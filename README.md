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
| `/feedback` | ⭐ Customer Feedback | | | |

## 📬 Contact Form Kaise Kaam Karta Hai

1. Har enquiry **`messages.log`** me save hoti hai.
2. **Email bhi chahiye?** `.env` me: Gmail par 2-Step Verification ON →
   https://myaccount.google.com/apppasswords se App Password lo →
   `SMTP_HOST=smtp.gmail.com`, `SMTP_USER=<gmail>`, `SMTP_PASS=<16-char pass>` bhar do. Bas!

## ⭐ Customer Feedback Form (`/feedback`)

Customers jo service use kar chuke hain wo **`/feedback`** par apna experience share karte hain —
star rating (1–5), service, recommend, likhit feedback. Feedback **Google Sheet** me save hota hai,
aur submit ke baad customer ek tap me apna feedback **WhatsApp** par share kar sakta hai.

1. Har feedback pehle **`feedback.log`** me backup hota hai (kuch bhi miss nahi hota).
2. **Google Sheet connection (5 min):** `marketing/feedback-google-sheet-setup.md` kholo →
   Apps Script paste → Deploy (Web app, Access: **Anyone**) → URL copy →
   **`config.js`** me `feedbackWebAppUrl: 'PASTE-YOUR-URL-HERE'` kar do. Bas! ✅
3. Submit ke baad success screen par 2 buttons: **Share on WhatsApp** (customer koi bhi
   chat / group / Status choose kar sakta hai) aur **Send to SHAUNIX GROUP** (seedha aapko) —
   feedback text pre-written format me WhatsApp me khul jata hai.

## 🔧 Common Changes

### ⭐ SAB BUSINESS DATA AB EK JAGAH — `config.js` (project root)

| Data | config.js field |
|---|---|
| 📞 Phone display | `phoneDisplay` |
| 💬 WhatsApp | `whatsapp` (+ `phoneDigits` tel-links ke liye) |
| ✉️ Email | `email` |
| 📍 Address | `address` |
| 🕒 Timing | `hours` |
| 🌐 Website | `websiteUrl` |
| 🗺️ Google Map | `mapQuery` |

`config.js` save karte hi **har page** me phone/email/WhatsApp/address/map automatic
update ho jate hain — partials ya pages kholne ki zarurat nahi. 👍

| Baaki cheezein | Kahan |
|---|---|
| Menu items | `views/partials/header.html` (1 jagah = sab pages) |
| Images | files replace karo same naam se (`public/images/…`) |
| Email bhejne ki setting | `.env` (SMTP_USER / SMTP_PASS) — ye display ke liye nahi hai |

## 🔍 SEO — SAB EK FILE ME (`seo.config.js`)

Har page ka `<title>`, meta description, **keywords**, canonical, OG/Twitter tags,
**LocalBusiness JSON-LD** (page-specific name/url/description) aur
**BreadcrumbList JSON-LD** — sab **`seo.config.js`** (project root) se aate hain.
SEO badalna ho toh wahi EK file edit karo — poori website automatic update. ✅

- **Naya page:** `views/` mein page banao (`<head>` mein `{{SEO}}` likho) → route banao
  → `seo.config.js` ke `PAGES` mein entry add karo. Title + keywords + schema +
  breadcrumb sab automatic ban jate hain.
- **H1 rule:** har page par sirf **ek `<h1>`** — vertical/brand name ke saath.
- **Breadcrumbs:** har inner page par visible `Home › Page` crumbs + hidden
  BreadcrumbList JSON-LD (dono `seo.config.js` ke `crumbs` se).
- **Canonical host:** `https://shaunixgroup.com` — www chahiye toh `seo.config.js`
  me `siteUrl` badlo (aur sitemap.xml + robots.txt bhi match kar lena).

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
