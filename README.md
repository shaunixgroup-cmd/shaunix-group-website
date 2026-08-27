# 🏢 SHAUNIX GROUP — Official Website

**Technology. Solutions. Growth.**
Technology • Digital • Services • Education • Sustainability

Ek simple Node.js (Express) website — 9 pages, contact form (email optional), WhatsApp button,
fully responsive design. Koi heavy framework nahi — `node server.js` bas chalao aur site live. 🚀

## 📁 Folder Structure

```
shaunix-group/
├── package.json          ← dependencies & scripts
├── server.js             ← MAIN FILE — node server.js
├── .env                  ← settings (port / email)
├── public/
│   ├── css/style.css     ← main design
│   ├── css/responsive.css← mobile/tablet styles
│   ├── js/main.js        ← menu, animations, form logic
│   ├── favicon.svg       ← tab icon
│   └── images/
│       ├── logo/shaunix-group-logo.png   ← AAPKA LOGO YAHAN
│       ├── hero/hero.jpg                 ← homepage hero photo
│       └── services/                     ← tech.jpg care.jpg digital.jpg
│                                             print.jpg academy.jpg reclaim.jpg
├── views/                ← HTML pages (+ partials: header/footer/contact-form)
├── routes/               ← URL routing + render helper
└── marketing/            ← Gmail signature / WhatsApp kit / Brochure
```

> Agar koi image missing hai to site khud sundar placeholder dikhati hai — crash nahi hoti.
> Images daalte hi automatic real photo show hogi. ✨

## ▶️ Chalane Ka Tarika

```bash
npm install      # sirf pehli baar
npm start        # ya: node server.js
```

Browser me kholo → **http://localhost:3000**

| Route | Page | | Route | Page |
|-------|------|-|-------|------|
| `/` | Home | | `/print` | SHAUNIX PRINT |
| `/tech` | SHAUNIX TECH | | `/academy` | SHAUNIX ACADEMY |
| `/care` | SHAUNIX CARE | | `/reclaim` | SHAUNIX RECLAIM |
| `/digital` | SHAUNIX DIGITAL | | `/about` `(`/contact`)` | About / Contact |

## 📬 Contact Form Kaise Kaam Karta Hai

1. Har enquiry **`messages.log`** me save hoti hai.
2. **Email bhi chahiye?** `.env` me: Gmail par 2-Step Verification ON →
   https://myaccount.google.com/apppasswords se App Password lo →
   `SMTP_HOST=smtp.gmail.com`, `SMTP_USER=<gmail>`, `SMTP_PASS=<16-char pass>` bhar do. Bas!

## 🔧 Common Changes

| Kya badalna hai | Kahan |
|---|---|
| Phone / WhatsApp number | partials (header/footer/contact-section) + `main.js` me `919000000000` replace |
| Email | Partials me `hello@shaunixgroup.com` replace |
| Address / Map | `views/contact.html` |
| Menu items | `views/partials/header.html` (1 jagah = sab pages) |

## 🐙 GitHub Upload

```bash
git init
git add .
git commit -m "SHAUNIX GROUP website v1"
git branch -M main
git remote add origin https://github.com/<username>/shaunix-group.git
git push -u origin main
```
`.env` & `messages.log` already ignored hain — secrets upload nahi honge. ✅

## ☁️ Hosting (jab online karna ho)

- **Render/Railway** (free): repo connect karo → Start command `npm start`
- **VPS**: folder copy → `npm install` → `pm2 start server.js --name shaunix`
- Domain baad me A-record se point kara sakte ho.

## ✅ Missions Checklist

- [x] Website Design → ye project
- [x] Gmail Signature → `marketing/gmail-signature.html`
- [x] WhatsApp Kit + Quick Replies → `marketing/whatsapp-business-kit.md`
- [x] Brochure Content → `marketing/brochure-content.md`
- [x] GitHub Setup → upar wale commands

— Built with ❤️ for SHAUNIX GROUP
