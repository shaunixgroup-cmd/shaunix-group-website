// GET  /tech, /care, /digital, /print, /academy, /reclaim  -> Service pages
const express   = require('express');
const { renderPage } = require('./render');

const router = express.Router();

const SERVICE_PAGES = {
  '/tech':    'services/tech.html',
  '/care':    'services/care.html',
  '/digital': 'services/digital.html',
  '/print':   'services/print.html',
  '/academy': 'services/academy.html',
  '/reclaim': 'services/reclaim.html'
};

Object.entries(SERVICE_PAGES).forEach(([routeName, viewFile]) => {
  router.get(routeName, (req, res) => {
    renderPage(res, viewFile);
  });
});

module.exports = router;

