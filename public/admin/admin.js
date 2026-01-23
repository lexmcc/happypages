(function() {
  'use strict';

  // Check auth on load
  checkAuth();
  loadVideos();

  document.getElementById('btn-logout').addEventListener('click', async () => {
    await fetch('/api/auth/logout', { method: 'POST' });
    window.location.href = '/admin/login';
  });

  document.getElementById('btn-upload').addEventListener('click', uploadVideo);

  async function checkAuth() {
    const res = await fetch('/api/videos');
    if (res.status === 401) {
      window.location.href = '/admin/login';
    }
  }

  async function loadVideos() {
    const res = await fetch('/api/videos');
    if (res.status === 401) return;
    const videos = await res.json();
    renderVideos(videos);
  }

  function renderVideos(videos) {
    const container = document.getElementById('video-list-content');
    if (!videos.length) {
      container.innerHTML = '<p class="no-videos">no videos uploaded yet.</p>';
      return;
    }
    container.innerHTML = videos.map(video => {
      const date = new Date(video.createdAt).toLocaleDateString();
      const badge = video.submitted
        ? '<span class="badge badge-submitted">submitted</span>'
        : '<span class="badge badge-pending">pending</span>';
      return `
        <div class="video-item" data-id="${video.id}">
          <div class="video-item-header">
            <span class="video-item-title">${escapeHtml(video.title)}</span>
            <div class="video-item-meta">
              ${badge}
              <span>${date}</span>
            </div>
          </div>
          <div class="video-item-actions">
            <button class="btn-sm btn-copy" data-id="${video.id}">copy review link</button>
            <button class="btn-sm btn-danger btn-delete" data-id="${video.id}">delete</button>
          </div>
          <div class="video-comments" id="comments-${video.id}">
            <h4>comments</h4>
            <div class="comments-list">loading...</div>
          </div>
        </div>
      `;
    }).join('');

    // Load comments for each video
    videos.forEach(v => loadComments(v.id));

    // Event delegation
    container.querySelectorAll('.btn-copy').forEach(btn => {
      btn.addEventListener('click', () => copyLink(btn));
    });
    container.querySelectorAll('.btn-delete').forEach(btn => {
      btn.addEventListener('click', () => deleteVideo(btn.dataset.id));
    });
  }

  async function loadComments(videoId) {
    const res = await fetch(`/api/videos/${videoId}/comments`);
    const comments = await res.json();
    const el = document.querySelector(`#comments-${videoId} .comments-list`);
    if (!comments.length) {
      el.innerHTML = '<span style="color:#999;font-size:13px">no comments yet</span>';
      return;
    }
    el.innerHTML = comments
      .sort((a, b) => a.timestamp - b.timestamp)
      .map(c => `
        <div class="comment-item">
          <span class="comment-time">${c.formattedTime}</span>
          <span class="comment-text">${escapeHtml(c.text)}</span>
        </div>
      `).join('');
  }

  function copyLink(btn) {
    const id = btn.dataset.id;
    const url = `${window.location.origin}/review/${id}`;
    navigator.clipboard.writeText(url).then(() => {
      btn.textContent = 'copied!';
      btn.classList.add('btn-copied');
      setTimeout(() => {
        btn.textContent = 'copy review link';
        btn.classList.remove('btn-copied');
      }, 2000);
    });
  }

  async function deleteVideo(id) {
    if (!confirm('delete this video? this cannot be undone.')) return;
    const res = await fetch(`/api/videos/${id}`, { method: 'DELETE' });
    if (res.ok) loadVideos();
  }

  async function uploadVideo() {
    const titleInput = document.getElementById('upload-title');
    const fileInput = document.getElementById('upload-file');
    const btn = document.getElementById('btn-upload');
    const progressBar = document.getElementById('progress-bar');
    const progressFill = document.getElementById('progress-fill');
    const status = document.getElementById('upload-status');

    const title = titleInput.value.trim();
    const file = fileInput.files[0];

    if (!title) { status.textContent = 'please enter a title'; return; }
    if (!file) { status.textContent = 'please select a file'; return; }

    btn.disabled = true;
    status.textContent = 'requesting upload url...';
    progressBar.classList.add('visible');
    progressFill.style.width = '0%';

    try {
      // Get pre-signed URL
      const urlRes = await fetch('/api/videos/upload-url', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ filename: file.name, contentType: file.type })
      });
      if (!urlRes.ok) throw new Error('failed to get upload url');
      const { uploadUrl, key, id } = await urlRes.json();

      // Upload to R2
      status.textContent = 'uploading...';
      await new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('PUT', uploadUrl);
        xhr.setRequestHeader('Content-Type', file.type);
        xhr.upload.onprogress = (e) => {
          if (e.lengthComputable) {
            const pct = Math.round((e.loaded / e.total) * 100);
            progressFill.style.width = pct + '%';
            status.textContent = `uploading... ${pct}%`;
          }
        };
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) resolve();
          else reject(new Error(`upload failed: ${xhr.status}`));
        };
        xhr.onerror = () => reject(new Error('upload failed'));
        xhr.send(file);
      });

      // Confirm upload
      status.textContent = 'saving...';
      const confirmRes = await fetch('/api/videos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, title, key })
      });
      if (!confirmRes.ok) throw new Error('failed to save video');

      status.textContent = 'upload complete!';
      titleInput.value = '';
      fileInput.value = '';
      progressFill.style.width = '100%';
      loadVideos();
      setTimeout(() => {
        progressBar.classList.remove('visible');
        status.textContent = '';
      }, 3000);
    } catch (err) {
      status.textContent = err.message;
    } finally {
      btn.disabled = false;
    }
  }

  function escapeHtml(str) {
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
})();
