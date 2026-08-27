// GET  /contact                     -> Contact page
// POST /contact/send-message        -> Contact form submit
const express = require('express');
const fs      = require('fs');
const path    = require('path');
const { renderPage } = require('./render');

const router = express.Router();
const CFG    = require('../config');   // config.js ka business data

// ---------- CONTACT PAGE ----------
router.get('/', (req, res) => {
  renderPage(res, 'contact.html');
});

// ---------- FORM SUBMIT ----------
router.post('/send-message', (req, res) => {
  const body = req.body || {};

  const name    = String(body.name || '').trim();
  const phone   = String(body.phone || '').trim();
  const email   = String(body.email || '').trim();
  const service = String(body.service || 'General Enquiry').trim();
  const message = String(body.message || '').trim();

  // Basic validation
  if (!name || !phone || !message) {
    if (req.get('X-Requested-With') === 'fetch') {
      return res.status(400).json({ ok: false, error: 'Naam, phone aur message required hain.' });
    }
    return res.redirect('/contact?error=1');
  }

  // 1) Message hamesha messages.log me save hota hai (backup)
  const entry = {
    time: new Date().toLocaleString('en-IN'),
    name: name.slice(0, 100),
    phone: phone.slice(0, 25),
    email: email.slice(0, 120),
    service,
    message: message.slice(0, 2000)
  };

  try {
    fs.appendFileSync(
      path.join(__dirname, '..', 'messages.log'),
      JSON.stringify(entry) + '\n',
      'utf8'
    );
  } catch (err) {
    console.error('Log write failed:', err.message);
  }

  // 2) Email bhejo (sirf tab jab .env me SMTP details bhari ho)
  sendEnquiryEmail(entry);

  // 3) Reply
  if (req.get('X-Requested-With') === 'fetch') {
    return res.json({ ok: true });
  }
  res.redirect('/contact?sent=1');
});

// ---------- EMAIL (optional) ----------
function sendEnquiryEmail(entry) {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, ADMIN_EMAIL, BUSINESS_EMAIL } = process.env;

  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) return; // email setup nahi hai — skip

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
        subject: `🚀 New Enquiry | ${entry.service} | ${entry.name}`,
        text:
          `Naya enquiry aaya hai!\n\n` +
          `Naam    : ${entry.name}\n` +
          `Phone   : ${entry.phone}\n` +
          `Email   : ${entry.email || '-'}\n` +
          `Service : ${entry.service}\n\n` +
          `Message :\n${entry.message}\n`,
        html:
          `<div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;border:1px solid #e5e9f2;border-radius:12px;overflow:hidden">` +
          `<div style="background:#0b1b3a;color:#fff;padding:18px 24px"><b>SHAUNIX GROUP</b> — New Website Enquiry</div>` +
          `<table style="width:100%;border-collapse:collapse;font-size:14px;color:#334155">` +
          row('Naam', entry.name) + row('Phone', `<a href="tel:${entry.phone}">${entry.phone}</a>`) +
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

