/* ============================================================
   contact.js — Contact page & form handling
   GET  /contact              -> Contact page
   POST /contact/send-message -> Contact form submit
   ============================================================ */

   // Agar Node.js v18 se purana hai toh
const fetch = require('node-fetch');
const express = require('express');
const fs      = require('fs');
const path    = require('path');
const { renderPage } = require('./render');

// ✅ Google Apps Script URL (aapka deployed URL)
const GAS_WEB_APP_URL = 'https://script.google.com/macros/s/AKfycbzNRpBXyec_CsNnCu8ssH-alXlQq7H5hmoDtX3a707bf_CHUpwAWW3DzGQ4U_ukkqe1/exec';

const router = express.Router();
const CFG    = require('../config');   /* Business data from config.js */

/* ---------- CONTACT PAGE ---------- */
router.get('/', (req, res) => {
  renderPage(res, 'contact.html');
});

/* ---------- FORM SUBMIT ---------- */
router.post('/send-message', async (req, res) => {  // ← async add karein
  const body = req.body || {};

  const name    = String(body.name || '').trim();
  const phone   = String(body.phone || '').trim();
  const email   = String(body.email || '').trim();
  const service = String(body.service || 'General Enquiry').trim();
  const message = String(body.message || '').trim();

  /* Basic validation */
  if (!name || !phone || !message) {
    if (req.get('X-Requested-With') === 'fetch') {
      return res.status(400).json({ ok: false, error: 'Name, phone and message are required.' });
    }
    return res.redirect('/contact?error=1');
  }

  /* 1) Always save message to messages.log (backup) */
  const entry = {
    time: new Date().toLocaleString('en-IN'),
    name: name.slice(0, 100),
    phone: phone.slice(0, 25),
    email: email.slice(0, 120),
    service,
    message: message.slice(0, 2000)
  };

  // ✅ Save to messages.log (backup)
  try {
    fs.appendFileSync(
      path.join(__dirname, '..', 'messages.log'),
      JSON.stringify(entry) + '\n',
      'utf8'
    );
    console.log('✅ Saved to messages.log');
  } catch (err) {
    console.error('❌ Log write failed:', err.message);
  }

  // ✅ Save to Google Sheets — BACKGROUND mein (await NAHI karte!)
  // Apps Script kabhi-kabhi slow/hot hota hai — agar yahan await karein
  // toh form ka button "Sending..." par atak jata hai. Isliye user ko
  // reply TURANT bhejte hain, sheet save background mein hota hai.
  // (Backup: entry upar messages.log mein already save ho chuki hai)
  sendToGoogleSheet(entry)
    .then(function(ok) {
      if (ok) console.log('✅ Saved to Google Sheets');
      else console.error('⚠️ Google Sheets ne unexpected response diya — entry messages.log backup mein safe hai');
    })
    .catch(function(err) {
      console.error('❌ Google Sheets save failed:', err.message);
      /* Error ignore karein - app crash nahi honi chahiye */
    });

  /* 2) Send email (only when SMTP details are configured in .env) */
  sendEnquiryEmail(entry);

  /* 3) Reply */
  if (req.get('X-Requested-With') === 'fetch') {
    return res.json({ ok: true });
  }
  res.redirect('/contact?sent=1');
});

/* ---------- GOOGLE SHEETS FUNCTION ---------- */
async function sendToGoogleSheet(entry) {
  try {
    // Check if fetch is available (Node.js 18+)
    const fetch = global.fetch || require('node-fetch');
    
    const response = await fetch(GAS_WEB_APP_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      redirect: 'follow',
      /* 15s timeout — Apps Script hang ho toh server process kabhi stuck na ho */
      signal: AbortSignal.timeout(15000),
      body: JSON.stringify({
        name: entry.name,
        phone: entry.phone,
        email: entry.email || '',
        service: entry.service,
        message: entry.message,
        timestamp: entry.time
      })
    });
    
    return response.ok;
  } catch (error) {
    console.error('❌ Google Sheets fetch error:', error.message);
    throw error;
  }
}

/* ---------- EMAIL (optional) ---------- */
function sendEnquiryEmail(entry) {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, ADMIN_EMAIL, BUSINESS_EMAIL } = process.env;

  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) return; /* Email not configured — skip */

  try {
    const nodemailer   = require('nodemailer');
    const transporter = nodemailer.createTransport({
      host: SMTP_HOST,
      port: Number(SMTP_PORT) || 587,
      secure: Number(SMTP_PORT) === 465,
      auth: { user: SMTP_USER, pass: SMTP_PASS }
    });

    const to = ADMIN_EMAIL || CFG.email || BUSINESS_EMAIL || SMTP_USER;

    transporter
      .sendMail({
        from: `SHAUNIX GROUP Website <${SMTP_USER}>`,
        to,
        replyTo: entry.email || undefined,
        subject: `New Enquiry | ${entry.service} | ${entry.name}`,
        text:
          `New enquiry received!\n\n` +
          `Name    : ${entry.name}\n` +
          `Phone   : ${entry.phone}\n` +
          `Email   : ${entry.email || '-'}\n` +
          `Service : ${entry.service}\n\n` +
          `Message :\n${entry.message}\n`,
        html:
          `<div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;border:1px solid #e5e9f2;border-radius:12px;overflow:hidden">` +
          `<div style="background:#0b1b3a;color:#fff;padding:18px 24px"><b>SHAUNIX GROUP</b> — New Website Enquiry</div>` +
          `<table style="width:100%;border-collapse:collapse;font-size:14px;color:#334155">` +
          row('Name', entry.name) + row('Phone', `<a href="tel:${entry.phone}">${entry.phone}</a>`) +
          row('Email', entry.email || '-') + row('Service', entry.service) +
          `</table>` +
          `<div style="padding:16px 24px 24px;font-size:14px;color:#334155">` +
          `<b style="color:#0b1b3a">Message:</b><br>${String(entry.message).replace(/\n/g, '<br>')}</div></div>`
      })
      .catch((err) => console.error('Email failed:', err.message));
  } catch (err) {
    console.error('Email setup error:', err.message);
  }
}

function row(label, value) {
  return (
    `<tr><td style="padding:10px 24px;border-bottom:1px solid #f1f5f9;width:90px"><b>${label}</b></td>` +
    `<td style="padding:10px 24px;border-bottom:1px solid #f1f5f9">${value}</td></tr>`
  );
}

module.exports = router;