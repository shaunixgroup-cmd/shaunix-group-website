#!/usr/bin/env bash
# =====================================================================
#  SHAUNIX GROUP website  ->  PASSWORD-PROTECTED ADMIN: Skill Builders Print Kit
#  Visiting Card | Trainer ID Card (naya aesthetic design + QR) | Brochure | Certificates
#
#  Run (website folder ke andar, jahan server.js hai):
#       bash add_skill_builders_admin.sh
#  Ya:  bash add_skill_builders_admin.sh /path/to/shaunix-group-website-master
#
#  Admin URL:  /sb-admin     (hidden, noindex, sitemap mein nahi)
#
#  Ye script karta hai:
#   1) routes/sb-admin.js            login + session + settings + QR API
#   2) views/sb-admin.html           admin app (sirf login ke baad khulta hai)
#   3) views/sb-admin-login.html     login page
#   4) server.js                     route register (redirect-all se pehle)
#   5) .env                          password HASH + session secret (plain password kahin save nahi)
#   6) .gitignore                    .env, data/ ignore
#  Backup + RESTORE.sh banta hai. Dobara chalane par password reset ka option milta hai.
# =====================================================================

ROOT="${1:-$PWD}"
line() { printf '%s\n' "------------------------------------------------------------"; }

valid_root() { [ -f "$1/server.js" ] && [ -d "$1/views" ] && [ -d "$1/routes" ]; }
if ! valid_root "$ROOT"; then
  echo "server.js / views / routes nahi mila: $ROOT"
  read -r -p "Website project folder ka path do: " ROOT
  ROOT="${ROOT/#\~/$HOME}"
  valid_root "$ROOT" || { echo "Ye shaunix website folder nahi lag raha. Band kar raha hoon."; exit 1; }
fi
command -v node >/dev/null 2>&1 || { echo "Node.js chahiye (PATH mein nahi mila)."; exit 1; }
ROOT="$(cd "$ROOT" && pwd)"

echo; line; echo "  SKILL BUILDERS ADMIN installer"; echo "  Project: $ROOT"; line

# ---------- password ----------
HAVE_HASH=0
[ -f "$ROOT/.env" ] && grep -q '^SB_ADMIN_HASH=' "$ROOT/.env" && HAVE_HASH=1
SET_PW=1
if [ "$HAVE_HASH" = "1" ]; then
  read -r -p "  Admin password pehle se set hai. Naya password set karna hai? (y/n) [n]: " R
  [[ "${R:-n}" =~ ^[Yy] ]] || SET_PW=0
fi
SB_PW=""
if [ "$SET_PW" = "1" ]; then
  while true; do
    read -r -s -p "  Admin password chuno (kam se kam 8 characters): " P1; echo
    read -r -s -p "  Password dobara likho: " P2; echo
    if [ "${#P1}" -lt 8 ]; then echo "  Bahut chhota hai, 8+ characters rakho."; continue; fi
    if [ "$P1" != "$P2" ]; then echo "  Dono match nahi hue, phir se."; continue; fi
    SB_PW="$P1"; break
  done
fi

# ---------- backup ----------
BK="$ROOT/.sb_admin_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BK"
FILES_EDIT=(server.js .env .gitignore)
FILES_NEW=(routes/sb-admin.js views/sb-admin.html views/sb-admin-login.html)
for f in "${FILES_EDIT[@]}" "${FILES_NEW[@]}"; do
  if [ -f "$ROOT/$f" ]; then mkdir -p "$BK/$(dirname "$f")"; cp "$ROOT/$f" "$BK/$f"; fi
done
{
  echo '#!/usr/bin/env bash'
  echo "# Undo: purani files wapas, naye files hata do"
  echo "cd \"$ROOT\" || exit 1"
  for f in "${FILES_EDIT[@]}"; do
    if [ -f "$BK/$f" ]; then echo "cp \"$BK/$f\" \"$ROOT/$f\""; else echo "rm -f \"$ROOT/$f\""; fi
  done
  for f in "${FILES_NEW[@]}"; do
    if [ -f "$BK/$f" ]; then echo "cp \"$BK/$f\" \"$ROOT/$f\""; else echo "rm -f \"$ROOT/$f\""; fi
  done
  echo 'echo "Restore ho gaya. Server restart karo."'
} > "$BK/RESTORE.sh"
echo "  Backup: $BK  (undo: bash $BK/RESTORE.sh)"
mkdir -p "$ROOT/routes" "$ROOT/views" "$ROOT/data"

# =====================================================================
# 1) ROUTE  (auth + API)
# =====================================================================
cat > "$ROOT/routes/sb-admin.js" <<'EOF'
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
EOF

