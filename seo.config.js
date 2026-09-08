/* ============================================================
   SHAUNIX GROUP — CENTRAL SEO CONFIG (seo.config.js)
   ------------------------------------------------------------
   SAB SEO EK JAGAH! Titles, meta descriptions, keywords,
   canonical URLs, Open Graph, JSON-LD schema aur breadcrumbs —
   yahan edit karo, poori website par automatic update.

   Naya page add karna ho toh:
     1. views/ mein page banao (<head> mein {{SEO}} likho)
     2. routes/ mein route banao — renderPage() use karo
     3. Neeche PAGES mein iski entry add karo. Bas!

   routes/render.js har page ke <head> mein inject karta hai:
     title • description • keywords • canonical • OG • Twitter •
     LocalBusiness JSON-LD • BreadcrumbList JSON-LD
   ============================================================ */

const CFG = require('./config');   /* business data — phone/email single source */

const BRAND = {
  name: CFG.name,                                  /* 'SHAUNIX GROUP' */

  /* Canonical site host — www lagana/hatana ho toh SIRF yahan badlo.
     (sitemap.xml + robots.txt bhi isi host se match karte hain) */
  siteUrl: 'https://shaunixgroup.com',

  /* Social share image (OG / Twitter card) */
  ogImage: 'https://shaunixgroup.com/images/logo/shaunix-group-logo.png',

  /* Structured-data contact info (JSON-LD) — config.js se derived */
  telephone: '+' + CFG.whatsapp,                   /* +919821186889 */
  email: CFG.email,
  openingHours: 'Mo-Sa 10:00-19:00',
  areaServed: 'Delhi, India',

  /* Structured postal address (Google local SEO) */
  address: {
    '@type': 'PostalAddress',
    streetAddress: 'A-20, A Block, Gali No. 1/A, Om Nagar, Shakti Vihar, Badarpur',
    addressLocality: 'Delhi',
    addressRegion: 'Delhi',
    postalCode: '110044',
    addressCountry: 'IN'
  },

  /* Site-wide meta defaults */
  author: CFG.name,
  geoRegion: 'IN-DL',
  geoPlacename: 'New Delhi',
  robots: 'index, follow',

  /* Fallback keywords — jab kisi page ki apni keywords na hon */
  defaultKeywords: 'SHAUNIX GROUP, IT solutions Delhi, laptop repair Delhi, website development Delhi, printing services Delhi, tech courses Delhi, e-waste management Delhi, computer accessories Delhi, digital marketing Delhi'
};

/* ============================================================
   PER-PAGE SEO — ek page = ek entry = NO duplicate tags!
   schemaName → JSON-LD LocalBusiness "name" (vertical/brand name)
   crumbs     → BreadcrumbList + visible breadcrumb data
                (omit = auto "Home › schemaName"; [] = koi nahi, homepage)
   Optional overrides: ogTitle, ogDescription, twitterTitle,
   twitterDescription (default = title / description)
   ============================================================ */
