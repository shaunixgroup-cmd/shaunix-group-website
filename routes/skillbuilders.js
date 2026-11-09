// GET  /skill-builders  -> SHAUNIX SKILL BUILDERS (school programs) page
const express = require('express');
const { renderPage } = require('./render');

const router = express.Router();

router.get(['/skill-builders', '/skillbuilders', '/schools'], (req, res) => {
  renderPage(res, 'skill-builders.html');
});

module.exports = router;
