// GET  /about  -> About page
const express   = require('express');
const { renderPage } = require('./render');

const router = express.Router();

router.get('/', (req, res) => {
  renderPage(res, 'about.html');
});

module.exports = router;

