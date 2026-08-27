/* ============================================================
   SHAUNIX GROUP — main.js
   (menu • animations • contact form • whatsapp • polish)
   Sirf ye ek file chahiye frontend logic ke liye ✨
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {

  /* -------------------------------------------------
   * 0) SITE DATA — /config.js se aata hai (ek hi jagah!)
   * ------------------------------------------------- */
  const SITE = window.SITE || {};
  const WHATSAPP_NUMBER = SITE.wa || '919000000000';
  const SITE_PHONE      = SITE.phone || '';

  /* -------------------------------------------------
   * 1) IMAGE FALLBACK — logo/images na ho to sundar placeholder
   * ------------------------------------------------- */
  window.imgFallback = function (img) {
    const label = img.dataset.fallback || 'SG';
    const ph = document.createElement('span');
    ph.className = 'ph-fallback' + (img.closest('.brand') ? ' logo-ph' : ' media-ph');
    ph.textContent = label;
    img.replaceWith(ph);
  };
  document.querySelectorAll('img[data-fallback]').forEach((img) => {
    img.addEventListener('error', () => window.imgFallback(img));
    if (img.complete && img.naturalWidth === 0 && img.src.includes('/images/')) {
      window.imgFallback(img);
    }
  });

  /* -------------------------------------------------
   * 2) MOBILE MENU + SUBMENU
   * ------------------------------------------------- */
  const burger  = document.getElementById('hamburger');
  const navList = document.getElementById('navLinks');

  if (burger && navList) {
    burger.addEventListener('click', () => {
      const open = navList.classList.toggle('open');
      burger.classList.toggle('active', open);
      burger.setAttribute('aria-expanded', open);
      document.body.classList.toggle('no-scroll', open);
    });
    navList.querySelectorAll('a').forEach((a) =>
      a.addEventListener('click', () => {
        navList.classList.remove('open');
        burger.classList.remove('active');
        document.body.classList.remove('no-scroll');
      })
    );
  }

  document.querySelectorAll('.has-drop > a').forEach((link) => {
    link.addEventListener('click', (e) => {
      if (window.innerWidth <= 900) {
        e.preventDefault();
        link.parentElement.classList.toggle('open-sub');
      }
    });
  });

  /* -------------------------------------------------
   * 3) ACTIVE NAV LINK
   * ------------------------------------------------- */
  const path = location.pathname.replace(/\/$/, '') || '/';
  document.querySelectorAll('[data-nav]').forEach((a) => {
    if (a.dataset.nav === path) a.classList.add('active');
  });
  if (/^\/(tech|care|digital|print|academy|reclaim)$/.test(path)) {
    document.querySelector('.has-drop > a')?.classList.add('active');
  }

  /* -------------------------------------------------
   * 4) HEADER SHADOW ON SCROLL
   * ------------------------------------------------- */
  const header = document.querySelector('.site-header');
  const onScrollHeader = () => header?.classList.toggle('scrolled', window.scrollY > 8);
  onScrollHeader();
  addEventListener('scroll', onScrollHeader, { passive: true });

  /* -------------------------------------------------
   * 5) SCROLL REVEAL + STAGGER
   * ------------------------------------------------- */
  const reveals = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window && reveals.length) {
    document.querySelectorAll('[data-stagger]').forEach((group) => {
      [...group.children].forEach((child, i) => child.style.transitionDelay = `${i * 70}ms`);
    });
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (!en.isIntersecting) return;
        en.target.classList.add('in');
        io.unobserve(en.target);
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    reveals.forEach((el) => io.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add('in'));
  }

  /* -------------------------------------------------
   * 6) COUNTERS
   * ------------------------------------------------- */
  const counters = document.querySelectorAll('[data-count]');
  if (counters.length && 'IntersectionObserver' in window) {
    const co = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (!en.isIntersecting) return;
        runCount(en.target);
        co.unobserve(en.target);
      });
    }, { threshold: 0.4 });
    counters.forEach((el) => co.observe(el));
  }
  function runCount(el) {
    const target = parseInt(el.dataset.count, 10) || 0;
    const suffix = el.dataset.suffix || '+';
    const dur = 1400, t0 = performance.now();
    (function tick(now) {
      const p = Math.min((now - t0) / dur, 1);
      el.textContent = Math.round(target * (0.2 + 0.8 * p * p)) + suffix;
      if (p < 1) requestAnimationFrame(tick);
    })(t0);
  }

  /* -------------------------------------------------
   * 7) BACK TO TOP
   * ------------------------------------------------- */
  const toTop = document.getElementById('toTop');
  if (toTop) {
    const onScrollTop = () => toTop.classList.toggle('show', window.scrollY > 520);
    onScrollTop();
    addEventListener('scroll', onScrollTop, { passive: true });
    toTop.addEventListener('click', () => scrollTo({ top: 0, behavior: 'smooth' }));
  }

  /* -------------------------------------------------
   * 8) CONTACT FORM — AJAX + WhatsApp option
   * ------------------------------------------------- */
  const form = document.getElementById('contactForm');
  if (form) {
    const status   = document.getElementById('formStatus');
    const submitBt = document.getElementById('submitBtn');
    const waBtn    = document.getElementById('waSendBtn');

    if (waBtn) waBtn.hidden = false;

    function collectMsg() {
      const f = new FormData(form);
      return `Hi SHAUNIX GROUP! 👋\n\n` +
        `Naam: ${f.get('name') || ''}\n` +
        `Phone: ${f.get('phone') || ''}\n` +
        `Email: ${f.get('email') || ''}\n` +
        `Service: ${f.get('service') || ''}\n\n` +
        `Message: ${f.get('message') || ''}`;
    }

    waBtn?.addEventListener('click', () =>
      window.open(`https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(collectMsg())}`, '_blank')
    );

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      if (!form.checkValidity()) { form.reportValidity(); return; }

      submitBt.disabled = true;
      submitBt.textContent = 'Sending… ⏳';
      status.textContent = '';
      status.className = 'form-status';

      try {
        const res = await fetch(form.action, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'fetch' },
          body: JSON.stringify(Object.fromEntries(new FormData(form)))
        });
        if (!res.ok) throw new Error('fail');

        const msg = collectMsg();
        form.innerHTML =
          `<div class="sent-success">
             <div class="tick">🎉</div>
             <h3>Message received!</h3>
             <p>Dhanyavaad! Hamari team jald hi aapse connect karegi.<br>Urgent ho to seedha WhatsApp karein:</p>
             <a class="btn btn-wa" target="_blank" rel="noopener"
                href="https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(msg)}">💬 Chat on WhatsApp</a>
           </div>`;
      } catch (err) {
        status.textContent = '⚠️ Send nahi hua — neeche WhatsApp button se bhejein.';
        status.className = 'form-status error';
        submitBt.disabled = false;
        submitBt.textContent = 'Send Message ➜';
      }
    });
  }

  /* -------------------------------------------------
   * 9) CONTACT PAGE — ?sent=1 banner (no-JS fallback)
   * ------------------------------------------------- */
  const sentZone = document.querySelector('.sent-banner-zone');
  if (sentZone && new URLSearchParams(location.search).get('sent')) {
    sentZone.innerHTML =
      `<div class="sent-banner">✅ <b>Message mil gaya!</b> Hamari team jald reply karegi.
       Urgent ho to WhatsApp 👉
       <a href="https://wa.me/${WHATSAPP_NUMBER}" target="_blank" rel="noopener"><b>${SITE_PHONE}</b></a></div>`;
  }
});