# =====================================================================
# 2) LOGIN PAGE
# =====================================================================
cat > "$ROOT/views/sb-admin-login.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex, nofollow">
<title>Admin Login</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{min-height:100vh;display:grid;place-items:center;font-family:'Poppins','Segoe UI',Arial,sans-serif;
  background:radial-gradient(600px 400px at 85% -10%,rgba(255,107,44,.35),transparent 60%),radial-gradient(500px 400px at 0% 110%,rgba(20,184,166,.28),transparent 60%),linear-gradient(160deg,#0B1F3A,#14386b);color:#fff;padding:20px}
.box{width:min(400px,100%);background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.18);border-radius:22px;padding:34px 30px;backdrop-filter:blur(8px);box-shadow:0 24px 60px rgba(0,0,0,.35)}
.brand{display:flex;align-items:center;gap:12px;margin-bottom:22px}
.mark{width:44px;height:44px;border-radius:12px;background:linear-gradient(135deg,#FF6B2C,#FFB703);display:grid;place-items:center;font-weight:800;font-size:24px}
.wm b{display:block;font-weight:800;letter-spacing:1.5px;font-size:18px;line-height:1}
.wm i{display:block;font-style:normal;font-weight:600;font-size:9px;letter-spacing:4px;color:#FFB703;margin-top:5px}
h1{font-size:20px;margin-bottom:4px}
p{font-size:13px;color:#cbd6ee;margin-bottom:20px}
input{width:100%;padding:13px 16px;border-radius:12px;border:1px solid rgba(255,255,255,.25);background:rgba(255,255,255,.1);color:#fff;font:inherit;outline:none}
input:focus{border-color:#FFB703;box-shadow:0 0 0 3px rgba(255,183,3,.25)}
button{margin-top:14px;width:100%;padding:13px;border:0;border-radius:12px;font:inherit;font-weight:700;color:#fff;cursor:pointer;background:linear-gradient(135deg,#FF6B2C,#FFB703)}
.err{margin-top:14px;font-size:13px;color:#ffb4a2;min-height:18px}
</style>
</head>
<body>
<form class="box" method="POST" action="/sb-admin/login" autocomplete="off">
  <div class="brand"><div class="mark">S</div><div class="wm"><b>SHAUNIX</b><i>SKILL BUILDERS</i></div></div>
  <h1>Admin Login</h1>
  <p>Print kit: visiting card, ID card, brochure &amp; certificates.</p>
  <input type="password" name="password" placeholder="Password" required autofocus>
  <button type="submit">Login</button>
  <div class="err">{{ERROR}}</div>
</form>
</body>
</html>
EOF

# =====================================================================
# 3) ADMIN APP  (sab client-side render, login ke baad hi serve hota hai)
# =====================================================================
cat > "$ROOT/views/sb-admin.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex, nofollow">
<title>Skill Builders — Print Kit (Admin)</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&family=Playfair+Display:ital,wght@0,600;0,700;1,600&display=swap" rel="stylesheet">
<style>
:root{--navy:#0B1F3A;--navy2:#14386b;--orange:#FF6B2C;--amber:#FFB703;--teal:#14B8A6;--bg:#f3f5fa;--line:#e3e8f1;--mute:#667085;--ink:#1d2939}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Poppins','Segoe UI',Arial,sans-serif;background:var(--bg);color:var(--ink);font-size:14px}
.top{background:linear-gradient(135deg,#0B1F3A,#14386b);color:#fff;display:flex;align-items:center;gap:22px;padding:12px 22px;flex-wrap:wrap;position:sticky;top:0;z-index:5}
.lg{display:flex;align-items:center;gap:10px}
.lg .m{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--orange),var(--amber));display:grid;place-items:center;font-weight:800;font-size:18px}
.lg b{display:block;font-weight:800;letter-spacing:1px;font-size:14px;line-height:1}
.lg i{display:block;font-style:normal;font-weight:600;font-size:7px;letter-spacing:3.2px;color:var(--amber);margin-top:4px}
.tabs{display:flex;gap:6px;flex:1;flex-wrap:wrap}
.tabs button{border:0;background:rgba(255,255,255,.08);color:#dbe6f5;font:inherit;font-weight:600;font-size:13px;padding:9px 16px;border-radius:999px;cursor:pointer;transition:.15s}
.tabs button:hover{background:rgba(255,255,255,.16)}
.tabs button.on{background:linear-gradient(135deg,var(--orange),var(--amber));color:#fff}
.out button{border:1px solid rgba(255,255,255,.3);background:transparent;color:#fff;font:inherit;font-size:12px;padding:8px 14px;border-radius:999px;cursor:pointer}
.wrap{display:grid;grid-template-columns:370px 1fr;min-height:calc(100vh - 58px)}
.panel{background:#fff;border-right:1px solid var(--line);padding:22px;overflow:auto;max-height:calc(100vh - 58px);position:sticky;top:58px}
.panel h2{font-size:16px;margin-bottom:4px}
.panel .sub{font-size:12px;color:var(--mute);margin-bottom:16px}
.pane{display:none}.pane.on{display:block}
label{display:block;font-size:11px;font-weight:600;color:var(--mute);letter-spacing:.04em;text-transform:uppercase;margin:12px 0 5px}
input[type=text],input[type=number],textarea,select{width:100%;padding:10px 12px;border:1px solid var(--line);border-radius:10px;font:inherit;font-size:13.5px;background:#fbfcfe;outline:none}
input:focus,textarea:focus,select:focus{border-color:var(--orange);box-shadow:0 0 0 3px rgba(255,107,44,.15);background:#fff}
textarea{min-height:130px;resize:vertical}
input[type=file]{font-size:12px;width:100%}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;border:0;font:inherit;font-weight:600;font-size:13px;padding:10px 16px;border-radius:10px;cursor:pointer}
.btn.pri{background:linear-gradient(135deg,var(--orange),var(--amber));color:#fff}
.btn.sec{background:#eef2f9;color:var(--navy)}
.btn.dng{background:#fff1ee;color:#c4381b}
.btns{display:flex;gap:8px;flex-wrap:wrap;margin-top:16px}
.hint{font-size:11.5px;color:var(--mute);margin-top:6px;line-height:1.5}
.chips{display:flex;flex-wrap:wrap;gap:6px;margin:8px 0}
.chips button{border:1px solid var(--line);background:#fff;border-radius:999px;padding:6px 12px;font:inherit;font-size:12px;cursor:pointer;color:var(--navy)}
.chips button.on{background:var(--navy);color:#fff;border-color:var(--navy)}
.stage{padding:16px 24px 40px;min-width:0}
.bar{display:flex;align-items:center;gap:14px;flex-wrap:wrap;background:#fff;border:1px solid var(--line);border-radius:14px;padding:10px 16px;margin-bottom:16px;position:sticky;top:70px;z-index:4}
.bar h3{font-size:14px;flex:1;min-width:140px}
.bar label{margin:0;text-transform:none;letter-spacing:0;display:flex;align-items:center;gap:8px;font-size:12px}
.bar input[type=range]{width:110px}
.bar select{width:auto;padding:7px 10px}
#frame{width:100%;border:0;display:block;background:transparent;min-height:300px}
.toast{position:fixed;right:20px;bottom:20px;background:var(--navy);color:#fff;padding:12px 18px;border-radius:12px;font-size:13px;opacity:0;transform:translateY(10px);transition:.25s;pointer-events:none;z-index:20}
.toast.on{opacity:1;transform:none}
@media(max-width:900px){.wrap{grid-template-columns:1fr}.panel{max-height:none;position:static;border-right:0;border-bottom:1px solid var(--line)}.bar{top:0;position:static}}
</style>
</head>
<body>
<header class="top">
  <div class="lg"><div class="m">S</div><div><b>SHAUNIX</b><i>SKILL BUILDERS · ADMIN</i></div></div>
  <nav class="tabs" id="tabs">
    <button data-t="company">Company</button>
    <button data-t="card">Visiting Card</button>
    <button data-t="id">Trainer ID</button>
    <button data-t="brochure">Brochure</button>
    <button data-t="cert">Certificates</button>
  </nav>
  <form class="out" method="POST" action="/sb-admin/logout"><button type="submit">Logout</button></form>
</header>

<div class="wrap">
<aside class="panel">

  <!-- COMPANY -->
  <section class="pane" id="p-company">
    <h2>Company details</h2><div class="sub">Ek baar bharo, sab cards, brochure aur certificates mein use honge.</div>
    <label>Founder / contact person</label><input type="text" id="c_founder">
    <label>Designation</label><input type="text" id="c_role">
    <div class="row2"><div><label>Phone</label><input type="text" id="c_phone"></div><div><label>Email</label><input type="text" id="c_email"></div></div>
    <label>Website</label><input type="text" id="c_web">
    <label>Address</label><input type="text" id="c_addr">
    <label>Tagline</label><input type="text" id="c_tag">
    <label>Logo (PNG / JPG / SVG, optional)</label><input type="file" id="c_logo" accept="image/png,image/jpeg,image/webp,image/svg+xml">
    <div class="hint">Logo na do to built-in "S" mark use hoga.</div>
    <div class="btns"><button class="btn pri" id="saveCompany">Save company details</button><button class="btn dng" id="rmLogo">Remove logo</button></div>
  </section>

  <!-- CARD -->
  <section class="pane" id="p-card">
    <h2>Visiting card</h2><div class="sub">90 × 50 mm, front + back.</div>
    <label>Name</label><input type="text" id="k_name">
    <label>Designation</label><input type="text" id="k_role">
    <div class="row2"><div><label>Phone</label><input type="text" id="k_phone"></div><div><label>Email</label><input type="text" id="k_email"></div></div>
    <label>Website</label><input type="text" id="k_web">
    <label>Address</label><input type="text" id="k_addr">
    <div class="btns"><button class="btn sec" id="cardFill">Company se bharo</button></div>
  </section>

  <!-- ID -->
  <section class="pane" id="p-id">
    <h2>Trainer ID card</h2><div class="sub">54 × 86 mm, front + back (back par QR code).</div>
    <div class="chips" id="tlist"></div>
    <div class="btns" style="margin-top:0"><button class="btn sec" id="tAdd">+ Add trainer</button><button class="btn dng" id="tDel">Delete this</button></div>
    <label>Trainer name</label><input type="text" id="t_name">
    <div class="row2"><div><label>Role</label><input type="text" id="t_role"></div><div><label>ID number</label><input type="text" id="t_id"></div></div>
    <div class="row2"><div><label>Phone</label><input type="text" id="t_phone"></div><div><label>Blood group</label><input type="text" id="t_blood" placeholder="optional"></div></div>
    <div class="row2"><div><label>Valid till</label><input type="text" id="t_valid"></div><div><label>Emergency no.</label><input type="text" id="t_em"></div></div>
    <label>Photo</label><input type="file" id="t_photo" accept="image/*">
    <div class="hint">Photo sirf aapke browser mein rehti hai (server par upload nahi hoti). Saaf, seedhe face wali photo best lagti hai.</div>
  </section>

  <!-- BROCHURE -->
  <section class="pane" id="p-brochure">
    <h2>Brochure</h2><div class="sub">A4 landscape tri-fold: page 1 bahar, page 2 andar.</div>
    <label>Fee per student (blank = fee na dikhao)</label><input type="text" id="b_fee" placeholder="e.g. 599">
    <div class="hint">Print: A4 landscape, double-sided (short edge flip), phir 3 mein fold karo. Fee likho to material scope written agreement mein tay rakhna.</div>
  </section>

  <!-- CERT -->
  <section class="pane" id="p-cert">
    <h2>Certificates</h2><div class="sub">A4 landscape, ek student = ek page.</div>
    <label>Program / course</label><input type="text" id="g_course">
    <div class="row2"><div><label>Duration</label><input type="text" id="g_dur"></div><div><label>Class (optional)</label><input type="text" id="g_class"></div></div>
    <label>School name</label><input type="text" id="g_school">
    <label>Program dates</label><input type="text" id="g_dates" placeholder="10-19 Jan 2027">
    <label>Award line (optional, sabke liye same)</label><input type="text" id="g_award" placeholder="Winner - Best Project">
    <label>Lead trainer (signature ke neeche)</label><input type="text" id="g_trainer">
    <label>Students (ek line mein ek naam, ya Name|Class)</label><textarea id="g_names" placeholder="Rohan Verma|9&#10;Asha Singh|8"></textarea>
    <label>Starting certificate number</label><input type="number" id="g_start" min="1">
    <div class="btns"><button class="btn sec" id="markIssued">Mark numbers as issued</button></div>
    <div class="hint">Print karne ke baad "Mark numbers as issued" dabao, taaki agli baar numbering aage se chale.</div>
  </section>

</aside>

<main class="stage">
  <div class="bar">
    <h3 id="barTitle">Preview</h3>
    <label id="layoutWrap">Layout
      <select id="layout"><option value="single">Single (1 per page)</option><option value="a4">A4 sheet (cut marks)</option></select>
    </label>
    <label>Zoom <input type="range" id="zoom" min="40" max="250" value="100"></label>
    <button class="btn pri" id="printBtn">Print / Save as PDF</button>
  </div>
  <iframe id="frame" title="Preview"></iframe>
</main>
</div>
<div class="toast" id="toast"></div>

<script>
(() => {
'use strict';
const $ = s => document.querySelector(s);
const esc = s => String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const val = id => (document.getElementById(id).value || '').trim();
const setv = (id, v) => { document.getElementById(id).value = v == null ? '' : v; };
const frame = $('#frame');
let S = {}, tab = 'card', trainers = [], cur = 0, rid = 0;
const zoomByTab = { company: 1.8, card: 1.8, id: 1.6, brochure: 0, cert: 0 };   // 0 = fit width
const titles = { company: 'Visiting card preview', card: 'Visiting card', id: 'Trainer ID cards', brochure: 'Brochure (tri-fold)', cert: 'Certificates' };

function toast(m) { const t = $('#toast'); t.textContent = m; t.classList.add('on'); setTimeout(() => t.classList.remove('on'), 2200); }
async function api(p, opt) {
  const r = await fetch('/sb-admin/api/' + p, Object.assign({ credentials: 'same-origin' }, opt || {}));
  if (r.status === 401) { location.reload(); throw new Error('auth'); }
  return r;
}

/* ---------- image helpers ---------- */
function resizeImage(file, max, type) {
  return new Promise((ok, no) => {
    if (file.type === 'image/svg+xml') {
      if (file.size > 200000) return no(new Error('SVG bahut badi hai'));
      const r = new FileReader(); r.onload = () => ok(r.result); r.onerror = no; return r.readAsDataURL(file);
    }
    const url = URL.createObjectURL(file), img = new Image();
    img.onload = () => {
      const k = Math.min(1, max / Math.max(img.width, img.height));
      const c = document.createElement('canvas'); c.width = Math.round(img.width * k); c.height = Math.round(img.height * k);
      c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
      URL.revokeObjectURL(url); ok(c.toDataURL(type, 0.88));
    };
    img.onerror = no; img.src = url;
  });
}

/* ---------- company (live from form) ---------- */
function C() {
  return { founder: val('c_founder'), role: val('c_role'), phone: val('c_phone'), email: val('c_email'),
           web: val('c_web'), addr: val('c_addr'), tag: val('c_tag') || 'Learn it. Build it. Show it.', logo: S.logo || '' };
}

/* ---------- shared print CSS ---------- */
const COMMON = `@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&family=Playfair+Display:ital,wght@0,600;0,700;1,600&display=swap');
:root{--navy:#0B1F3A;--navy2:#14386b;--orange:#FF6B2C;--amber:#FFB703;--teal:#14B8A6;--cream:#FFF8F0;--ink:#1d2939;--mute:#667085;--gold:#C9A227}
*{box-sizing:border-box;margin:0;padding:0;-webkit-print-color-adjust:exact;print-color-adjust:exact}
body{font-family:'Poppins','Segoe UI',Arial,sans-serif;color:var(--ink);background:#d9dde3}
.brand{display:flex;align-items:center;gap:2.2mm}
.mark{width:9mm;height:9mm;border-radius:2.2mm;background:linear-gradient(135deg,var(--orange),var(--amber));display:grid;place-items:center;color:#fff;font-weight:800;font-size:5.6mm;flex:none}
.logo-img{height:9mm;width:auto;flex:none}
.wordmark{display:flex;flex-direction:column;line-height:1}
.wordmark b{font-weight:800;letter-spacing:.4mm;font-size:4.3mm}
.wordmark i{font-style:normal;font-weight:600;font-size:1.9mm;letter-spacing:.95mm;color:var(--amber);margin-top:1mm}`;

function brand(c) {
  const m = c.logo ? `<img class="logo-img" src="${esc(c.logo)}" alt="">` : '<div class="mark">S</div>';
  return `<div class="brand">${m}<div class="wordmark"><b>SHAUNIX</b><i>SKILL BUILDERS</i></div></div>`;
}
const doc = (title, css, body) => `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>${esc(title)}</title><style>${COMMON}\n${css}</style></head><body>${body}</body></html>`;

/* ---------- layout: single OR A4 sheet with cut marks (duplex-aligned backs) ---------- */
function layoutCSS(w, h, mode) {
  const base = `.sheet{width:${w}mm;height:${h}mm;position:relative;overflow:hidden}`;
  if (mode === 'single')
    return base + `@page{size:${w}mm ${h}mm;margin:0}.sheet{page-break-after:always}.sheet:last-child{page-break-after:auto}@media screen{.sheet{margin:8mm auto;box-shadow:0 6px 24px rgba(0,0,0,.25)}}`;
  const cols = Math.floor(200 / w), rows = Math.floor(287 / h);
  return base + `@page{size:210mm 297mm;margin:0}.a4{width:210mm;height:297mm;display:grid;grid-template-columns:repeat(${cols},${w}mm);grid-auto-rows:${h}mm;justify-content:center;align-content:center;background:#fff;page-break-after:always}.a4:last-child{page-break-after:auto}.a4 .sheet{outline:.15mm dashed #b8bec9}@media screen{.a4{margin:8mm auto;box-shadow:0 6px 24px rgba(0,0,0,.25)}}`;
}
function assemble(title, css, fronts, backs, w, h, mode) {
  let body = '';
  if (mode === 'single') fronts.forEach((f, i) => { body += f + backs[i]; });
  else {
    const cols = Math.floor(200 / w), per = cols * Math.floor(287 / h);
    for (let i = 0; i < fronts.length; i += per) {
      const fc = fronts.slice(i, i + per), bc = backs.slice(i, i + per);
      body += `<div class="a4">${fc.join('')}</div>`;
      const grid = new Array(Math.ceil(fc.length / cols) * cols).fill('<div></div>');
      bc.forEach((b, j) => { grid[Math.floor(j / cols) * cols + (cols - 1 - (j % cols))] = b; });   // back side mirrored for duplex
      body += `<div class="a4">${grid.join('')}</div>`;
    }
  }
  return doc(title, layoutCSS(w, h, mode) + css, body);
}

/* =====================================================================
   1) VISITING CARD
   ===================================================================== */
const CARD_CSS = `
.front{background:linear-gradient(135deg,#0B1F3A 0%,#14386b 100%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center}
.c1{position:absolute;width:40mm;height:40mm;border-radius:50%;right:-13mm;top:-15mm;background:rgba(255,107,44,.20)}
.c2{position:absolute;width:28mm;height:28mm;border-radius:50%;left:-9mm;bottom:-11mm;background:rgba(20,184,166,.22)}
.front .brand{position:relative;gap:3mm}
.front .mark{width:13mm;height:13mm;font-size:8mm;border-radius:3mm}
.front .logo-img{height:13mm}
.front .wordmark b{font-size:6.6mm}
.front .wordmark i{font-size:2.4mm;letter-spacing:1.3mm;margin-top:1.4mm}
.tag{position:relative;margin-top:4.5mm;font-size:2.5mm;letter-spacing:.5mm;color:#dbe6f5;font-weight:500}
.strip{position:absolute;left:0;right:0;bottom:0;height:1.8mm;background:linear-gradient(90deg,var(--orange),var(--amber),var(--teal))}
.back{background:var(--cream);padding:6.5mm 7mm 6mm 9mm}
.back:before{content:'';position:absolute;left:0;top:0;bottom:0;width:2.4mm;background:linear-gradient(180deg,var(--orange),var(--amber))}
.back .brand{position:absolute;right:6mm;top:6mm;color:var(--navy);transform:scale(.62);transform-origin:top right}
.nm{margin-top:5mm;font-size:5mm;font-weight:700;color:var(--navy);line-height:1.1}
.rl{font-size:2.3mm;font-weight:600;color:var(--orange);letter-spacing:.5mm;text-transform:uppercase;margin-top:1.2mm}
.rows{position:absolute;left:9mm;bottom:6mm;right:6mm}
.row{display:flex;gap:2mm;font-size:2.55mm;margin-top:1.4mm;align-items:baseline;color:var(--ink)}
.row em{font-style:normal;font-weight:700;color:var(--orange);font-size:1.7mm;letter-spacing:.35mm;width:7.5mm;flex:none}`;

function cardDoc(mode) {
  const c = C(), L = brand(c);
  const f = `<div class="sheet front"><div class="c1"></div><div class="c2"></div>${L}<div class="tag">${esc(c.tag)}</div><div class="strip"></div></div>`;
  const b = `<div class="sheet back">${L}<div class="nm">${esc(val('k_name'))}</div><div class="rl">${esc(val('k_role'))}</div>
<div class="rows"><div class="row"><em>PHONE</em><span>${esc(val('k_phone'))}</span></div><div class="row"><em>EMAIL</em><span>${esc(val('k_email'))}</span></div>
<div class="row"><em>WEB</em><span>${esc(val('k_web'))}</span></div><div class="row"><em>ADDRESS</em><span>${esc(val('k_addr'))}</span></div></div></div>`;
  const n = mode === 'a4' ? 10 : 1;
  return assemble('Visiting Card', CARD_CSS, Array(n).fill(f), Array(n).fill(b), 90, 50, mode);
}

/* =====================================================================
   2) TRAINER ID CARD  (naya design: gradient photo ring, wave header, QR back)
   ===================================================================== */
const ID_CSS = `
.idf .top{position:absolute;left:0;right:0;top:0;height:37mm;background:linear-gradient(150deg,#0B1F3A 0%,#14386b 65%,#1d4f94 100%);overflow:hidden}
.idf .top:before{content:'';position:absolute;inset:0;background-image:radial-gradient(rgba(255,255,255,.14) .3mm,transparent .35mm);background-size:2.4mm 2.4mm}
.idf .top:after{content:'';position:absolute;width:32mm;height:32mm;border-radius:50%;right:-11mm;top:-13mm;background:rgba(255,107,44,.30)}
.idf .g2{position:absolute;width:22mm;height:22mm;border-radius:50%;left:-8mm;top:14mm;background:rgba(20,184,166,.28)}
.idf .slot{position:absolute;top:2.4mm;left:50%;margin-left:-6mm;width:12mm;height:2.2mm;border-radius:2mm;background:#e9eef7;box-shadow:inset 0 .35mm .7mm rgba(0,0,0,.4)}
.idf .bw{position:absolute;top:7mm;left:0;right:0;display:flex;justify-content:center;color:#fff}
.idf .bw .brand{transform:scale(.64);transform-origin:center top}
.idf .wave{position:absolute;left:-4mm;right:-4mm;top:32mm;height:12mm;background:#fff;border-radius:50% 50% 0 0/100% 100% 0 0}
.idf .ring{position:absolute;top:16mm;left:50%;margin-left:-15mm;width:30mm;height:30mm;border-radius:50%;padding:1.1mm;background:conic-gradient(from 200deg,#FF6B2C,#FFB703,#14B8A6,#FF6B2C);box-shadow:0 1.2mm 3.2mm rgba(11,31,58,.38)}
.idf .ph{width:100%;height:100%;border-radius:50%;border:.9mm solid #fff;background-size:cover;background-position:center;display:grid;place-items:center;color:#fff;font-weight:800;font-size:9mm;letter-spacing:.3mm}
.idf .body{position:absolute;left:0;right:0;top:48mm;bottom:9.5mm;display:flex;flex-direction:column;align-items:center;padding:0 3.5mm;text-align:center}
.idf .nm{font-weight:700;color:var(--navy);line-height:1.15;letter-spacing:-.1mm}
.idf .rl{margin-top:1.5mm;background:linear-gradient(90deg,var(--orange),var(--amber));color:#fff;font-size:1.95mm;font-weight:700;letter-spacing:.55mm;padding:.8mm 3.2mm;border-radius:5mm;text-transform:uppercase}
.idf .meta{margin-top:auto;margin-bottom:1.5mm;width:100%;display:flex;border:.25mm solid #f3dfcb;background:var(--cream);border-radius:2mm;overflow:hidden}
.idf .meta div{flex:1;padding:1.5mm 1mm}
.idf .meta div+div{border-left:.25mm solid #f3dfcb}
.idf .meta small{display:block;font-size:1.5mm;letter-spacing:.45mm;color:var(--mute);font-weight:600}
.idf .meta b{display:block;font-size:2.55mm;color:var(--navy);font-weight:700;margin-top:.3mm}
.foot{position:absolute;left:0;right:0;bottom:0;height:7.5mm;background:var(--navy);color:var(--amber);font-size:1.85mm;letter-spacing:.4mm;display:grid;place-items:center;font-weight:600;text-align:center;padding:0 2mm}
.foot:before{content:'';position:absolute;left:0;right:0;top:-.8mm;height:.8mm;background:linear-gradient(90deg,var(--orange),var(--amber),var(--teal))}
.idb{background:#fff}
.idb .bh{position:absolute;left:0;right:0;top:0;height:13.5mm;background:linear-gradient(150deg,#0B1F3A,#14386b);color:#fff;display:flex;justify-content:center;padding-top:3.6mm;overflow:hidden}
.idb .bh:before{content:'';position:absolute;width:20mm;height:20mm;border-radius:50%;right:-7mm;top:-9mm;background:rgba(255,107,44,.30)}
.idb .bh .brand{transform:scale(.62);transform-origin:center top;position:relative}
.idb .bh:after{content:'';position:absolute;left:0;right:0;bottom:0;height:.9mm;background:linear-gradient(90deg,var(--orange),var(--amber),var(--teal))}
.idb .bt{position:absolute;left:5mm;top:17.5mm;font-size:2.2mm;font-weight:700;letter-spacing:.7mm;color:var(--orange)}
.idb .bt:after{content:'';display:block;width:8mm;height:.5mm;background:var(--orange);margin-top:1mm;border-radius:1mm}
.idb .kvs{position:absolute;left:5mm;right:5mm;top:23.5mm}
.idb .kv{margin-bottom:2mm;padding-left:2.2mm;border-left:.5mm solid var(--amber)}
.idb .kv small{display:block;font-size:1.5mm;letter-spacing:.45mm;color:var(--mute);font-weight:600}
.idb .kv b{display:block;font-size:2.7mm;color:var(--navy);font-weight:600;margin-top:.2mm}
.idb .note{position:absolute;left:5mm;right:5mm;bottom:30mm;font-size:1.65mm;line-height:1.5;color:var(--mute)}
.idb .qr{position:absolute;left:5mm;bottom:10.5mm;display:flex;align-items:center;gap:2mm}
.idb .qr .box{width:15mm;height:15mm;padding:1mm;border:.25mm solid var(--line,#e3e8f1);border-radius:1.6mm;background:#fff;box-shadow:0 .4mm 1.2mm rgba(11,31,58,.12);display:grid;place-items:center;font-size:1.5mm;color:var(--mute)}
.idb .qr svg{width:100%;height:100%;display:block}
.idb .qr span{font-size:1.6mm;color:var(--mute);line-height:1.4;font-weight:500}
.idb .sig{position:absolute;right:5mm;bottom:12mm;width:21mm;border-top:.3mm solid var(--navy);font-size:1.55mm;text-align:center;padding-top:.7mm;color:var(--mute)}`;

const qrCache = {};
async function getQR(text) {
  if (text in qrCache) return qrCache[text];
  try { const r = await api('qr?text=' + encodeURIComponent(text)); qrCache[text] = r.ok ? await r.text() : ''; }
  catch (e) { qrCache[text] = ''; }
  return qrCache[text];
}
const initials = n => (n.trim().split(/\s+/).filter(Boolean).map((w, i, a) => (i === 0 || i === a.length - 1) ? w[0] : '').join('') || 'S').toUpperCase().slice(0, 2);

async function idDoc(mode) {
  const c = C(), L = brand(c);
  const web = c.web ? (/^https?:/i.test(c.web) ? c.web : 'https://' + c.web.replace(/^\/+/, '')) : '';
  const qr = web ? await getQR(web.replace(/\/+$/, '') + '/skill-builders') : '';
  const fronts = [], backs = [];
  trainers.forEach(t => {
    const nm = t.name || 'Trainer Name';
    const fs = nm.length > 26 ? 3.3 : nm.length > 19 ? 3.8 : 4.4;
    const ph = t.photo ? `background-image:url('${t.photo}')` : 'background:linear-gradient(135deg,#FF6B2C,#FFB703)';
    fronts.push(`<div class="sheet idf"><div class="top"></div><div class="g2"></div><div class="slot"></div><div class="bw">${L}</div><div class="wave"></div>
<div class="ring"><div class="ph" style="${ph}">${t.photo ? '' : esc(initials(nm))}</div></div>
<div class="body"><div class="nm" style="font-size:${fs}mm">${esc(nm)}</div><div class="rl">${esc(t.role || 'Trainer')}</div>
<div class="meta"><div><small>ID NO.</small><b>${esc(t.idno)}</b></div><div><small>VALID TILL</small><b>${esc(t.valid)}</b></div></div></div>
<div class="foot">${esc(c.tag)}</div></div>`);
    backs.push(`<div class="sheet idb"><div class="bh">${L}</div><div class="bt">TRAINER DETAILS</div>
<div class="kvs"><div class="kv"><small>PHONE</small><b>${esc(t.phone)}</b></div>${t.blood ? `<div class="kv"><small>BLOOD GROUP</small><b>${esc(t.blood)}</b></div>` : ''}<div class="kv"><small>EMERGENCY CONTACT</small><b>${esc(t.em)}</b></div></div>
<div class="note">Property of Shaunix Skill Builders. To be worn visibly inside school premises. If found, please return to: ${esc(c.addr)}</div>
<div class="qr"><div class="box">${qr || 'QR'}</div><span>Scan to visit<br>our website</span></div>
<div class="sig">Authorised Signatory</div><div class="foot">${esc(c.web)}</div></div>`);
  });
  return assemble('Trainer ID Cards', ID_CSS, fronts, backs, 54, 86, mode);
}

/* =====================================================================
   3) BROCHURE
   ===================================================================== */
const BRO_CSS = `
@page{size:297mm 210mm;margin:0}
.page{width:297mm;height:210mm;display:flex;overflow:hidden;page-break-after:always;background:#fff}
.page:last-child{page-break-after:auto}
@media screen{.page{margin:8mm auto;box-shadow:0 6px 24px rgba(0,0,0,.25)}}
.pn{width:99mm;height:210mm;position:relative;overflow:hidden;padding:13mm 10mm;font-size:3.3mm;line-height:1.55}
.dark{background:linear-gradient(160deg,#0B1F3A 0%,#14386b 100%);color:#fff}
.cream{background:var(--cream)}
h2{font-size:6.4mm;font-weight:800;color:var(--navy);line-height:1.15;margin-bottom:2mm}
.dark h2{color:#fff}
.kick{font-size:2.5mm;font-weight:700;letter-spacing:.8mm;color:var(--orange);text-transform:uppercase;margin-bottom:2mm}
.bar{width:14mm;height:1.1mm;background:linear-gradient(90deg,var(--orange),var(--amber));border-radius:1mm;margin:2.5mm 0 4mm}
.circ{position:absolute;border-radius:50%}
.pt{display:flex;gap:3mm;margin-top:4mm}.pt .n{width:7.5mm;height:7.5mm;border-radius:50%;background:var(--orange);color:#fff;font-weight:700;display:grid;place-items:center;flex:none;font-size:3.4mm}
.pt b{display:block;color:var(--navy);font-size:3.6mm}.pt span{color:var(--mute);font-size:3mm;line-height:1.45;display:block}
.tbl{margin-top:5mm;border-radius:2.5mm;overflow:hidden;border:.3mm solid #f1dfcf;background:#fff}
.tbl div{display:flex;justify-content:space-between;padding:1.7mm 3.5mm;font-size:3mm;border-bottom:.25mm solid #f5e8db}.tbl div:last-child{border:0}
.tbl .h{background:var(--navy);color:#fff;font-weight:600}.tbl b{color:var(--orange)}
.cover{display:flex;flex-direction:column;justify-content:space-between}
.cover .big{font-size:11.5mm;font-weight:800;line-height:1.08;position:relative}
.cover .big span{color:var(--amber)}
.cover p.sub{font-size:4mm;color:#cfdcf0;margin-top:5mm;position:relative}
.badge{display:inline-flex;gap:3mm;align-items:center;margin-top:8mm;background:rgba(255,255,255,.1);border:.3mm solid rgba(255,255,255,.3);padding:2.5mm 5mm;border-radius:10mm;font-weight:700;font-size:4.2mm;position:relative}
.badge i{font-style:normal;color:var(--amber)}
.foot{font-size:2.6mm;letter-spacing:.7mm;color:var(--amber);font-weight:600;position:relative}
.dark .brand{position:relative;color:#fff}
.chips2{display:flex;gap:2.5mm;margin-top:6mm}
.chip{flex:1;background:#fff;border-radius:3mm;padding:3mm 1mm;text-align:center;border:.3mm solid #f1dfcf}
.chip b{display:block;font-size:7mm;color:var(--orange);line-height:1}.chip small{font-size:2.5mm;color:var(--mute);font-weight:600}
.tl{position:relative;margin-top:5mm;padding-left:8mm}.tl:before{content:'';position:absolute;left:2.2mm;top:1mm;bottom:1mm;width:.7mm;background:linear-gradient(var(--orange),var(--teal));border-radius:1mm}
.st{position:relative;margin-bottom:4.6mm}.st:before{content:'';position:absolute;left:-8.2mm;top:1.1mm;width:4.2mm;height:4.2mm;border-radius:50%;background:#fff;border:.9mm solid var(--orange)}
.st b{color:var(--navy);font-size:3.6mm;display:block}.st small{color:var(--orange);font-weight:700;font-size:2.6mm;letter-spacing:.5mm}.st span{color:var(--mute);font-size:3mm;line-height:1.45;display:block}
.tr{display:flex;gap:3mm;margin-top:3.4mm;align-items:flex-start}.tr i{width:3mm;height:3mm;border-radius:1mm;margin-top:1.1mm;flex:none}
.tr b{color:var(--navy);font-size:3.4mm}.tr span{display:block;color:var(--mute);font-size:2.9mm;line-height:1.4}
.ages{display:flex;gap:2mm;margin-top:5mm}.ages div{flex:1;text-align:center;background:var(--navy);color:#fff;border-radius:2.5mm;padding:2mm 0;font-size:2.7mm}.ages b{display:block;color:var(--amber);font-size:3.4mm}
.fee{margin-top:4mm;background:linear-gradient(135deg,var(--orange),var(--amber));color:#fff;border-radius:3mm;padding:3mm;text-align:center}.fee b{display:block;font-size:8mm;line-height:1.1}.fee small{font-size:2.6mm;display:block}
.ct{margin-top:6mm}.ct div{display:flex;gap:3mm;margin-top:2.6mm;font-size:3.3mm}.ct em{font-style:normal;color:var(--amber);font-weight:700;font-size:2.4mm;letter-spacing:.4mm;width:16mm;flex:none;padding-top:.6mm}
.disc{position:absolute;left:10mm;right:10mm;bottom:10mm;font-size:2.4mm;color:#9db3d3;line-height:1.5;border-top:.25mm solid rgba(255,255,255,.2);padding-top:3mm}`;

function brochureDoc() {
  const c = C(), L = brand(c), fee = val('b_fee').replace(/[^0-9.,]/g, '');
  const feeHtml = fee ? `<div class="fee"><small>Program fee</small><b>&#8377;${esc(fee)}</b><small>per student, material included*</small></div>` : '';
  const body = `
<div class="page">
 <div class="pn cream">
  <div class="kick">Why Schools Choose Us</div><h2>Real skills.<br>Real projects.</h2><div class="bar"></div>
  <div class="pt"><div class="n">1</div><div><b>Learn by building</b><span>Har din hands-on activity, sirf theory nahi.</span></div></div>
  <div class="pt"><div class="n">2</div><div><b>Safe &amp; supervised</b><span>Low-voltage kits, verified trainers aur written school agreement.</span></div></div>
  <div class="pt"><div class="n">3</div><div><b>Zero burden on school</b><span>Extra teacher ya setup ki zaroorat nahi. Hum sab laate hain.</span></div></div>
  <div class="pt"><div class="n">4</div><div><b>Transparent judging</b><span>Showcase ke marks pehle se sabko bataye jaate hain.</span></div></div>
  <div class="tbl"><div class="h"><span>Project judging</span><span>Marks</span></div>
   <div><span>Working model</span><b>30</b></div><div><span>Innovation</span><b>25</b></div><div><span>Practical usefulness</span><b>20</b></div><div><span>Presentation</span><b>15</b></div><div><span>Creativity</span><b>10</b></div></div>
 </div>
 <div class="pn dark">
  <div class="circ" style="width:70mm;height:70mm;right:-25mm;top:-20mm;background:rgba(255,107,44,.16)"></div>
  ${L}
  <div style="margin-top:14mm;position:relative"><div class="kick">About Us</div><h2>Bacchon ko creators banate hain.</h2><div class="bar"></div>
  <p style="color:#cfdcf0">Shaunix Skill Builders schools ke liye practical skill-development programs chalata hai. Bacchon ko AI, coding, electronics, PC hardware aur green energy jaisi technologies seekhne aur apna working project banakar dikhane ka mauka milta hai.</p></div>
  <div class="ct">
   <div><em>CONTACT</em><span>${esc(c.founder)}<br><small style="color:#9db3d3">${esc(c.role)}</small></span></div>
   <div><em>PHONE</em><span>${esc(c.phone)}</span></div>
   <div><em>EMAIL</em><span>${esc(c.email)}</span></div>
   <div><em>WEB</em><span>${esc(c.web)}</span></div>
   <div><em>ADDRESS</em><span>${esc(c.addr)}</span></div>
  </div>
  <div class="disc">Certificates are "Certificate of Participation" issued by Shaunix Skill Builders. This is a private skill-development program and not a government-recognised qualification.</div>
 </div>
 <div class="pn dark cover">
  <div class="circ" style="width:95mm;height:95mm;left:-30mm;bottom:-35mm;background:rgba(20,184,166,.2)"></div>
  <div class="circ" style="width:50mm;height:50mm;right:-14mm;top:70mm;background:rgba(255,183,3,.14)"></div>
  ${L}
  <div><div class="big">Seekho.<br>Banao.<br><span>Dikhao.</span></div>
   <p class="sub">Hands-on skill programs<br>for schools &amp; young creators</p>
   <div class="badge"><i>7 + 3</i> Days Program</div></div>
  <div class="foot">PRACTICAL SKILLS &bull; INNOVATION &bull; CREATIVITY</div>
 </div>
</div>
<div class="page">
 <div class="pn cream">
  <div class="kick">The Idea</div><h2>Seekhne se aage,<br>banana.</h2><div class="bar"></div>
  <p style="color:var(--mute)">Aaj bacchon ko theory bahut milti hai, lekin hands-on exposure kam. Hamara program class ko ek workshop mein badal deta hai, jahan har bachcha kuch apne haath se banata hai aur sabke saamne dikhata hai.</p>
  <div class="chips2"><div class="chip"><b>7</b><small>DAYS TRAINING</small></div><div class="chip"><b>3</b><small>DAYS LIVE PROJECT</small></div><div class="chip"><b>1</b><small>FINAL SHOWCASE</small></div></div>
  <p style="margin-top:6mm;color:var(--mute)"><b style="color:var(--navy)">School ko milta hai:</b> ek complete extracurricular activity, showcase ke photos aur report, aur parents ke saamne school ki strong image.</p>
  <div class="ages"><div><b>Junior</b>Class 6-8</div><div><b>Intermediate</b>Class 8-10</div><div><b>Senior</b>Class 9-12</div></div>
 </div>
 <div class="pn" style="background:#fff">
  <div class="kick">The Journey</div><h2>The 7 + 3 Model</h2><div class="bar"></div>
  <div class="tl">
   <div class="st"><small>DAY 1 - 2</small><b>Foundation</b><span>Concepts samjho aur pehli hands-on activity karo.</span></div>
   <div class="st"><small>DAY 3 - 5</small><b>Build Skills</b><span>Tools, kits aur practical exercises, teams mein.</span></div>
   <div class="st"><small>DAY 6 - 7</small><b>Plan Your Project</b><span>Apna project idea chuno aur plan banao.</span></div>
   <div class="st"><small>DAY 8 - 10</small><b>Live Project</b><span>Mentor ki madad se apna working project banao.</span></div>
   <div class="st"><small>FINAL DAY</small><b>Showcase &amp; Awards</b><span>Demo, judging, prizes aur Certificate of Participation.</span></div>
  </div>
 </div>
 <div class="pn cream">
  <div class="kick">Programs</div><h2>Choose a Track</h2><div class="bar"></div>
  <div class="tr"><i style="background:var(--orange)"></i><div><b>AI &amp; Future Tech</b><span>Chatbots, image recognition, responsible AI</span></div></div>
  <div class="tr"><i style="background:var(--teal)"></i><div><b>Coding &amp; Apps</b><span>Websites, games, quiz apps (Node.js, C++, Java)</span></div></div>
  <div class="tr"><i style="background:var(--amber)"></i><div><b>PC Hardware &amp; Networking</b><span>Build a PC, fix faults, set up a network</span></div></div>
  <div class="tr"><i style="background:var(--navy)"></i><div><b>Electronics &amp; Robotics</b><span>Sensors, smart dustbin, obstacle robot</span></div></div>
  <div class="tr"><i style="background:#22c55e"></i><div><b>Green Energy</b><span>Solar street light, solar mini fan</span></div></div>
  <div class="tr"><i style="background:#a855f7"></i><div><b>Cyber Safety &amp; Digital Skills</b><span>Safe internet, creator and business basics</span></div></div>
  ${feeHtml}
  <p style="font-size:2.5mm;color:var(--mute);margin-top:3mm">${fee ? '*Material scope as agreed in the written school agreement. ' : ''}Track availability may vary by batch.</p>
 </div>
</div>`;
  return doc('Brochure', BRO_CSS, body);
}

/* =====================================================================
   4) CERTIFICATES
   ===================================================================== */
const CERT_CSS = `
@page{size:297mm 210mm;margin:0}
.cert{width:297mm;height:210mm;position:relative;overflow:hidden;background:#fffdf8;page-break-after:always}
.cert:last-child{page-break-after:auto}
@media screen{.cert{margin:8mm auto;box-shadow:0 6px 24px rgba(0,0,0,.25)}}
.b1{position:absolute;inset:7mm;border:1.8mm solid var(--navy)}
.b2{position:absolute;inset:11.5mm;border:.5mm solid var(--gold)}
.cn1{position:absolute;left:7mm;top:7mm;width:60mm;height:60mm;background:linear-gradient(135deg,var(--orange) 0,var(--amber) 55%,transparent 55%);opacity:.9;clip-path:polygon(0 0,100% 0,0 100%)}
.cn2{position:absolute;right:7mm;bottom:7mm;width:60mm;height:60mm;background:linear-gradient(315deg,var(--navy) 0,var(--navy2) 55%,transparent 55%);clip-path:polygon(100% 100%,0 100%,100% 0)}
.wm{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);font-size:150mm;font-weight:800;color:rgba(11,31,58,.035);line-height:1}
.ct{position:absolute;inset:16mm 30mm 14mm;display:flex;flex-direction:column;align-items:center;text-align:center}
.ct .brand{color:var(--navy);margin-top:3mm}
.t1{margin-top:7mm;font-family:'Playfair Display',Georgia,serif;font-size:19mm;font-weight:700;color:var(--navy);line-height:1}
.t2{margin-top:2.5mm;font-size:4.4mm;font-weight:600;letter-spacing:2.2mm;color:var(--orange)}
.t3{margin-top:7mm;font-size:3.6mm;color:var(--mute);letter-spacing:.5mm}
.nm{margin-top:3mm;font-family:'Playfair Display',Georgia,serif;font-style:italic;font-size:13.5mm;font-weight:600;color:var(--navy);padding:0 10mm 1.5mm;border-bottom:.6mm solid var(--gold);line-height:1.2}
.sc{margin-top:3.2mm;font-size:4mm;font-weight:600;color:var(--navy)}
.tx{margin-top:3.5mm;font-size:3.7mm;color:var(--ink);line-height:1.65;max-width:175mm}
.tx b{color:var(--navy)}
.aw{margin-top:4mm;background:linear-gradient(90deg,var(--orange),var(--amber));color:#fff;font-weight:700;font-size:4mm;letter-spacing:.6mm;padding:1.8mm 8mm;border-radius:10mm}
.ft{position:absolute;left:30mm;right:30mm;bottom:19mm;display:flex;justify-content:space-between;align-items:flex-end}
.sg{width:58mm;text-align:center;font-size:3mm;color:var(--mute)}
.sg .ln{border-top:.4mm solid var(--navy);padding-top:1.5mm}.sg b{display:block;color:var(--navy);font-size:3.4mm}
.sg .dt{font-size:3.4mm;color:var(--navy);font-weight:600;margin-bottom:1.5mm}
.seal{width:27mm;height:27mm;border-radius:50%;background:radial-gradient(circle,var(--amber),var(--gold));box-shadow:0 0 0 1.2mm #fff,0 0 0 1.8mm var(--gold);display:grid;place-items:center;text-align:center;color:#fff;font-weight:800;font-size:2.7mm;line-height:1.25;letter-spacing:.3mm}
.seal span{display:block;font-size:6mm}
.fn{position:absolute;left:0;right:0;bottom:12.5mm;text-align:center;font-size:2.3mm;color:var(--mute)}
.empty{padding:40mm;text-align:center;font-size:5mm;color:#667085}`;

function certList() {
  return val('g_names').split('\n').map(s => s.trim()).filter(Boolean).map(l => {
    const i = l.indexOf('|');
    return i < 0 ? { name: l, cls: val('g_class') } : { name: l.slice(0, i).trim(), cls: l.slice(i + 1).trim() || val('g_class') };
  });
}
function certDoc() {
  const c = C(), L = brand(c), list = certList();
  if (!list.length) return doc('Certificates', CERT_CSS, '<div class="empty">Left side mein students ke naam likho (ek line mein ek naam).</div>');
  const start = Math.max(1, parseInt(val('g_start'), 10) || 1), yr = new Date().getFullYear();
  const aw = val('g_award');
  const body = list.map((s, i) => {
    const no = 'SSB-' + yr + '-' + String(start + i).padStart(3, '0');
    return `<div class="cert"><div class="cn1"></div><div class="cn2"></div><div class="b1"></div><div class="b2"></div><div class="wm">S</div>
<div class="ct">${L}
 <div class="t1">Certificate</div><div class="t2">OF PARTICIPATION</div>
 <div class="t3">THIS CERTIFICATE IS PROUDLY PRESENTED TO</div>
 <div class="nm">${esc(s.name)}</div>
 <div class="sc">${esc(val('g_school'))}${s.cls ? ', Class ' + esc(s.cls) : ''}</div>
 <div class="tx">for successfully participating in the <b>${esc(val('g_course'))}</b> (${esc(val('g_dur'))}), held on <b>${esc(val('g_dates'))}</b>, and for showing curiosity, teamwork and creativity by building and presenting a project.</div>
 ${aw ? `<div class="aw">${esc(aw)}</div>` : ''}
</div>
<div class="ft">
 <div class="sg"><div class="dt">${esc(val('g_dates'))}</div><div class="ln"><b>${esc(val('g_trainer'))}</b>Lead Trainer</div></div>
 <div class="seal"><div><span>S</span>SKILL<br>BUILDERS</div></div>
 <div class="sg"><div class="dt">${no}</div><div class="ln"><b>${esc(c.founder)}</b>${esc(c.role)}</div></div>
</div>
<div class="fn">Certificate of Participation issued by Shaunix Skill Builders. Private skill-development program; not a government-recognised qualification.</div>
</div>`;
  }).join('');
  return doc('Certificates', CERT_CSS, body);
}

/* =====================================================================
   RENDER + UI
   ===================================================================== */
function fit() {
  let d; try { d = frame.contentDocument; } catch (e) { return; }
  if (!d || !d.body) return;
  let z = parseInt($('#zoom').value, 10) / 100;
  d.body.style.zoom = z;
  frame.style.height = Math.max(300, d.documentElement.scrollHeight + 20) + 'px';
}
async function render() {
  const my = ++rid;
  const mode = $('#layout').value;
  let html;
  if (tab === 'company' || tab === 'card') html = cardDoc(mode);
  else if (tab === 'id') html = await idDoc(mode);
  else if (tab === 'brochure') html = brochureDoc();
  else html = certDoc();
  if (my !== rid) return;
  frame.onload = () => { fit(); try { frame.contentDocument.fonts.ready.then(fit); } catch (e) {} };
  frame.srcdoc = html;
}
let timer; const later = () => { clearTimeout(timer); timer = setTimeout(render, 250); };

function setZoomDefault() {
  let z = zoomByTab[tab];
  if (tab === 'card' || tab === 'company' || tab === 'id') z = $('#layout').value === 'a4' ? 0.8 : z;
  if (!z) z = Math.min(1, Math.max(0.4, ($('.stage').clientWidth - 60) / 1130));
  $('#zoom').value = Math.round(z * 100);
}
function showTab(t) {
  tab = t;
  document.querySelectorAll('#tabs button').forEach(b => b.classList.toggle('on', b.dataset.t === t));
  document.querySelectorAll('.pane').forEach(p => p.classList.toggle('on', p.id === 'p-' + t));
  $('#barTitle').textContent = titles[t];
  $('#layoutWrap').style.display = (t === 'card' || t === 'id') ? '' : 'none';
  if (t === 'company') { $('#layoutWrap').style.display = 'none'; $('#layout').value = 'single'; }
  setZoomDefault(); render();
}

/* ---------- trainers ---------- */
function saveTrainers() { try { localStorage.setItem('sb_trainers', JSON.stringify(trainers)); } catch (e) {} }
function newTrainer() {
  return { name: '', role: 'Lead Trainer', idno: 'SSB-T-' + String(trainers.length + 1).padStart(3, '0'), phone: '', blood: '', valid: 'Dec ' + (new Date().getFullYear() + 1), em: '', photo: '' };
}
function drawTrainerList() {
  const box = $('#tlist'); box.innerHTML = '';
  trainers.forEach((t, i) => {
    const b = document.createElement('button'); b.textContent = t.name || ('Trainer ' + (i + 1));
    if (i === cur) b.className = 'on';
    b.onclick = () => { cur = i; loadTrainer(); drawTrainerList(); };
    box.appendChild(b);
  });
}
function loadTrainer() {
  const t = trainers[cur];
  setv('t_name', t.name); setv('t_role', t.role); setv('t_id', t.idno); setv('t_phone', t.phone);
  setv('t_blood', t.blood); setv('t_valid', t.valid); setv('t_em', t.em); $('#t_photo').value = '';
}
function readTrainer() {
  const t = trainers[cur];
  t.name = val('t_name'); t.role = val('t_role'); t.idno = val('t_id'); t.phone = val('t_phone');
  t.blood = val('t_blood'); t.valid = val('t_valid'); t.em = val('t_em');
  saveTrainers();
}

/* ---------- init ---------- */
async function init() {
  S = await (await api('settings')).json();
  setv('c_founder', S.founder); setv('c_role', S.role); setv('c_phone', S.phone); setv('c_email', S.email);
  setv('c_web', S.web); setv('c_addr', S.addr); setv('c_tag', S.tag);
  fillCard();
  setv('g_course', 'Hands-on Skill Builders Program'); setv('g_dur', '7+3 Days');
  setv('g_start', (S.certCounter || 0) + 1);
  try { trainers = JSON.parse(localStorage.getItem('sb_trainers') || '[]'); } catch (e) { trainers = []; }
  if (!Array.isArray(trainers) || !trainers.length) trainers = [newTrainer()];
  loadTrainer(); drawTrainerList();

  document.querySelectorAll('#tabs button').forEach(b => b.onclick = () => showTab(b.dataset.t));
  document.querySelector('.panel').addEventListener('input', e => {
    if (e.target.id && e.target.id.startsWith('t_') && e.target.type !== 'file') { readTrainer(); drawTrainerList(); }
    later();
  });
  $('#layout').onchange = () => { setZoomDefault(); render(); };
  $('#zoom').oninput = fit;
  window.addEventListener('resize', () => { if (!zoomByTab[tab]) { setZoomDefault(); fit(); } });

  $('#cardFill').onclick = () => { fillCard(); render(); };
  $('#saveCompany').onclick = saveCompany;
  $('#rmLogo').onclick = () => { S.logo = ''; $('#c_logo').value = ''; render(); toast('Logo hata diya (Save dabao)'); };
  $('#c_logo').onchange = async e => {
    const f = e.target.files[0]; if (!f) return;
    try { S.logo = await resizeImage(f, 400, 'image/png'); render(); toast('Logo set. Save dabao.'); }
    catch (err) { toast('Logo load nahi hua'); }
  };
  $('#t_photo').onchange = async e => {
    const f = e.target.files[0]; if (!f) return;
    try { trainers[cur].photo = await resizeImage(f, 480, 'image/jpeg'); saveTrainers(); render(); }
    catch (err) { toast('Photo load nahi hui'); }
  };
  $('#tAdd').onclick = () => { trainers.push(newTrainer()); cur = trainers.length - 1; loadTrainer(); drawTrainerList(); saveTrainers(); render(); };
  $('#tDel').onclick = () => {
    if (trainers.length === 1) { trainers[0] = newTrainer(); } else { trainers.splice(cur, 1); cur = Math.max(0, cur - 1); }
    loadTrainer(); drawTrainerList(); saveTrainers(); render();
  };
  $('#markIssued').onclick = async () => {
    const n = certList().length; if (!n) return toast('Pehle students ke naam likho');
    const next = Math.max(1, parseInt(val('g_start'), 10) || 1) + n - 1;
    await api('cert-counter', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ value: next }) });
    S.certCounter = next; setv('g_start', next + 1); render(); toast('Numbers issued mark ho gaye');
  };
  $('#printBtn').onclick = async () => {
    const w = frame.contentWindow, d = frame.contentDocument; if (!d || !d.body) return;
    d.body.style.zoom = 1;
    try { await d.fonts.ready; } catch (e) {}
    w.focus(); w.print();
    setTimeout(fit, 600);
  };
  showTab('card');
}
function fillCard() {
  const c = C();
  setv('k_name', c.founder); setv('k_role', c.role); setv('k_phone', c.phone); setv('k_email', c.email); setv('k_web', c.web); setv('k_addr', c.addr);
}
async function saveCompany() {
  const c = C(); c.logo = S.logo || '';
  const r = await api('settings', { method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: JSON.stringify(c) });
  toast(r.ok ? 'Company details saved' : 'Save nahi hua');
  if (r.ok) { Object.assign(S, c); fillCard(); render(); }
}
init().catch(e => { if (e.message !== 'auth') toast('Load error: ' + e.message); });
})();
</script>
</body>
</html>
EOF

# =====================================================================
# 4) NODE: .env (password hash), server.js, .gitignore
# =====================================================================
SB_PW="$SB_PW" node - "$ROOT" <<'EOF'
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const root = process.argv[2];
const P = p => path.join(root, p);
const pw = process.env.SB_PW || '';

/* ---- .env : hash + secret ---- */
let env = fs.existsSync(P('.env')) ? fs.readFileSync(P('.env'), 'utf8') : '';
const has = k => new RegExp('^' + k + '=', 'm').test(env);
const drop = k => { env = env.replace(new RegExp('^' + k + '=.*\\n?', 'm'), ''); };
if (pw) {
  const salt = crypto.randomBytes(16);
  const hash = crypto.scryptSync(pw, salt, 64);
  drop('SB_ADMIN_HASH');
  if (env && !env.endsWith('\n')) env += '\n';
  env += 'SB_ADMIN_HASH=scrypt:' + salt.toString('hex') + ':' + hash.toString('hex') + '\n';
  console.log('  DONE .env: admin password hash saved');
}
if (!has('SB_SESSION_SECRET')) {
  if (env && !env.endsWith('\n')) env += '\n';
  env += 'SB_SESSION_SECRET=' + crypto.randomBytes(32).toString('hex') + '\n';
  console.log('  DONE .env: session secret generated');
}
fs.writeFileSync(P('.env'), env, { mode: 0o600 });

/* ---- server.js : redirect-all se PEHLE ---- */
let s = fs.readFileSync(P('server.js'), 'utf8');
if (s.includes('routes/sb-admin')) {
  console.log('  OK   server.js (pehle se hai)');
} else {
  const add = "/* 3d) SHAUNIX SKILL BUILDERS — private admin print kit (/sb-admin, password protected) */\napp.use(require('./routes/sb-admin'));\n\n";
  let out = s;
  if (/\/\* 4\) Redirect/.test(s)) out = s.replace(/\/\* 4\) Redirect/, add + '/* 4) Redirect');
  else { const m = s.match(/app\.use\(\(req,\s*res\)\s*=>\s*res\.redirect\('\/'\)\);/); if (m) out = s.replace(m[0], add + m[0]); }
  if (out === s) console.log('  WARN server.js: marker nahi mila. Redirect-all se pehle ye line manually add karo:\n       app.use(require(\'./routes/sb-admin\'));');
  else { fs.writeFileSync(P('server.js'), out); console.log('  DONE server.js: /sb-admin route registered'); }
}

/* ---- .gitignore ---- */
let gi = fs.existsSync(P('.gitignore')) ? fs.readFileSync(P('.gitignore'), 'utf8') : '';
const need = ['.env', 'data/', '.sb_*backup_*/'].filter(x => !gi.split('\n').map(l => l.trim()).includes(x));
if (need.length) {
  if (gi && !gi.endsWith('\n')) gi += '\n';
  fs.writeFileSync(P('.gitignore'), gi + need.join('\n') + '\n');
  console.log('  DONE .gitignore: ' + need.join(', '));
}
EOF
chmod 600 "$ROOT/.env" 2>/dev/null

# =====================================================================
# 5) SMOKE TEST
# =====================================================================
echo; line
if [ -d "$ROOT/node_modules" ] && [ -n "$SB_PW" ]; then
  read -r -p "  Quick test chalau? (server temporarily port 3999 par) (y/n) [y]: " T; T="${T:-y}"
  if [[ "$T" =~ ^[Yy] ]]; then
    ( cd "$ROOT" && PORT=3999 node server.js >/dev/null 2>&1 & echo $! > "$BK/pid" )
    sleep 2
    U=http://localhost:3999/sb-admin
    JAR="$BK/jar.txt"
    A=$(curl -s -o "$BK/login.html" -w '%{http_code}' "$U")
    B=$(curl -s -o /dev/null -w '%{http_code}' "$U/api/settings")
    C1=$(curl -s -o /dev/null -w '%{http_code}' -c "$JAR" --data-urlencode "password=wrong-password-xyz" "$U/login")
    D=$(curl -s -o /dev/null -w '%{http_code}' -c "$JAR" --data-urlencode "password=$SB_PW" "$U/login")
    E=$(curl -s -o "$BK/app.html" -w '%{http_code}' -b "$JAR" "$U")
    F=$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" "$U/api/settings")
    G=$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" "$U/api/qr?text=https://example.com")
    kill "$(cat "$BK/pid")" 2>/dev/null
    echo "  login page          : $A   (200 chahiye)"
    echo "  api bina login      : $B   (401 chahiye)"
    echo "  galat password      : $C1  (302 chahiye)"
    echo "  sahi password       : $D   (302 chahiye)"
    echo "  admin app (login ke baad): $E (200 chahiye)"
    echo "  settings API        : $F   (200 chahiye)"
    echo "  QR API              : $G   (200 chahiye; 501 = qrcode package nahi mila, QR box khali rahega)"
    if [ "$A" = "200" ] && [ "$B" = "401" ] && [ "$D" = "302" ] && [ "$E" = "200" ] && [ "$F" = "200" ]; then echo "  Test PASS"; else echo "  Test mein dikkat, upar ke codes dekho"; fi
    rm -f "$JAR" "$BK/app.html" "$BK/login.html" "$BK/pid"
  fi
else
  echo "  (Test skip: node_modules nahi hai ya password change nahi hua)"
fi

echo; line
echo "  Ho gaya! Server restart karo:"
echo "     cd \"$ROOT\" && npm start"
echo "  Admin kholo:  http://localhost:3000/sb-admin"
echo "  Deploy karne par .env file bhi server par honi chahiye (SB_ADMIN_HASH, SB_SESSION_SECRET)."
echo "  Undo:         bash $BK/RESTORE.sh"
line