const PAGES = {
  'index.html': {
    title: 'SHAUNIX GROUP — IT Solutions, Repair, Printing, Digital, Academy & E-Waste in Delhi',
    description: 'Complete IT solutions under one roof — laptops, desktops, accessories, repair, printing, website development, digital marketing, tech courses & e-waste management in Delhi. Call +91 98211 86889.',
    keywords: 'SHAUNIX GROUP, IT solutions Delhi, laptop repair Delhi, website development Delhi, printing services Delhi, tech courses Delhi, e-waste management Delhi, computer accessories Delhi, digital marketing Delhi',
    canonical: '/',
    schemaName: 'SHAUNIX GROUP',
    crumbs: []
  },
  'services/tech.html': {
    title: 'Buy Laptops, Desktops & Accessories in Delhi — New, Refurbished & Old | SHAUNIX TECH',
    description: 'Best prices on HP, Dell, Lenovo, Acer laptops, desktops, SSDs, RAM, chargers, batteries & all computer accessories in Delhi. New, refurbished & old products available. GST invoice.',
    keywords: 'laptops Delhi, desktops Delhi, computer accessories Delhi, refurbished laptops Delhi, old computers Delhi, SSD Delhi, RAM upgrade Delhi, laptop charger Delhi, HP laptop Delhi, Dell desktop Delhi',
    canonical: '/tech',
    schemaName: 'SHAUNIX TECH'
  },
  'services/care.html': {
    title: 'Laptop, Desktop & Printer Repair Service in Delhi — Expert Repairs | SHAUNIX CARE',
    description: 'Professional laptop, desktop & printer repair services in Badarpur, Delhi. Screen replacement, battery, keyboard, motherboard repair, software installation & AMC support. Doorstep service available.',
    keywords: 'laptop repair Delhi, desktop repair Delhi, printer repair Delhi, laptop screen replacement Delhi, laptop battery replacement Delhi, computer repair near me, AMC Delhi, doorstep repair Delhi',
    canonical: '/care',
    schemaName: 'SHAUNIX CARE'
  },
  'services/digital.html': {
    title: 'Website Development, App Development & Digital Marketing in Delhi | SHAUNIX DIGITAL',
    description: 'Professional website development, mobile apps, SEO, digital marketing, branding & YouTube promotion services in Delhi. Custom solutions for businesses, startups & individuals.',
    keywords: 'website development Delhi, app development Delhi, SEO services Delhi, digital marketing Delhi, YouTube views Delhi, branding Delhi, e-commerce website Delhi, software development Delhi',
    canonical: '/digital',
    schemaName: 'SHAUNIX DIGITAL'
  },
  'services/print.html': {
    title: 'Printing Services in Delhi — Business Cards, Brochures, Flyers & Branding | SHAUNIX PRINT',
    description: 'Digital & offset printing services in Delhi. Business cards, brochures, flyers, letterheads, wedding cards, packaging, labels, vinyl, signage & more. Premium finishes available.',
    keywords: 'printing services Delhi, business cards Delhi, brochure printing Delhi, flyer printing Delhi, offset printing Delhi, digital printing Delhi, wedding cards Delhi, packaging printing Delhi, vinyl printing Delhi',
    canonical: '/print',
    schemaName: 'SHAUNIX PRINT'
  },
  'services/academy.html': {
    title: 'Tech Courses in Delhi — MERN, Python, Data Science & More | SHAUNIX ACADEMY',
    description: 'Practical tech courses in Delhi — MERN Stack, Python Programming, Data Science, Web Development & more. Industry-relevant training with hands-on projects & placement support.',
    keywords: 'MERN course Delhi, Python training Delhi, data science course Delhi, web development course Delhi, programming classes Delhi, tech courses Delhi, coding bootcamp Delhi, IT training Delhi',
    canonical: '/academy',
    schemaName: 'SHAUNIX ACADEMY'
  },
  'services/reclaim.html': {
    title: 'IT Asset Recovery & E-Waste Collection in Delhi — Responsible Recycling | SHAUNIX RECLAIM',
    description: 'Professional IT asset recovery, secure data destruction, e-waste collection & responsible recycling services in Delhi. Help reduce environmental impact. Free doorstep collection.',
    keywords: 'e-waste management Delhi, IT asset recovery Delhi, computer recycling Delhi, laptop recycling Delhi, data destruction Delhi, e-waste collection Delhi, responsible recycling Delhi',
    canonical: '/reclaim',
    schemaName: 'SHAUNIX RECLAIM'
  },
  'about.html': {
    title: 'About SHAUNIX GROUP — Our Story, Vision & Mission',
    description: 'SHAUNIX GROUP is a diversified technology & business solutions group — six verticals covering products, services, digital, print, education and sustainability.',
    keywords: 'SHAUNIX GROUP, about SHAUNIX GROUP, IT company Delhi, technology group Delhi, IT services Badarpur Delhi, SHAUNIX TECH, SHAUNIX CARE, SHAUNIX ACADEMY',
    canonical: '/about',
    schemaName: 'SHAUNIX GROUP',
    crumbs: [{ name: 'Home', url: '/' }, { name: 'About Us', url: '/about' }]
  },
  'contact.html': {
    title: 'Contact SHAUNIX GROUP — Get a Quote, Book Service or Ask Anything',
    description: 'Contact SHAUNIX GROUP for IT products, repairs, websites & apps, printing, courses or e-waste pickup. Call, WhatsApp or send an enquiry form.',
    keywords: 'contact SHAUNIX GROUP, IT services Delhi contact, computer repair Badarpur, laptop repair near me, SHAUNIX GROUP phone number, SHAUNIX GROUP address, IT solutions Delhi contact',
    canonical: '/contact',
    schemaName: 'SHAUNIX GROUP',
    crumbs: [{ name: 'Home', url: '/' }, { name: 'Contact', url: '/contact' }]
  },
  'feedback.html': {
    title: 'Share Your Feedback — Rate Your SHAUNIX GROUP Experience',
    description: 'Used our products or services? Rate your SHAUNIX GROUP experience in under a minute — your honest feedback helps us serve you better.',
    keywords: 'SHAUNIX GROUP feedback, SHAUNIX GROUP reviews, rate SHAUNIX GROUP service, customer feedback SHAUNIX GROUP, SHAUNIX GROUP testimonials',
    canonical: '/feedback',
    schemaName: 'SHAUNIX GROUP',
    crumbs: [{ name: 'Home', url: '/' }, { name: 'Feedback', url: '/feedback' }]
  }
};

module.exports = { brand: BRAND, pages: PAGES };