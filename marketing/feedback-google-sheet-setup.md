# ⭐ Customer Feedback Form → Google Sheet + WhatsApp Share

Yeh doc `/feedback` page ko Google Sheet se jodne ke liye hai. Total time: **~5 minute**.

## Kaise kaam karta hai (flow)

```
Customer /feedback page            Website server               Google Sheet
└─ stars + form bharta hai   →   /feedback/submit         →   Apps Script Web App
   Submit dabata hai             (feedback.log me backup      (new row append)
   ✓ Success screen                 + Sheet me bhejta hai)
└─ "Share on WhatsApp" buttons → pre-written feedback text ke saath
   WhatsApp khulta hai — koi bhi chat / group / Status choose kar sakta hai
```

## 📝 Setup Steps (one time)

### Step 1 — Google Sheet banayein
1. [sheets.new](https://sheets.new) kholo → naam do: **`SHAUNIX GROUP — Feedback`**

### Step 2 — Apps Script paste karo
1. Sheet me: **Extensions ▸ Apps Script**
2. Jo code neeche hai, usse purane `function myFunction() {...}` ki jagah paste karo
3. **Ctrl + S** (Save)

```javascript
/** ============================================================
 *  SHAUNIX GROUP — Feedback → Google Sheet (Apps Script)
 *  /feedback form ka POST yahan aata hai (JSON body).
 *  Har submit = sheet ki ek nayi row.
 *  ============================================================ */

var SHEET_NAME = 'Feedback';

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var ss    = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);

    /* Pehli baar: header row banao */
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(['Timestamp', 'Name', 'Phone', 'Email', 'Service Used',
                       'Rating', 'Rating Label', 'Recommend', 'Feedback',
                       'Share Permission', 'Source Page']);
      sheet.getRange(1, 1, 1, 11)
           .setFontWeight('bold').setBackground('#0a1830').setFontColor('#ffffff');
      sheet.setFrozenRows(1);
    }

    sheet.appendRow([
      data.timestamp  || new Date().toLocaleString('en-IN'),
      data.name       || '',
      data.phone      || '',
      data.email      || '',
      data.service    || '',
      data.rating     || '',
      data.ratingLabel || '',
      data.recommend  || '',
      data.message    || '',
      data.permission || 'No',
      data.source     || ''
    ]);

    return ContentService
      .createTextOutput(JSON.stringify({ ok: true }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ ok: false, error: String(err) }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

/* Browser me URL kholke quick health-check */
function doGet() {
  return ContentService
    .createTextOutput(JSON.stringify({ ok: true, service: 'SHAUNIX feedback endpoint live' }))
    .setMimeType(ContentService.MimeType.JSON);
}
```

### Step 3 — Deploy karo
1. Apps Script me upar right: **Deploy ▸ New deployment**
2. ⚙️ gear icon → type: **Web app**
3. Description: `Feedback form endpoint`
4. **Execute as: Me** (aapke Google account se sheet me likhe)
5. **Who has access: Anyone** ← important! (yeh sirf URL jaane wale ko access deta hai)
6. **Deploy** ▸ Google account authorize karo ▸ **Web app URL copy karo**

URL aisa dikhega: `https://script.google.com/macros/s/AKfycb...xxxx.../exec`

### Step 4 — Website se jodo
Project root **`config.js`** kholo:
```js
feedbackWebAppUrl: 'YAHAN-APNA-WEB-APP-URL-PASTE-KARO'
```
Save → server restart (`npm start`). **Ho gaya!** ✅

> `.env` option: `FEEDBACK_WEB_APP_URL=https://script.google.com/macros/s/.../exec`
> (`.env` config.js se zyada priority rakhta hai)

## ✅ Test kaise karein

1. Website kholo → `/feedback` → form bharo → Submit
2. Google Sheet me nayi row dikhni chahiye
3. Server console me: `✅ Feedback saved to Google Sheets`
4. Success screen par **Share on WhatsApp** → WhatsApp khulega pre-written feedback ke saath

## 🔧 Troubleshooting

| Problem | Fix |
|---|---|
| Sheet me row nahi aayi | Deploy settings me *Who has access = **Anyone*** hai? Naya deployment banao |
| Code edit kiya, par effect nahi | **Deploy ▸ Manage deployments ▸ ✏️ Edit ▸ Version: New version ▸ Deploy** |
| Server console: `⚠️ Google Sheets responded unexpectedly` ya `save failed` | Script URL galat hai ya deployment access "Anyone" nahi hai — entry `feedback.log` backup mein safe hai. Sheet save **background** mein hota hai, isliye form turant success dikhata hai |
| Feedback kahin nahi gaya | Panic nahi — `feedback.log` (project root) me backup hamesha hota hai |

## 📊 Sheet Columns (auto-created)

| Timestamp | Name | Phone | Email | Service Used | Rating | Rating Label | Recommend | Feedback | Share Permission | Source Page |
|---|---|---|---|---|---|---|---|---|---|---|

> **Contact form** ka Google Sheet URL `routes/contact.js` me hai (alag) — feedback ka
> `config.js` me (upar wala). Dono alag sheet/script use kar sakte hain.