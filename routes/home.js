// GET  /        -> Home page
const express   = require('express');
const { renderPage } = require('./render');

const router = express.Router();

router.get(['/', '/home', '/index'], (req, res) => {
  renderPage(res, 'index.html');
});

module.exports = router;

