/* ============================================================
   SHAUNIX GROUP — main.js
   Single file for all frontend logic
   ============================================================ */

(function() {
  'use strict';

  document.addEventListener('DOMContentLoaded', function() {

    /* -------------------------------------------------
     * 0) SITE DATA — injected from /config.js
     * ------------------------------------------------- */
    var SITE = window.SITE || {};
    var WHATSAPP_NUMBER = SITE.wa || '919000000000';
    var SITE_PHONE = SITE.phone || '';

    /* -------------------------------------------------
     * 1) IMAGE FALLBACK
     * ------------------------------------------------- */
    window.imgFallback = function(img) {
      var label = img.dataset.fallback || 'SG';
      var ph = document.createElement('span');
      ph.className = 'ph-fallback' + (img.closest('.brand') ? ' logo-ph' : ' media-ph');
      ph.textContent = label;
      img.replaceWith(ph);
    };

    var fallbackImages = document.querySelectorAll('img[data-fallback]');
    for (var i = 0; i < fallbackImages.length; i++) {
      (function(img) {
        img.addEventListener('error', function() {
          window.imgFallback(img);
        });
        if (img.complete && img.naturalWidth === 0 && img.src.indexOf('/images/') !== -1) {
          window.imgFallback(img);
        }
      })(fallbackImages[i]);
    }

    /* -------------------------------------------------
     * 2) MOBILE MENU
     * ------------------------------------------------- */
    var burger = document.getElementById('hamburger');
    var navList = document.getElementById('navLinks');

    /* Create overlay */
    var navOverlay = document.createElement('div');
    navOverlay.className = 'nav-overlay';
    document.body.appendChild(navOverlay);

    function openMenu() {
      navList.classList.add('open');
      burger.classList.add('active');
      burger.setAttribute('aria-expanded', 'true');
      document.body.classList.add('no-scroll');
      navOverlay.classList.add('show');
    }

    function closeMenu() {
      navList.classList.remove('open');
      burger.classList.remove('active');
      burger.setAttribute('aria-expanded', 'false');
      document.body.classList.remove('no-scroll');
      navOverlay.classList.remove('show');
    }

    function toggleMenu() {
      if (navList.classList.contains('open')) {
        closeMenu();
      } else {
        openMenu();
      }
    }

    if (burger && navList) {
      burger.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        toggleMenu();
      });

      navOverlay.addEventListener('click', function() {
        closeMenu();
      });

      /* Close menu when a link is clicked */
      var navLinks = navList.querySelectorAll('a');
      for (var i = 0; i < navLinks.length; i++) {
        navLinks[i].addEventListener('click', function(e) {
          /* Let submenu toggle handle dropdown parent links */
          if (this.parentElement.classList.contains('has-drop')) {
            return;
          }
          closeMenu();
        });
      }

      /* Close menu on Escape key */
      document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && navList.classList.contains('open')) {
          closeMenu();
        }
      });
    }

    /* Submenu toggle on mobile */
    var dropToggles = document.querySelectorAll('.has-drop > a');
    for (var i = 0; i < dropToggles.length; i++) {
      dropToggles[i].addEventListener('click', function(e) {
        if (window.innerWidth <= 900) {
          e.preventDefault();
          this.parentElement.classList.toggle('open-sub');
        }
      });
    }

    /* -------------------------------------------------
     * 3) ACTIVE NAV LINK
     * ------------------------------------------------- */
    var path = location.pathname.replace(/\/$/, '') || '/';
    var navItems = document.querySelectorAll('[data-nav]');
    for (var i = 0; i < navItems.length; i++) {
      if (navItems[i].dataset.nav === path) {
        navItems[i].classList.add('active');
      }
    }
    if (/^\/(tech|care|digital|print|academy|reclaim)$/.test(path)) {
      var dropLink = document.querySelector('.has-drop > a');
      if (dropLink) dropLink.classList.add('active');
    }

    /* -------------------------------------------------
     * 4) HEADER SHADOW ON SCROLL
     * ------------------------------------------------- */
    var header = document.querySelector('.site-header');
    function onScrollHeader() {
      if (header) {
        header.classList.toggle('scrolled', window.scrollY > 8);
      }
    }
    onScrollHeader();
    window.addEventListener('scroll', onScrollHeader, { passive: true });

    /* -------------------------------------------------
     * 5) SCROLL REVEAL + STAGGER
     * ------------------------------------------------- */
    var reveals = document.querySelectorAll('.reveal');
    if ('IntersectionObserver' in window && reveals.length) {
      var staggerGroups = document.querySelectorAll('[data-stagger]');
      for (var i = 0; i < staggerGroups.length; i++) {
        var children = staggerGroups[i].children;
        for (var j = 0; j < children.length; j++) {
          children[j].style.transitionDelay = (j * 70) + 'ms';
        }
      }
      var io = new IntersectionObserver(function(entries) {
        for (var i = 0; i < entries.length; i++) {
          if (!entries[i].isIntersecting) continue;
          entries[i].target.classList.add('in');
          io.unobserve(entries[i].target);
        }
      }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
      for (var i = 0; i < reveals.length; i++) {
        io.observe(reveals[i]);
      }
    } else {
      for (var i = 0; i < reveals.length; i++) {
        reveals[i].classList.add('in');
      }
    }

    /* -------------------------------------------------
     * 6) COUNTERS
     * ------------------------------------------------- */
    var counters = document.querySelectorAll('[data-count]');
    if (counters.length && 'IntersectionObserver' in window) {
      var co = new IntersectionObserver(function(entries) {
        for (var i = 0; i < entries.length; i++) {
          if (!entries[i].isIntersecting) continue;
          runCount(entries[i].target);
          co.unobserve(entries[i].target);
        }
      }, { threshold: 0.4 });
      for (var i = 0; i < counters.length; i++) {
        co.observe(counters[i]);
      }
    }

    function runCount(el) {
      var target = parseInt(el.dataset.count, 10) || 0;
      var suffix = el.dataset.suffix || '+';
      var dur = 1400;
      var t0 = performance.now();
      (function tick(now) {
        var p = Math.min((now - t0) / dur, 1);
        el.textContent = Math.round(target * (0.2 + 0.8 * p * p)) + suffix;
        if (p < 1) requestAnimationFrame(tick);
      })(t0);
    }

    /* -------------------------------------------------
     * 7) BACK TO TOP
     * ------------------------------------------------- */
    var toTop = document.getElementById('toTop');
    if (toTop) {
      function onScrollTop() {
        toTop.classList.toggle('show', window.scrollY > 520);
      }
      onScrollTop();
      window.addEventListener('scroll', onScrollTop, { passive: true });
      toTop.addEventListener('click', function() {
        window.scrollTo({ top: 0, behavior: 'smooth' });
      });
    }

    /* -------------------------------------------------
     * 8) CONTACT FORM — AJAX + WhatsApp option
     * ------------------------------------------------- */
    var form = document.getElementById('contactForm');
    if (form) {
      var status = document.getElementById('formStatus');
      var submitBt = document.getElementById('submitBtn');
      var waBtn = document.getElementById('waSendBtn');

      if (waBtn) waBtn.hidden = false;

      function collectMsg() {
        var f = new FormData(form);
        return 'Hi SHAUNIX GROUP!\n\n' +
          'Name: ' + (f.get('name') || '') + '\n' +
          'Phone: ' + (f.get('phone') || '') + '\n' +
          'Email: ' + (f.get('email') || '') + '\n' +
          'Service: ' + (f.get('service') || '') + '\n\n' +
          'Message: ' + (f.get('message') || '');
      }

      if (waBtn) {
        waBtn.addEventListener('click', function() {
          window.open('https://wa.me/' + WHATSAPP_NUMBER + '?text=' + encodeURIComponent(collectMsg()), '_blank');
        });
      }

      form.addEventListener('submit', function(e) {
        e.preventDefault();
        if (!form.checkValidity()) {
          form.reportValidity();
          return;
        }

        submitBt.disabled = true;
        submitBt.textContent = 'Sending...';
        status.textContent = '';
        status.className = 'form-status';

        fetch(form.action, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'fetch' },
          body: JSON.stringify(Object.fromEntries(new FormData(form)))
        })
        .then(function(res) {
          if (!res.ok) throw new Error('fail');
          return res.json();
        })
        .then(function() {
          var msg = collectMsg();
          form.innerHTML =
            '<div class="sent-success">' +
              '<div class="tick">✓</div>' +
              '<h3>Message Received!</h3>' +
              '<p>Thank you for reaching out! Our team will contact you shortly.<br>For urgent enquiries, please connect via WhatsApp:</p>' +
              '<a class="btn btn-wa" target="_blank" rel="noopener" ' +
                'href="https://wa.me/' + WHATSAPP_NUMBER + '?text=' + encodeURIComponent(msg) + '">Chat on WhatsApp</a>' +
            '</div>';
        })
        .catch(function() {
          status.textContent = 'Unable to send. Please use the WhatsApp button below.';
          status.className = 'form-status error';
          submitBt.disabled = false;
          submitBt.textContent = 'Send Message →';
        });
      });
    }

    /* -------------------------------------------------
     * 9) CONTACT PAGE — ?sent=1 banner
     * ------------------------------------------------- */
    var sentZone = document.querySelector('.sent-banner-zone');
    if (sentZone && new URLSearchParams(location.search).get('sent')) {
      sentZone.innerHTML =
        '<div class="sent-banner"><b>Message received!</b> Our team will reply shortly. ' +
        'For urgent enquiries, contact us on WhatsApp → ' +
        '<a href="https://wa.me/' + WHATSAPP_NUMBER + '" target="_blank" rel="noopener"><b>' + SITE_PHONE + '</b></a></div>';
    }
  });
})();