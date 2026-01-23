'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function filePath(name) {
  ensureDir(DATA_DIR);
  return path.join(DATA_DIR, `${name}.json`);
}

function commentsPath(videoId) {
  const dir = path.join(DATA_DIR, 'comments');
  ensureDir(dir);
  return path.join(dir, `${videoId}.json`);
}

function readJSON(name) {
  const fp = filePath(name);
  if (!fs.existsSync(fp)) return null;
  return JSON.parse(fs.readFileSync(fp, 'utf8'));
}

function writeJSON(name, obj) {
  ensureDir(DATA_DIR);
  fs.writeFileSync(filePath(name), JSON.stringify(obj, null, 2));
}

function generateId() {
  return crypto.randomBytes(8).toString('hex');
}

// Videos
function getVideos() {
  return readJSON('videos') || {};
}

function getVideo(id) {
  const videos = getVideos();
  return videos[id] || null;
}

function saveVideo(video) {
  const videos = getVideos();
  videos[video.id] = video;
  writeJSON('videos', videos);
  return video;
}

function deleteVideo(id) {
  const videos = getVideos();
  delete videos[id];
  writeJSON('videos', videos);
  // Remove comments file
  const cp = commentsPath(id);
  if (fs.existsSync(cp)) fs.unlinkSync(cp);
}

// Comments
function getComments(videoId) {
  const cp = commentsPath(videoId);
  if (!fs.existsSync(cp)) return [];
  return JSON.parse(fs.readFileSync(cp, 'utf8'));
}

function saveComments(videoId, comments) {
  fs.writeFileSync(commentsPath(videoId), JSON.stringify(comments, null, 2));
}

function addComment(videoId, comment) {
  const comments = getComments(videoId);
  comment.id = generateId();
  comment.createdAt = Date.now();
  comment.updatedAt = Date.now();
  comments.push(comment);
  saveComments(videoId, comments);
  return comment;
}

function updateComment(videoId, commentId, updates) {
  const comments = getComments(videoId);
  const idx = comments.findIndex(c => c.id === commentId);
  if (idx === -1) return null;
  comments[idx] = { ...comments[idx], ...updates, updatedAt: Date.now() };
  saveComments(videoId, comments);
  return comments[idx];
}

module.exports = { readJSON, writeJSON, generateId, getVideos, getVideo, saveVideo, deleteVideo, getComments, addComment, updateComment };
