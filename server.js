// ============================================================
//  SHAUNIX GROUP  —  Website Server
//  ------------------------------------------------------------
//  Start karne ke liye:   npm start      (ya: node server.js)
//  Phir browser me kholo: http://localhost:3000
// ============================================================

require('dotenv').config();

const path = require('path');
const express = require('express');

const homeRouter = require('./routes/home');
const aboutRouter = require('./routes/about');
const contactRouter = require('./routes/contact');
const servicesRouter = require('./routes/services');

const app = express();
const PORT = process.env.PORT || 3000;

// 1) Static files (css / js / images / favicon) "public" folder se
app.use(express.static(path.join(__dirname, 'public')));

// 2) Contact form ka data padhne ke liye
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// 3) Pages
app.use('/', homeRouter);     // /
app.use('/', servicesRouter); // /tech /care /digital /print /academy /reclaim
app.use('/about', aboutRouter);    // /about
app.use('/contact', contactRouter);  // /contact + form submit

// 4) Galat URL aaye to home par bhej do
app.use((req, res) => res.redirect('/'));

app.listen(PORT, () => {
  console.log('');
  console.log('==========================================');
  console.log('  SHAUNIX GROUP website running 🚀');
  console.log(`  Open karlo ➜  http://localhost:${PORT}`);
  console.log('  To close: Ctrl + C');
  console.log('==========================================');
  console.log('');
});

