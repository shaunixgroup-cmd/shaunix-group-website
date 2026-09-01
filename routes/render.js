/* ============================================================
   render.js — Small helper
   Every page contains {{HEADER}}, {{FOOTER}}, {{CONTACT_SECTION}},
   {{YEAR}} placeholders. This file replaces them with the actual
   header/footer/contact-form content from views/partials/.
   Benefit: menu or phone number only needs to be changed in ONE place.
   ============================================================ */

const fs   = require('fs');
const path = require('path');

const VIEWS_DIR     = path.join(__dirname, '..', 'views');
const PARTIALS_DIR  = path.join(VIEWS_DIR, 'partials');

function readPartial(fileName) {
  return fs.readFileSync(path.join(PARTIALS_DIR, fileName), 'utf8');
}

/* ============================================================
   SINGLE SOURCE OF BUSINESS DATA — from project root /config.js
   All {{TOKENS}} are filled across the entire website from here.
   ============================================================ */
const CFG = require('../config');

const TOKENS = {
  '{{NAME}}':         CFG.name,
  '{{TAGLINE}}':      CFG.tagline,
  '{{PHONE}}':        CFG.phoneDisplay,
  '{{PHONE_DIGITS}}': CFG.phoneDigits,
  '{{EMAIL}}':        CFG.email,
  '{{ADDRESS}}':      CFG.address,
  '{{HOURS}}':        CFG.hours,
  '{{WEBSITE_URL}}':  CFG.websiteUrl,
  '{{MAP_QUERY}}':    CFG.mapQuery,
  '{{WA_NUM}}':       CFG.whatsapp,
  '{{WA_LINK}}':      'https://wa.me/' + CFG.whatsapp +
                      '?text=' + encodeURIComponent('Hi ' + CFG.name + '!')
};

function applySiteData(html) {
  Object.entries(TOKENS).forEach(([token, value]) => {
    const safeVal = String(value == null ? '' : value).replace(/"/g, '"');
    html = html.split(token).join(safeVal);
  });
  return html;
}
/* ============================================================ */

function renderPage(res, viewFile) {
  try {
    let html = fs.readFileSync(path.join(VIEWS_DIR, viewFile), 'utf8');

    html = html
      .split('{{HEADER}}').join(readPartial('header.html'))
      .split('{{FOOTER}}').join(readPartial('footer.html'))
      .split('{{CONTACT_SECTION}}').join(readPartial('contact-section.html'));

    /* Inject config.js data into every page + partial */
    html = applySiteData(html);

    html = html.replace(/{{YEAR}}/g, String(new Date().getFullYear()));

    res.type('text/html').send(html);
  } catch (err) {
    console.error('Render error (' + viewFile + '):', err.message);
    res.status(500).send('Something went wrong — please try again later.');
  }
}

module.exports = { renderPage };