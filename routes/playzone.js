/* ============================================================
   playzone.js — SHAUNIX PLAYZONE (Admin Play Key Generator)
   GET  /playzone_key      -> Hidden admin page (noindex)
   POST /playzone_key/api  -> Generate PLAY KEY → Apps Script → Google Sheet
   ------------------------------------------------------------
   Flow:
   Website (admin) → POST JSON → Google Apps Script Web App
   → Google Sheet (shaunix_playzone)

   Gaming PCs OFFLINE hain — ye page SIRF website side ke liye hai.
   Google Sheet kabhi direct browser se read nahi hoti — sheet hamesha
   Apps Script API ke peeche rahti hai.
   URL: .env PLAYZONE_WEB_APP_URL > config.js playzoneWebAppUrl
   ============================================================ */

const express = require('express');
const crypto  = require('crypto');
const { renderPage } = require('./render');

const router = express.Router();
const CFG    = require('../config');   /* Business data from config.js */

/* Google Apps Script Web App URL — .env override > config.js (single source) */
const PLAYZONE_WEB_APP_URL = process.env.PLAYZONE_WEB_APP_URL || CFG.playzoneWebAppUrl || '';

/* ---------- Allowed values (single source — UI aur API dono isi se validate hote hain) ---------- */
const PCS            = ['PC-01', 'PC-02', 'PC-03'];
const GAMES          = ['Tekken 3', 'Street Fighter Alpha 3', 'Mortal Kombat 4', 'Marvel vs. Capcom', 'Metal Slug 3', 'Contra', 'Super Mario Bros.', 'Road Rash'];
const DURATIONS      = [15, 30, 60, 120];
const PAYMENT_METHODS = ['Cash', 'UPI'];

/* Ambiguous chars (O/0, I/1, L) avoid karne ke liye — 32 clean characters */
const KEY_CHARS = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/* ---------- PLAY KEY PAGE (hidden — sirf direct URL se) ---------- */
router.get('/playzone_key', (req, res) => {
  renderPage(res, 'playzone.html');
});

/* ---------- GENERATE PLAY KEY (API) ---------- */
router.post('/playzone_key/api', async (req, res) => {
  if (!PLAYZONE_WEB_APP_URL) {
    return res.status(503).json({
      ok: false,
      error: 'Playzone is not configured yet. Please set the Apps Script URL in config.js (playzoneWebAppUrl).'
    });
  }

  const body = req.body || {};

  /* 1) Validate — values sirf allowed list se aa sakti hain */
  const pcId    = String(body.pc_id || '').trim();
  const game    = String(body.game || '').trim();
  const minutes = parseInt(body.duration_minutes, 10);
  const price   = Number(body.price);
  const payment = String(body.payment_method || '').trim();
  const incharge = String(body.incharge_name || '').trim().slice(0, 60);

  if (!PCS.includes(pcId)) {
    return res.status(400).json({ ok: false, error: 'Please select a valid PC.' });
  }
  if (!GAMES.includes(game)) {
    return res.status(400).json({ ok: false, error: 'Please select a valid game.' });
  }
  if (!Number.isInteger(minutes) || minutes < 1 || minutes > 1440) {
    return res.status(400).json({ ok: false, error: 'Duration must be a natural number of minutes (1–1440).' });
  }
  if (!Number.isFinite(price) || price < 0) {
    return res.status(400).json({ ok: false, error: 'Price must be 0 or greater.' });
  }
  if (!PAYMENT_METHODS.includes(payment)) {
    return res.status(400).json({ ok: false, error: 'Please select a valid payment method.' });
  }
  if (!incharge) {
    return res.status(400).json({ ok: false, error: 'Incharge name is required.' });
  }

  /* 2) Generate random PLAY KEY — retry on duplicate (max 5 tries) */
  let lastError = 'Could not generate a unique PLAY KEY. Please try again.';
  for (let attempt = 0; attempt < 5; attempt++) {
    const key = generatePlayKey();

    try {
      const result = await sendPlayKeyToGoogleSheet({
        key,
        pc_id: pcId,
        game,
        duration_minutes: minutes,
        price,
        payment_method: payment,
        incharge_name: incharge
      });

      if (result.success) {
        console.log('✅ PLAY KEY saved:', key, '(' + pcId + ' · ' + game + ')');
        return res.json({ ok: true, key: result.data });
      }

      /* Duplicate key → naya key generate karke retry */
      if (result.duplicate) {
        console.warn('⚠️ Duplicate PLAY KEY rejected, retrying:', key);
        lastError = 'PLAY KEY already exists — generating a new one…';
        continue;
      }

      lastError = result.error || 'Playzone service rejected the request. Please try again.';
 break;
    } catch (err) {
      console.error('❌ Playzone API error:', err.message);
      lastError = 'Playzone service is not responding right now. Please try again in a moment.';
      break;
    }
  }

  return res.status(502).json({ ok: false, error: lastError });
});

/* ---------- RANDOM PLAY KEY — format XXXX-XXXX ---------- */
function generatePlayKey() {
  const pick = () => KEY_CHARS[crypto.randomInt(0, KEY_CHARS.length)];
  const part = () => pick() + pick() + pick() + pick();
  return part() + '-' + part();
}

/* ---------- POST JSON → Google Apps Script Web App ---------- */
async function sendPlayKeyToGoogleSheet(payload) {
  const fetch = global.fetch || require('node-fetch');

  const response = await fetch(PLAYZONE_WEB_APP_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    redirect: 'follow',
    /* 20s timeout — Apps Script hang ho toh request atki na rahe */
    signal: AbortSignal.timeout(20000)
  });

  const text = await response.text();
  let data = null;
  try { data = JSON.parse(text); } catch (e) { /* HTML / empty response */ }

  if (!data) {
    return { success: false, error: 'Unexpected response from the Playzone service.' };
  }

  /* API duplicate-key reject karta hai: { success:false, error:"Duplicate PLAY KEY" } */
  const isDuplicate = data.success === false &&
    /duplicate/i.test(String(data.error || ''));

  return { success: !!data.success, duplicate: isDuplicate, error: data.error, data };
}

module.exports = router;
