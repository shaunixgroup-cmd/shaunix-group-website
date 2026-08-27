// ============================================================
//  render.js — Chhota helper
//  Har page me jo {{HEADER}}, {{FOOTER}}, {{CONTACT_SECTION}},
//  {{YEAR}} likha hota hai, uski jagah asli header/footer/
//  contact-form daal deta hai (views/partials/ se).
//  Fayda: menu ya phone number sirf EK jagah badalna hota hai.
// ============================================================

const fs   = require('fs');
const path = require('path');

const VIEWS_DIR     = path.join(__dirname, '..', 'views');
const PARTIALS_DIR  = path.join(VIEWS_DIR, 'partials');

function readPartial(fileName) {
  return fs.readFileSync(path.join(PARTIALS_DIR, fileName), 'utf8');
}

function renderPage(res, viewFile) {
  try {
    let html = fs.readFileSync(path.join(VIEWS_DIR, viewFile), 'utf8');

    html = html
      .split('{{HEADER}}').join(readPartial('header.html'))
      .split('{{FOOTER}}').join(readPartial('footer.html'))
      .split('{{CONTACT_SECTION}}').join(readPartial('contact-section.html'))
      .split('{{YEAR}}').join(String(new Date().getFullYear()));

    res.type('text/html').send(html);
  } catch (err) {
    console.error('Render error (' + viewFile + '):', err.message);
    res.status(500).send('Kuch galat ho gaya — thodi der baad try karein.');
  }
}

module.exports = { renderPage };
