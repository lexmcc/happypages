'use strict';

const crypto = require('crypto');
const data = require('./data');

const SESSION_MAX_AGE = 7 * 24 * 60 * 60 * 1000; // 7 days

function createSession() {
  const token = crypto.randomBytes(32).toString('hex');
  const sessions = data.readJSON('sessions') || {};
  sessions[token] = { createdAt: Date.now() };
  // Prune expired sessions
  for (const [t, s] of Object.entries(sessions)) {
    if (Date.now() - s.createdAt > SESSION_MAX_AGE) delete sessions[t];
  }
  data.writeJSON('sessions', sessions);
  return token;
}

function validateSession(token) {
  if (!token) return false;
  const sessions = data.readJSON('sessions') || {};
  const session = sessions[token];
  if (!session) return false;
  if (Date.now() - session.createdAt > SESSION_MAX_AGE) {
    delete sessions[token];
    data.writeJSON('sessions', sessions);
    return false;
  }
  return true;
}

function deleteSession(token) {
  const sessions = data.readJSON('sessions') || {};
  delete sessions[token];
  data.writeJSON('sessions', sessions);
}

function getTokenFromReq(req) {
  const cookie = req.headers.cookie || '';
  const match = cookie.match(/session=([^;]+)/);
  return match ? match[1] : null;
}

function setSessionCookie(res, token) {
  res.setHeader('Set-Cookie', `session=${token}; Path=/; HttpOnly; SameSite=Strict; Max-Age=${SESSION_MAX_AGE / 1000}`);
}

function clearSessionCookie(res) {
  res.setHeader('Set-Cookie', 'session=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0');
}

function requireAuth(req, res) {
  const token = getTokenFromReq(req);
  if (!validateSession(token)) {
    const { json } = require('./router');
    json(res, 401, { error: 'Unauthorized' });
    return false;
  }
  return true;
}

module.exports = { createSession, validateSession, deleteSession, getTokenFromReq, setSessionCookie, clearSessionCookie, requireAuth };
