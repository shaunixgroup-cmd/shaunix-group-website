/* ============================================================
   playstation.js — SHAUNIX PLAYSTATION
   Sirf key generate karta hai (PC ka koi chakkar nahi)
   ============================================================ */

const express = require('express');
const crypto  = require('crypto');
const { renderPage } = require('./render');
const router = express.Router();
const CFG = require('../config');

const PLAYZONE_WEB_APP_URL = process.env.PLAYZONE_WEB_APP_URL || CFG.playzoneWebAppUrl || '';

const GAMES = ['Tekken 3', 'Street Fighter Alpha 3', 'Mortal Kombat 4', 'Contra', 'Super Mario Bros.', 'Super Bomberman 5', 'Megaman X4'];
const PAYMENT_METHODS = ['Cash', 'UPI'];
const KEY_CHARS = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/* ---- Page ---- */
router.get('/playstation', (req, res) => {
  renderPage(res, 'playstation.html');
});

/* ---- API ---- */
router.post('/playstation/api', async (req, res) => {
  if (!PLAYZONE_WEB_APP_URL) {
    return res.status(503).json({ ok: false, error: 'Playstation not configured.' });
  }

  const body = req.body || {};
  const game = String(body.game || '').trim();
  const minutes = parseInt(body.duration_minutes, 10);
  const price = Number(body.price);
  const payment = String(body.payment_method || '').trim();
  const incharge = String(body.incharge_name || '').trim().slice(0, 60);

  if (!GAMES.includes(game)) return res.status(400).json({ ok: false, error: 'Invalid game.' });
  if (!Number.isInteger(minutes) || minutes < 1 || minutes > 1440) return res.status(400).json({ ok: false, error: 'Invalid duration.' });
  if (!Number.isFinite(price) || price < 0) return res.status(400).json({ ok: false, error: 'Invalid price.' });
  if (!PAYMENT_METHODS.includes(payment)) return res.status(400).json({ ok: false, error: 'Invalid payment.' });
  if (!incharge) return res.status(400).json({ ok: false, error: 'Incharge name required.' });

  let lastError = 'Could not generate key.';
  for (let i = 0; i < 5; i++) {
    const key = generatePlayKey();
    try {
      const result = await sendToSheet({
        key, pc_id: 'PC-01', game,
        duration_minutes: minutes,
        price, payment_method: payment,
        incharge_name: incharge
      });
      if (result.success) return res.json({ ok: true, key: result.data });
      if (result.duplicate) { lastError = 'Duplicate key, retrying…'; continue; }
      lastError = result.error || 'Rejected.';
      break;
    } catch (err) {
      lastError = 'Service not responding.';
      break;
    }
  }
  return res.status(502).json({ ok: false, error: lastError });
});

function generatePlayKey() {
  const pick = () => KEY_CHARS[crypto.randomInt(0, KEY_CHARS.length)];
  const part = () => pick() + pick() + pick() + pick();
  return part() + '-' + part();
}

async function sendToSheet(payload) {
  const fetch = global.fetch || require('node-fetch');
  const response = await fetch(PLAYZONE_WEB_APP_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    redirect: 'follow',
    signal: AbortSignal.timeout(20000)
  });
  const text = await response.text();
  let data = null;
  try { data = JSON.parse(text); } catch (e) {}
  if (!data) return { success: false, error: 'Bad response.' };
  const isDuplicate = data.success === false && /duplicate/i.test(String(data.error || ''));
  return { success: !!data.success, duplicate: isDuplicate, error: data.error, data };
}

module.exports = router;