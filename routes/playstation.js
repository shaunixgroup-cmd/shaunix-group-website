const express = require('express');
const crypto  = require('crypto');
const { renderPage } = require('./render');
const router = express.Router();
const CFG = require('../config');

const PLAYZONE_WEB_APP_URL = process.env.PLAYZONE_WEB_APP_URL || CFG.playzoneWebAppUrl || '';

const GAMES = ['Tekken 3', 'Street Fighter Alpha 3', 'Mortal Kombat 4', 'Contra', 'Super Mario Bros.', 'Super Bomberman 5', 'Megaman X4'];
const PAYMENT_METHODS = ['Cash', 'UPI', 'Voucher'];
const KEY_CHARS = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const MAX_PLAYERS = 10;

router.get('/playstation', (req, res) => {
  renderPage(res, 'playstation.html');
});

router.post('/playstation/api', async (req, res) => {
  if (!PLAYZONE_WEB_APP_URL) {
    return res.status(503).json({ ok: false, error: 'Playstation not configured.' });
  }

  const body = req.body || {};
  const game           = String(body.game || '').trim();
  const numPlayers     = parseInt(body.num_players, 10);
  const minutes        = parseInt(body.duration_minutes, 10);
  const price          = Number(body.price);
  const payment        = String(body.payment_method || '').trim();
  const clientName     = String(body.client_name || '').trim().slice(0, 60);
  const incharge       = String(body.incharge_name || '').trim().slice(0, 60);
  const clientWhatsapp = String(body.client_whatsapp || '').trim().slice(0, 15);
  const clientEmail    = String(body.client_email    || '').trim().slice(0, 80);

  if (!GAMES.includes(game))
    return res.status(400).json({ ok: false, error: 'Invalid game.' });
  if (!Number.isInteger(numPlayers) || numPlayers < 1 || numPlayers > MAX_PLAYERS)
    return res.status(400).json({ ok: false, error: 'Invalid number of players.' });
  if (!Number.isInteger(minutes) || minutes < 1 || minutes > 1440)
    return res.status(400).json({ ok: false, error: 'Invalid duration.' });
  if (!Number.isFinite(price) || price < 0)
    return res.status(400).json({ ok: false, error: 'Invalid price.' });
  if (!PAYMENT_METHODS.includes(payment))
    return res.status(400).json({ ok: false, error: 'Invalid payment.' });
  if (!clientName)
    return res.status(400).json({ ok: false, error: 'Client name required.' });
  if (!incharge)
    return res.status(400).json({ ok: false, error: 'Incharge name required.' });

  if (clientWhatsapp && !/^\d{10,15}$/.test(clientWhatsapp.replace(/[\s\-()+]/g, '')))
    return res.status(400).json({ ok: false, error: 'Invalid WhatsApp number.' });
  if (clientEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(clientEmail))
    return res.status(400).json({ ok: false, error: 'Invalid email.' });

  let lastError = 'Could not generate key.';
  for (let i = 0; i < 5; i++) {
    const key = generatePlayKey();
    try {
      const result = await sendToSheet({
        key,
        pc_id: 'PC-01',
        game,
        num_players: numPlayers,
        duration_minutes: minutes,
        price,
        payment_method: payment,
        client_name: clientName,
        incharge_name: incharge,
        client_whatsapp: clientWhatsapp,
        client_email: clientEmail
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