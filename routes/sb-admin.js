/* ============================================================
   SHAUNIX SKILL BUILDERS — private admin (print kit)
   URL: /sb-admin   (password protected, noindex)
   Password hash + session secret .env mein: SB_ADMIN_HASH, SB_SESSION_SECRET
   Settings data/skillbuilders-admin.json mein save hoti hain.
   ============================================================ */
const express = require('express');
const crypto  = require('crypto');
const fs      = require('fs');
const path    = require('path');

const router = express.Router();
const BASE   = '/sb-admin';
const ROOT   = path.join(__dirname, '..');
const VIEWS  = path.join(ROOT, 'views');
const DATA_DIR  = path.join(ROOT, 'data');
const DATA_FILE = path.join(DATA_DIR, 'skillbuilders-admin.json');
const COOKIE = 'sb_admin';
const TTL_MS = 8 * 60 * 60 * 1000;

let SITE = {};
try { SITE = require('../config'); } catch (e) { /* optional */ }

const HASH   = () => process.env.SB_ADMIN_HASH || '';
const SECRET = () => (process.env.SB_SESSION_SECRET || '') + HASH();

/* ---------- password + session ---------- */
function checkPassword(pw) {
  const parts = HASH().split(':');
  if (parts.length !== 3 || parts[0] !== 'scrypt') return false;
  const expected = Buffer.from(parts[2], 'hex');
  const got = crypto.scryptSync(String(pw || ''), Buffer.from(parts[1], 'hex'), expected.length);
  return crypto.timingSafeEqual(got, expected);
}
function makeToken() {
  const body = Buffer.from(JSON.stringify({ exp: Date.now() + TTL_MS })).toString('base64url');
  const sig  = crypto.createHmac('sha256', SECRET()).update(body).digest('base64url');
  return body + '.' + sig;
}
function getCookie(req, name) {
  const h = req.headers.cookie || '';
  for (const p of h.split(';')) {
    const i = p.indexOf('=');
    if (i > 0 && p.slice(0, i).trim() === name) return decodeURIComponent(p.slice(i + 1).trim());
  }
  return '';
}
function isAuthed(req) {
  if (!HASH() || !process.env.SB_SESSION_SECRET) return false;
  const tok = getCookie(req, COOKIE);
  const [body, sig] = tok.split('.');
  if (!body || !sig) return false;
  const exp = crypto.createHmac('sha256', SECRET()).update(body).digest('base64url');
  const a = Buffer.from(sig), b = Buffer.from(exp);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return false;
  try { return JSON.parse(Buffer.from(body, 'base64url').toString()).exp > Date.now(); }
  catch (e) { return false; }
}
function requireAuth(req, res, next) {
  if (isAuthed(req)) return next();
  res.status(401).json({ ok: false, error: 'Login required' });
}

/* ---------- brute-force throttle (5 galat = 15 min lock, per IP) ---------- */
const fails = new Map();
function locked(ip) {
  const f = fails.get(ip);
  return f && f.n >= 5 && f.until > Date.now() ? Math.ceil((f.until - Date.now()) / 60000) : 0;
}
function noteFail(ip) {
  const f = fails.get(ip) || { n: 0, until: 0 };
  if (f.until && f.until < Date.now()) { f.n = 0; }
  f.n += 1; f.until = Date.now() + 15 * 60 * 1000;
  fails.set(ip, f);
}

/* ---------- headers: private, no cache, no indexing ---------- */
router.use(BASE, (req, res, next) => {
  res.set({
    'X-Robots-Tag': 'noindex, nofollow',
    'Cache-Control': 'no-store',
    'X-Frame-Options': 'SAMEORIGIN',
    'Referrer-Policy': 'no-referrer'
  });
  next();
});

