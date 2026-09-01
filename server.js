/* ============================================================
   SHAUNIX GROUP — Website Server
   ------------------------------------------------------------
   To start:    npm start      (or: node server.js)
   Then open:   http://localhost:3000
   ============================================================ */

require('dotenv').config();

const path = require('path');
const express = require('express');

const homeRouter = require('./routes/home');
const aboutRouter = require('./routes/about');
const contactRouter = require('./routes/contact');
const servicesRouter = require('./routes/services');

const app = express();
const PORT = process.env.PORT || 3000;

/* 1) Static files (css / js / images / favicon) from "public" folder */
app.use(express.static(path.join(__dirname, 'public')));

/* 2) Parse contact form data */
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

/* 3) Pages */
app.use('/', homeRouter);     /* / */
app.use('/', servicesRouter); /* /tech /care /digital /print /academy /reclaim */
app.use('/about', aboutRouter);    /* /about */
app.use('/contact', contactRouter);  /* /contact + form submit */

/* 4) Redirect invalid URLs to home */
app.use((req, res) => res.redirect('/'));

app.listen(PORT, () => {
  console.log('');
  console.log('==========================================');
  console.log('  SHAUNIX GROUP website running');
  console.log(`  Open:  http://localhost:${PORT}`);
  console.log('  To close: Ctrl + C');
  console.log('==========================================');
  console.log('');
});