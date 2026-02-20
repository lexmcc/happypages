/**
 * Happypages Analytics — lightweight, privacy-friendly tracking script.
 * <3KB gzipped. No cookies for fingerprinting — just visitor + session IDs.
 *
 * Embed:
 *   <script defer src="https://app.happypages.co/s.js" data-hp-token="SITE_TOKEN"></script>
 */
;(function () {
  'use strict'

  var script = document.currentScript || document.querySelector('script[data-hp-token]')
  if (!script) return

  var token = script.getAttribute('data-hp-token')
  if (!token) return

  var endpoint = new URL('/collect', script.src).href
  var isSecure = location.protocol === 'https:'

  // --- ID helpers ---

  function hex(n) {
    var a = new Uint8Array(n)
    crypto.getRandomValues(a)
    return Array.prototype.map.call(a, function (b) { return ('0' + b.toString(16)).slice(-2) }).join('')
  }

  function getCookie(name) {
    var m = document.cookie.match(new RegExp('(?:^|; )' + name + '=([^;]*)'))
    return m ? m[1] : null
  }

  function setCookie(name, val, maxAge) {
    var c = name + '=' + val + ';path=/;max-age=' + maxAge + ';SameSite=Lax'
    if (isSecure) c += ';Secure'
    document.cookie = c
  }

  // Visitor: 1-year cookie
  var vid = getCookie('hp_vid')
  if (!vid) { vid = hex(8); setCookie('hp_vid', vid, 31536000) }

  // Session: 30-min sliding window
  var sid = getCookie('hp_sid')
  if (!sid) { sid = hex(8) }
  setCookie('hp_sid', sid, 1800) // refresh on every page

  // --- Referral code ---

  var refCode = null

  function refreshRef() {
    var p = new URLSearchParams(location.search)
    var r = p.get('ref')
    if (r) {
      refCode = r
      try { sessionStorage.setItem('hp_ref', refCode) } catch (e) {}
    } else if (!refCode) {
      try { refCode = sessionStorage.getItem('hp_ref') } catch (e) {}
    }
  }

  refreshRef()

  // --- UTM extraction ---

  function utms() {
    var p = new URLSearchParams(location.search)
    var u = {}
    ;['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content'].forEach(function (k) {
      var v = p.get(k)
      if (v) u[k] = v
    })
    return Object.keys(u).length ? u : undefined
  }

  // --- Send ---

  function send(eventName, props) {
    var data = {
      t: token,
      e: eventName,
      v: vid,
      s: sid,
      p: location.pathname,
      h: location.hostname,
      r: document.referrer || undefined,
      rc: refCode || undefined,
      u: utms()
    }
    if (props) data.pr = props

    var json = JSON.stringify(data)

    // Refresh session cookie on every send
    setCookie('hp_sid', sid, 1800)

    if (navigator.sendBeacon) {
      navigator.sendBeacon(endpoint, new Blob([json], { type: 'text/plain' }))
    } else {
      fetch(endpoint, { method: 'POST', body: json, keepalive: true })
    }
  }

  // --- Pageview tracking ---

  var lastPath = null

  function trackPage() {
    var path = location.pathname + location.search
    if (path === lastPath) return
    lastPath = path
    refreshRef()
    send('pageview')
  }

  // --- SPA support ---

  var origPush = history.pushState
  var origReplace = history.replaceState

  history.pushState = function () {
    origPush.apply(this, arguments)
    trackPage()
  }
  history.replaceState = function () {
    origReplace.apply(this, arguments)
    trackPage()
  }
  window.addEventListener('popstate', trackPage)

  // --- Goal tracking (data-hp-goal) ---

  var goalPending = false

  function bindGoals() {
    if (goalPending) return
    goalPending = true
    requestAnimationFrame(function () {
      goalPending = false
      document.querySelectorAll('[data-hp-goal]').forEach(function (el) {
        if (el._hpGoal) return
        el._hpGoal = true
        el.addEventListener('click', function () {
          send(el.getAttribute('data-hp-goal'))
        })
      })
    })
  }

  // --- Shopify cart injection ---

  function syncCart() {
    if (typeof Shopify === 'undefined') return
    try {
      if (sessionStorage.getItem('hp_cart_synced')) return
    } catch (e) {}

    var attrs = { hp_vid: vid, hp_sid: sid }
    if (refCode) attrs.hp_ref = refCode

    fetch('/cart/update.js', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ attributes: attrs })
    }).then(function () {
      try { sessionStorage.setItem('hp_cart_synced', '1') } catch (e) {}
    }).catch(function () {})
  }

  // --- Public API ---

  function api(eventName, props) {
    send(eventName, props)
  }

  // Drain pre-init queue
  var q = window.hpa
  window.hpa = api
  if (q && q.q) {
    q.q.forEach(function (args) { api.apply(null, args) })
  }

  // --- Init ---

  trackPage()
  bindGoals()
  syncCart()

  // Re-bind goals after DOM mutations (SPAs inserting new elements)
  if (typeof MutationObserver !== 'undefined') {
    new MutationObserver(bindGoals).observe(document.body, { childList: true, subtree: true })
  }
})()