function page(name, repl) {
  let html = fs.readFileSync(path.join(VIEWS, name), 'utf8');
  Object.keys(repl || {}).forEach(k => { html = html.split(k).join(repl[k]); });
  return html;
}
const escHtml = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/* ---------- pages ---------- */
router.get(BASE, (req, res) => {
  if (!HASH() || !process.env.SB_ADMIN_HASH) {
    return res.status(503).send('Admin not configured. Run the installer script again to set a password.');
  }
  if (isAuthed(req)) return res.type('html').send(page('sb-admin.html'));
  const err = req.query.e === '1' ? 'Galat password.' : req.query.e === '2' ? 'Bahut zyada galat koshish. 15 minute baad try karo.' : '';
  res.type('html').send(page('sb-admin-login.html', { '{{ERROR}}': escHtml(err) }));
});

router.post(BASE + '/login', async (req, res) => {
  const ip = req.ip || 'x';
  if (locked(ip)) return res.redirect(BASE + '?e=2');
  const ok = HASH() && checkPassword((req.body || {}).password);
  if (!ok) {
    noteFail(ip);
    await new Promise(r => setTimeout(r, 600));
    return res.redirect(BASE + '?e=' + (locked(ip) ? '2' : '1'));
  }
  fails.delete(ip);
  const secure = req.secure || req.headers['x-forwarded-proto'] === 'https';
  res.cookie(COOKIE, makeToken(), { httpOnly: true, sameSite: 'strict', secure, maxAge: TTL_MS, path: BASE });
  res.redirect(BASE);
});

router.post(BASE + '/logout', (req, res) => {
  res.clearCookie(COOKIE, { path: BASE });
  res.redirect(BASE);
});

/* ---------- settings storage ---------- */
function defaults() {
  return {
    founder: '', role: 'Founder & Director',
    phone: SITE.phoneDisplay || '', email: SITE.email || '',
    web: SITE.websiteUrl || '', addr: SITE.address || '',
    tag: 'Learn it. Build it. Show it.', logo: '', certCounter: 0
  };
}
function readSettings() {
  try { return Object.assign(defaults(), JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'))); }
  catch (e) { return defaults(); }
}
function writeSettings(obj) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const tmp = DATA_FILE + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2));
  fs.renameSync(tmp, DATA_FILE);
}
const LIMITS = { founder: 80, role: 80, phone: 40, email: 80, web: 80, addr: 200, tag: 80 };
function cleanSettings(o) {
  const out = {};
  Object.keys(LIMITS).forEach(k => { out[k] = String((o && o[k]) == null ? '' : o[k]).slice(0, LIMITS[k]); });
  const logo = o && o.logo;
  out.logo = (typeof logo === 'string' && logo.length < 1500000 &&
    /^data:image\/(png|jpeg|webp|svg\+xml);base64,[A-Za-z0-9+\/=]+$/.test(logo)) ? logo : '';
  return out;
}

router.get(BASE + '/api/settings', requireAuth, (req, res) => res.json(readSettings()));

/* text/plain body: global express.json() ki 100kb limit se bachne ke liye (logo image) */
router.post(BASE + '/api/settings', requireAuth, express.text({ type: () => true, limit: '3mb' }), (req, res) => {
  let incoming;
  try { incoming = JSON.parse(req.body || '{}'); } catch (e) { return res.status(400).json({ ok: false, error: 'Bad data' }); }
  const cur = readSettings();
  const next = Object.assign({}, cur, cleanSettings(incoming));
  writeSettings(next);
  res.json({ ok: true });
});

router.post(BASE + '/api/cert-counter', requireAuth, (req, res) => {
  const v = parseInt((req.body || {}).value, 10);
  if (!Number.isInteger(v) || v < 0 || v > 999999) return res.status(400).json({ ok: false, error: 'Invalid' });
  const cur = readSettings(); cur.certCounter = v; writeSettings(cur);
  res.json({ ok: true, certCounter: v });
});

/* ---------- QR (ID card back) — project ki existing "qrcode" package ---------- */
router.get(BASE + '/api/qr', requireAuth, async (req, res) => {
  const text = String(req.query.text || '').slice(0, 300);
  if (!text) return res.status(400).send('');
  try {
    const QR = require('qrcode');
    const svg = await QR.toString(text, { type: 'svg', margin: 0, color: { dark: '#0B1F3A', light: '#0000' } });
    res.type('image/svg+xml').send(svg);
  } catch (e) {
    res.status(501).send('');
  }
});

module.exports = router;
