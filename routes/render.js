/* ============================================================
   render.js — Small helper
   Every page contains {{HEADER}}, {{FOOTER}}, {{CONTACT_SECTION}},
   {{SEO}} and {{YEAR}} placeholders. This file replaces them with
   the actual header/footer/contact-form/SEO content — partials
   from views/partials/.

   SEO SINGLE SOURCE: project root /seo.config.js
   Titles, descriptions, keywords, canonicals, OG/Twitter tags,
   JSON-LD (LocalBusiness + BreadcrumbList) — SAB wahan se aate
   hain. SEO badalna ho toh render.js nahi — seo.config.js edit karo.
   ============================================================ */

const fs = require('fs');
const path = require('path');

const VIEWS_DIR = path.join(__dirname, '..', 'views');
const PARTIALS_DIR = path.join(VIEWS_DIR, 'partials');

function readPartial(fileName) {
  return fs.readFileSync(path.join(PARTIALS_DIR, fileName), 'utf8');
}

/* ============================================================
   SINGLE SOURCE OF BUSINESS DATA — from project root /config.js
   All {{TOKENS}} are filled across the entire website from here.
   ============================================================ */
const CFG = require('../config');

/* ============================================================
   CENTRAL SEO DATA — from project root /seo.config.js
   (brand block + per-page PAGES map)
   ============================================================ */
const SEO = require('../seo.config');

const SITE_URL = SEO.brand.siteUrl;   /* canonical host — seo.config.js */
const OG_IMAGE = SEO.brand.ogImage;   /* social share image */

/* ============================================================
   PER-PAGE SEO DATA — from project root /seo.config.js
   Ek page = ek entry = NO duplicate tags. Naya page banayein toh
   seo.config.js ke PAGES mein entry add karein — title, keywords,
   canonical, OG, JSON-LD schema aur breadcrumbs sab automatic.
   ============================================================ */
const SEO_DATA = SEO.pages;
/* Fallback for a page that has no entry above (keeps SEO unique) */
const DEFAULT_SEO = SEO_DATA['index.html'];

/* ============================================================
   SITE-WIDE DISPLAY TOKENS — from project root /config.js
   (phone, email, address, WhatsApp links — shown on every page)
   ============================================================ */
const TOKENS = {
  '{{NAME}}': CFG.name,
  '{{TAGLINE}}': CFG.tagline,
  '{{PHONE}}': CFG.phoneDisplay,
  '{{PHONE_DIGITS}}': CFG.phoneDigits,
  '{{EMAIL}}': CFG.email,
  '{{ADDRESS}}': CFG.address,
  '{{HOURS}}': CFG.hours,
  '{{WEBSITE_URL}}': CFG.websiteUrl,
  '{{MAP_QUERY}}': CFG.mapQuery,
  '{{WA_NUM}}': CFG.whatsapp,
  '{{WA_LINK}}': 'https://wa.me/' + CFG.whatsapp +
    '?text=' + encodeURIComponent('Hi ' + CFG.name + '!')
};

/* Make a value safe to print inside an HTML attribute (content="...") */
function escapeAttr(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function applySiteData(html, tokens) {
  Object.entries(tokens).forEach(([token, value]) => {
    html = html.split(token).join(escapeAttr(value));
  });
  return html;
}
/* ============================================================ */

/* ---------- STRUCTURED DATA (JSON-LD) — from seo.config.js ---------- */

/* JSON for <script> tags — '<' escaped so '</script>' can never break out */
function jsonForScript(obj) {
  return JSON.stringify(obj, null, 2).replace(/</g, '\\u003c');
}

/* Page-specific LocalBusiness schema — har page par ek */
function buildLocalBusinessLd(seo, pageUrl) {
  const b = SEO.brand;
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'LocalBusiness',
    '@id': SITE_URL + '/#business',
    name: seo.schemaName || b.name,
    description: seo.description,
    image: b.ogImage,
    url: pageUrl,
    telephone: b.telephone,
    email: b.email,
    address: b.address,
    openingHours: b.openingHours,
    areaServed: b.areaServed
  };
  return '<script type="application/ld+json">\n' + jsonForScript(schema) + '\n</script>';
}

