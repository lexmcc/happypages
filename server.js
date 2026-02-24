'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
const { Router, parseBody, json } = require('./lib/router');
const auth = require('./lib/auth');
const data = require('./lib/data');
const r2 = require('./lib/r2');

const PORT = process.env.PORT || 3000;

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.mp4': 'video/mp4',
  '.avif': 'image/avif'
};

const router = new Router();

// --- Auth endpoints ---

router.post('/api/auth/login', async (req, res) => {
  const body = await parseBody(req);
  const adminPassword = process.env.ADMIN_PASSWORD;
  if (!adminPassword) return json(res, 500, { error: 'ADMIN_PASSWORD not configured' });
  if (body.password !== adminPassword) return json(res, 401, { error: 'Invalid password' });
  const token = auth.createSession();
  auth.setSessionCookie(res, token);
  json(res, 200, { ok: true });
});

router.post('/api/auth/logout', (req, res) => {
  const token = auth.getTokenFromReq(req);
  if (token) auth.deleteSession(token);
  auth.clearSessionCookie(res);
  json(res, 200, { ok: true });
});

// --- Video endpoints ---

router.get('/api/videos', (req, res) => {
  if (!auth.requireAuth(req, res)) return;
  const videos = data.getVideos();
  json(res, 200, Object.values(videos).sort((a, b) => b.createdAt - a.createdAt));
});

router.post('/api/videos/upload-url', async (req, res) => {
  if (!auth.requireAuth(req, res)) return;
  const body = await parseBody(req);
  if (!body.filename || !body.contentType) return json(res, 400, { error: 'filename and contentType required' });
  const id = data.generateId();
  const ext = path.extname(body.filename) || '.mp4';
  const key = `videos/${id}${ext}`;
  const url = r2.generatePresignedUrl({ method: 'PUT', key, contentType: body.contentType });
  json(res, 200, { uploadUrl: url, key, id });
});

router.post('/api/videos', async (req, res) => {
  if (!auth.requireAuth(req, res)) return;
  const body = await parseBody(req);
  if (!body.id || !body.title || !body.key) return json(res, 400, { error: 'id, title, and key required' });
  const video = {
    id: body.id,
    title: body.title,
    key: body.key,
    url: r2.getPublicUrl(body.key),
    createdAt: Date.now(),
    submitted: false,
  };
  data.saveVideo(video);
  json(res, 201, video);
});

router.delete('/api/videos/:id', async (req, res) => {
  if (!auth.requireAuth(req, res)) return;
  const video = data.getVideo(req.params.id);
  if (!video) return json(res, 404, { error: 'Video not found' });
  try { await r2.deleteObject(video.key); } catch (e) { /* ignore R2 errors on delete */ }
  data.deleteVideo(video.id);
  json(res, 200, { ok: true });
});

router.get('/api/videos/:id', (req, res) => {
  const video = data.getVideo(req.params.id);
  if (!video) return json(res, 404, { error: 'Video not found' });
  json(res, 200, video);
});

// --- Comment endpoints ---

router.get('/api/videos/:id/comments', (req, res) => {
  const video = data.getVideo(req.params.id);
  if (!video) return json(res, 404, { error: 'Video not found' });
  json(res, 200, data.getComments(req.params.id));
});

router.post('/api/videos/:id/comments', async (req, res) => {
  const video = data.getVideo(req.params.id);
  if (!video) return json(res, 404, { error: 'Video not found' });
  const body = await parseBody(req);
  if (!body.text || body.timestamp == null) return json(res, 400, { error: 'text and timestamp required' });
  const comment = data.addComment(req.params.id, {
    text: body.text,
    timestamp: body.timestamp,
    formattedTime: body.formattedTime || formatTime(body.timestamp),
    reviewer: body.reviewer || 'anonymous',
  });
  json(res, 201, comment);
});

router.put('/api/videos/:id/comments/:cid', async (req, res) => {
  const video = data.getVideo(req.params.id);
  if (!video) return json(res, 404, { error: 'Video not found' });
  const body = await parseBody(req);
  const updated = data.updateComment(req.params.id, req.params.cid, { text: body.text });
  if (!updated) return json(res, 404, { error: 'Comment not found' });
  json(res, 200, updated);
});

router.post('/api/videos/:id/submit', (req, res) => {
  const video = data.getVideo(req.params.id);
  if (!video) return json(res, 404, { error: 'Video not found' });
  video.submitted = true;
  video.submittedAt = Date.now();
  data.saveVideo(video);
  json(res, 200, { ok: true });
});

function formatTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}

// --- Server ---

const server = http.createServer(async (req, res) => {
  const urlPath = req.url.split('?')[0];
  const method = req.method;

  // API routes
  const route = router.match(method, urlPath);
  if (route) {
    req.params = route.params;
    try {
      await route.handler(req, res);
    } catch (e) {
      console.error('API error:', e);
      if (!res.headersSent) json(res, 500, { error: 'Internal server error' });
    }
    return;
  }

  // Review page (dynamic path)
  if (urlPath.match(/^\/review\/[a-f0-9]{16}$/)) {
    const filePath = path.join(__dirname, 'public', 'review', 'index.html');
    return serveFile(res, filePath, 'text/html');
  }

  // Static files — redirect clean URLs to trailing slash so relative paths resolve correctly
  if (!path.extname(urlPath) && !urlPath.endsWith('/')) {
    const dirPath = path.join(__dirname, 'public', urlPath);
    if (fs.existsSync(path.join(dirPath, 'index.html'))) {
      res.writeHead(301, { 'Location': urlPath + '/' });
      res.end();
      return;
    }
  }

  let staticPath = urlPath;
  if (staticPath.endsWith('/')) {
    staticPath += 'index.html';
  } else if (!path.extname(staticPath)) {
    staticPath += '/index.html';
  }

  const filePath = path.join(__dirname, 'public', staticPath);
  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';
  serveFile(res, filePath, contentType);
});

function serveFile(res, filePath, contentType) {
  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 - Not Found</h1>');
      } else {
        res.writeHead(500);
        res.end('Server Error');
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    }
  });
}

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
