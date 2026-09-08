/* ============================================================
   feedback.js — Customer Feedback page & form handling
   GET  /feedback        -> Feedback page
   POST /feedback/submit -> Feedback form submit (saves to Google Sheet)
   ------------------------------------------------------------
   GOOGLE SHEET CONNECTION (5 minute setup):
   1) Google Sheet kholo ▸ Extensions ▸ Apps Script
   2) Script paste karo from: marketing/feedback-google-sheet-setup.md
   3) Deploy ▸ New deployment ▸ Web app (Access: "Anyone") ▸ URL copy
   4) config.js me feedbackWebAppUrl: 'PASTE-YOUR-URL-HERE' kar do
      (ya .env me FEEDBACK_WEB_APP_URL=... — .env zyada priority rakhta hai)
   Jab tak URL set nahi hai, feedback feedback.log me safe rehta hai.
   ============================================================ */

const express = require('express');
const fs      = require('fs');
const path    = require('path');
const { renderPage } = require('./render');

const router = express.Router();
const CFG    = require('../config');   /* Business data from config.js */

/* Google Apps Script Web App URL — .env override > config.js (single source) */
const FEEDBACK_WEB_APP_URL = process.env.FEEDBACK_WEB_APP_URL || CFG.feedbackWebAppUrl || '';

const RATING_LABELS = { 1: 'Poor (1/5)', 2: 'Fair (2/5)', 3: 'Good (3/5)', 4: 'Very Good (4/5)', 5: 'Excellent (5/5)' };

/* ---------- FEEDBACK PAGE ---------- */
router.get('/', (req, res) => {
  renderPage(res, 'feedback.html');
});

/* ---------- FORM SUBMIT ---------- */
router.post('/submit', async (req, res) => {
  const body = req.body || {};

  const name       = String(body.name || '').trim();
  const phone      = String(body.phone || '').trim();
  const email      = String(body.email || '').trim();
  const service    = String(body.service || '').trim();
  const recommend  = String(body.recommend || '').trim();
  const message    = String(body.message || '').trim();
  const permission = body.permission === 'Yes' ? 'Yes' : 'No';
  const source     = String(body.source || '').slice(0, 300);
  const rating     = parseInt(String(body.rating || body.ratingSelect || ''), 10);

  /* Basic validation */
  if (!name || !phone || !service || !message || !RATING_LABELS[rating]) {
    if (req.get('X-Requested-With') === 'fetch') {
      return res.status(400).json({ ok: false, error: 'Name, phone, service, star rating and feedback are required.' });
    }
    return res.redirect('/feedback?error=1');
  }

  /* 1) Always save feedback to feedback.log (backup) */
  const entry = {
    time: new Date().toLocaleString('en-IN'),
    name: name.slice(0, 100),
    phone: phone.slice(0, 25),
    email: email.slice(0, 120),
    service: service.slice(0, 120),
    rating: rating,
    ratingLabel: RATING_LABELS[rating],
    recommend: (recommend || 'Not said').slice(0, 40),
    message: message.slice(0, 2000),
    permission,
    source: source || 'shaunixgroup.com/feedback'
  };

  try {
    fs.appendFileSync(
      path.join(__dirname, '..', 'feedback.log'),
      JSON.stringify(entry) + '\n',
      'utf8'
    );
    console.log('✅ Feedback saved to feedback.log');
  } catch (err) {
    console.error('❌ Feedback log write failed:', err.message);
  }

  /* 2) Save to Google Sheets (via Apps Script Web App)
     BACKGROUND mein bhejte hain — await nahi karte. Apps Script slow
     ho toh bhi success screen TURANT dikhega. Backup: feedback.log
     mein entry already save ho chuki hai — kuch lost nahi hota. */
  if (FEEDBACK_WEB_APP_URL) {
    sendFeedbackToGoogleSheet(entry)
      .then(function(ok) {
        if (ok) console.log('✅ Feedback saved to Google Sheets');
        else console.error('⚠️ Google Sheets responded unexpectedly — feedback is safe in feedback.log');
      })
      .catch(function(err) {
        console.error('❌ Google Sheets save failed:', err.message);
        /* Error ignore karein - app crash nahi honi chahiye */
      });
  } else {
    console.warn('⚠️ Google Sheet link not set yet — paste it in config.js (feedbackWebAppUrl). Feedback saved locally only.');
  }

  /* 3) Reply — TURANT (Google Sheet background mein save hota hai) */
  if (req.get('X-Requested-With') === 'fetch') {
    return res.json({ ok: true, sheet: 'queued' });
  }
  res.redirect('/feedback?sent=1');
});

/* ---------- GOOGLE SHEETS FUNCTION ---------- */
async function sendFeedbackToGoogleSheet(entry) {
  const fetch = global.fetch || require('node-fetch');

  const response = await fetch(FEEDBACK_WEB_APP_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name: entry.name,
      phone: entry.phone,
      email: entry.email || '',
      service: entry.service,
      rating: entry.rating,
      ratingLabel: entry.ratingLabel,
      recommend: entry.recommend,
      message: entry.message,
      permission: entry.permission,
      source: entry.source,
      timestamp: entry.time
    }),
    redirect: 'follow',
    /* 15s timeout — Apps Script hang ho toh background call atki na rahe */
    signal: AbortSignal.timeout(15000)
  });

  return response.ok;
}

module.exports = router;