/* BreadcrumbList schema — page ke crumbs se auto-generated
   (homepage par crumbs = [] hota hai, isliye skip) */
function buildBreadcrumbLd(crumbs) {
  if (!crumbs || crumbs.length < 2) return '';
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: crumbs.map(function(c, i) {
      return { '@type': 'ListItem', position: i + 1, name: c.name, item: SITE_URL + (c.url || '/') };
    })
  };
  return '<script type="application/ld+json">\n' + jsonForScript(schema) + '\n</script>';
}

function renderPage(res, viewFile) {
  try {
    let html = fs.readFileSync(path.join(VIEWS_DIR, viewFile), 'utf8');

    html = html
      .split('{{HEADER}}').join(readPartial('header.html'))
      .split('{{FOOTER}}').join(readPartial('footer.html'))
      .split('{{CONTACT_SECTION}}').join(readPartial('contact-section.html'))
      .split('{{SEO}}').join(readPartial('seo.html'));

    /* Pick this page's SEO data (fallback: homepage data) */
    const seo = Object.assign({}, DEFAULT_SEO, SEO_DATA[viewFile]);
    const canonicalPath = seo.canonical || '/';
    const pageUrl = SITE_URL + canonicalPath;

    /* Breadcrumbs — page apne crumbs define kar sakta hai (seo.config.js
       ke apne entry mein), warna automatic: Home › schemaName.
       NOTE: apne entry check karte hain, merged object nahi — warna
       homepage ka crumbs:[] fallback sab pages par copy ho jata! */
    const ownSeo = SEO_DATA[viewFile] || {};
    const crumbs = ('crumbs' in ownSeo) ? ownSeo.crumbs
      : [{ name: 'Home', url: '/' }, { name: seo.schemaName || seo.title, url: canonicalPath }];

    /* Per-page SEO tokens — filled into views/partials/seo.html */
    const seoTokens = {
      '{{TITLE}}': seo.title,
      '{{DESCRIPTION}}': seo.description,
      '{{KEYWORDS}}': seo.keywords || SEO.brand.defaultKeywords,
      '{{ROBOTS}}': SEO.brand.robots,
      '{{CANONICAL}}': pageUrl,
      '{{OG_TITLE}}': seo.ogTitle || seo.title,
      '{{OG_DESCRIPTION}}': seo.ogDescription || seo.description,
      '{{OG_URL}}': pageUrl,
      '{{OG_IMAGE}}': OG_IMAGE,
      '{{TWITTER_TITLE}}': seo.twitterTitle || seo.title,
      '{{TWITTER_DESCRIPTION}}': seo.twitterDescription || seo.description,
      '{{AUTHOR}}': SEO.brand.author,
      '{{GEO_REGION}}': SEO.brand.geoRegion,
      '{{GEO_PLACENAME}}': SEO.brand.geoPlacename
    };

    /* Inject config.js data + per-page SEO into every page + partial */
    html = applySiteData(html, Object.assign({}, TOKENS, seoTokens));

    /* JSON-LD blocks RAW inject (ye escape NAHI hote — valid JSON
       rehta hai; upar wale tokens pehle hi replace ho chuke hain) */
    html = html
      .split('{{JSON_LD}}').join(buildLocalBusinessLd(seo, pageUrl))
      .split('{{BREADCRUMB_LD}}').join(buildBreadcrumbLd(crumbs));

    html = html.replace(/{{YEAR}}/g, String(new Date().getFullYear()));

    res.type('text/html').send(html);
  } catch (err) {
    console.error('Render error (' + viewFile + '):', err.message);
    res.status(500).send('Something went wrong — please try again later.');
  }
}

module.exports = { renderPage };