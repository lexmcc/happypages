(function() {
  'use strict';

  const videoId = window.location.pathname.split('/').pop();
  const player = document.getElementById('video-player');
  const titleEl = document.getElementById('video-title');
  const badgeEl = document.getElementById('timestamp-badge');
  const inputEl = document.getElementById('comment-input');
  const addBtn = document.getElementById('btn-add-comment');
  const listEl = document.getElementById('comments-list');
  const nameInput = document.getElementById('reviewer-name');

  const STORAGE_KEY = 'reviewer-name-' + videoId;
  let comments = [];
  let editingId = null;
  let reviewerName = localStorage.getItem(STORAGE_KEY) || '';

  // Restore name
  if (reviewerName) {
    nameInput.value = reviewerName;
    enableCommentInput();
  }

  nameInput.addEventListener('input', () => {
    reviewerName = nameInput.value.trim();
    if (reviewerName) {
      localStorage.setItem(STORAGE_KEY, reviewerName);
      enableCommentInput();
    } else {
      localStorage.removeItem(STORAGE_KEY);
      inputEl.disabled = true;
      addBtn.disabled = true;
    }
  });

  function enableCommentInput() {
    inputEl.disabled = false;
    addBtn.disabled = false;
    inputEl.placeholder = 'add a comment at this timestamp...';
  }

  init();

  async function init() {
    try {
      const res = await fetch(`/api/videos/${videoId}`);
      if (!res.ok) throw new Error('not found');
      const video = await res.json();

      titleEl.textContent = video.title + '.';
      player.src = video.url;

      await loadComments();
    } catch (e) {
      document.querySelector('.review-container').innerHTML =
        '<div class="error-message"><h2>video not found.</h2><p>this review link may be invalid or expired.</p></div>';
    }
  }

  async function loadComments() {
    const res = await fetch(`/api/videos/${videoId}/comments`);
    comments = await res.json();
    renderComments();
  }

  function renderComments() {
    if (!comments.length) {
      listEl.innerHTML = '<p class="no-comments">no comments yet. play the video and add your feedback.</p>';
      return;
    }

    // Group comments by reviewer
    const groups = {};
    comments.forEach(c => {
      const name = c.reviewer || 'anonymous';
      if (!groups[name]) groups[name] = [];
      groups[name].push(c);
    });

    // Sort each group by timestamp
    Object.values(groups).forEach(g => g.sort((a, b) => a.timestamp - b.timestamp));

    // Render: current user's group first, then others
    const names = Object.keys(groups);
    const isMe = n => n.toLowerCase() === reviewerName.toLowerCase();
    const sorted = names.sort((a, b) => {
      if (isMe(a) && !isMe(b)) return -1;
      if (!isMe(a) && isMe(b)) return 1;
      return a.localeCompare(b);
    });

    listEl.innerHTML = sorted.map(name => {
      const mine = isMe(name);
      const heading = mine ? `${escapeHtml(name)} (you)` : escapeHtml(name);
      const headingClass = mine ? 'reviewer-name-heading is-you' : 'reviewer-name-heading';

      const items = groups[name].map(c => {
        if (editingId === c.id && mine) {
          return `
            <div class="comment-item" data-id="${c.id}">
              <span class="comment-time" data-ts="${c.timestamp}">${c.formattedTime}</span>
              <input class="comment-edit-input" value="${escapeAttr(c.text)}" data-id="${c.id}">
            </div>
          `;
        }
        return `
          <div class="comment-item${mine ? ' editable' : ''}" data-id="${c.id}">
            <span class="comment-time" data-ts="${c.timestamp}">${c.formattedTime}</span>
            <span class="comment-text">${escapeHtml(c.text)}</span>
          </div>
        `;
      }).join('');

      return `<div class="reviewer-group"><div class="${headingClass}">${heading}</div>${items}</div>`;
    }).join('');

    // Bind timestamp clicks (seek video)
    listEl.querySelectorAll('.comment-time').forEach(el => {
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        player.currentTime = parseFloat(el.dataset.ts);
        player.play();
      });
    });

    // Bind edit on own comments only
    listEl.querySelectorAll('.comment-item.editable .comment-text').forEach(el => {
      el.addEventListener('click', () => {
        const item = el.closest('.comment-item');
        editingId = item.dataset.id;
        renderComments();
        const input = listEl.querySelector('.comment-edit-input');
        if (input) { input.focus(); input.select(); }
      });
    });

    listEl.querySelectorAll('.comment-edit-input').forEach(el => {
      el.addEventListener('keydown', async (e) => {
        if (e.key === 'Enter') {
          await saveEdit(el.dataset.id, el.value);
        } else if (e.key === 'Escape') {
          editingId = null;
          renderComments();
        }
      });
      el.addEventListener('blur', async () => {
        if (editingId) {
          await saveEdit(el.dataset.id, el.value);
        }
      });
    });
  }

  async function saveEdit(commentId, text) {
    text = text.trim();
    if (!text) { editingId = null; renderComments(); return; }
    await fetch(`/api/videos/${videoId}/comments/${commentId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text })
    });
    editingId = null;
    await loadComments();
  }

  // Update timestamp badge as video plays
  player.addEventListener('timeupdate', () => {
    badgeEl.textContent = formatTime(player.currentTime);
  });

  // Add comment
  addBtn.addEventListener('click', addComment);
  inputEl.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') addComment();
  });

  async function addComment() {
    if (!reviewerName) return;
    const text = inputEl.value.trim();
    if (!text) return;
    const timestamp = player.currentTime;
    const formattedTime = formatTime(timestamp);

    addBtn.disabled = true;
    try {
      await fetch(`/api/videos/${videoId}/comments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, timestamp, formattedTime, reviewer: reviewerName })
      });
      inputEl.value = '';
      await loadComments();
    } finally {
      addBtn.disabled = false;
    }
  }

  function formatTime(seconds) {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s.toString().padStart(2, '0')}`;
  }

  function escapeHtml(str) {
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function escapeAttr(str) {
    return str.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
})();
