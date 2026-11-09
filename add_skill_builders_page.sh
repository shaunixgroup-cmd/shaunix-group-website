#!/usr/bin/env bash
# =====================================================================
#  SHAUNIX GROUP website  ->  naya page: SHAUNIX SKILL BUILDERS (/skill-builders)
#  Run (project folder ke andar, jahan server.js hai):
#       bash add_skill_builders_page.sh
#  Ya:  bash add_skill_builders_page.sh /path/to/shaunix-group-website-master
#
#  Ye script karta hai:
#   1) views/skill-builders.html        (naya page, same design system)
#   2) routes/skillbuilders.js          (route)
#   3) public/css/skill-builders.css    (sirf is page ki extra styling)
#   4) server.js                        (route register, redirect-all se PEHLE)
#   5) seo.config.js                    (title, description, keywords, canonical)
#   6) public/sitemap.xml               (URL add)
#   7) views/partials/header.html       (Services dropdown mein link)
#   8) views/partials/footer.html       (footer links)
#   9) views/services/academy.html      (Academy page par "For Schools" strip)
#  Har change se pehle backup banta hai + RESTORE.sh (undo ke liye).
#  Dobara chalane par duplicate nahi banta.
# =====================================================================

ROOT="${1:-$PWD}"
line() { printf '%s\n' "------------------------------------------------------------"; }

if [ ! -f "$ROOT/server.js" ] || [ ! -d "$ROOT/views" ] || [ ! -f "$ROOT/seo.config.js" ]; then
  echo "server.js / views / seo.config.js nahi mila: $ROOT"
  read -r -p "Website project folder ka path do: " ROOT
  ROOT="${ROOT/#\~/$HOME}"
  if [ ! -f "$ROOT/server.js" ] || [ ! -d "$ROOT/views" ] || [ ! -f "$ROOT/seo.config.js" ]; then
    echo "Ye shaunix website folder nahi lag raha. Band kar raha hoon."; exit 1
  fi
fi
command -v node >/dev/null 2>&1 || { echo "Node.js chahiye (aapke paas hai, PATH mein nahi mila)."; exit 1; }

ROOT="$(cd "$ROOT" && pwd)"
echo; line; echo "  SHAUNIX SKILL BUILDERS page installer"; echo "  Project: $ROOT"; line

read -r -p "  Fee per student page par dikhani hai? (jaise 599, blank = mat dikhao): " FEE
read -r -p "  'Pilot partner schools' banner dikhana hai? (y/n) [y]: " PILOT; PILOT="${PILOT:-y}"

# ---------- backup ----------
BK="$ROOT/.sb_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BK"
FILES_EDIT=(server.js seo.config.js public/sitemap.xml views/partials/header.html views/partials/footer.html views/services/academy.html)
FILES_NEW=(views/skill-builders.html routes/skillbuilders.js public/css/skill-builders.css)
for f in "${FILES_EDIT[@]}" "${FILES_NEW[@]}"; do
  if [ -f "$ROOT/$f" ]; then mkdir -p "$BK/$(dirname "$f")"; cp "$ROOT/$f" "$BK/$f"; fi
done
{
  echo '#!/usr/bin/env bash'
  echo "# Undo: purani files wapas, naye files hata do"
  echo "cd \"$ROOT\" || exit 1"
  for f in "${FILES_EDIT[@]}"; do
    [ -f "$BK/$f" ] && echo "cp \"$BK/$f\" \"$ROOT/$f\""
  done
  for f in "${FILES_NEW[@]}"; do
    if [ -f "$BK/$f" ]; then echo "cp \"$BK/$f\" \"$ROOT/$f\""; else echo "rm -f \"$ROOT/$f\""; fi
  done
  echo 'echo "Restore ho gaya. Server restart karo."'
} > "$BK/RESTORE.sh"
echo "  Backup: $BK  (undo: bash $BK/RESTORE.sh)"

mkdir -p "$ROOT/routes" "$ROOT/views" "$ROOT/public/css"

# =====================================================================
# 1) ROUTE
# =====================================================================
cat > "$ROOT/routes/skillbuilders.js" <<'EOF'
// GET  /skill-builders  -> SHAUNIX SKILL BUILDERS (school programs) page
const express = require('express');
const { renderPage } = require('./render');

const router = express.Router();

router.get(['/skill-builders', '/skillbuilders', '/schools'], (req, res) => {
  renderPage(res, 'skill-builders.html');
});

module.exports = router;
EOF

# =====================================================================
# 2) PAGE CSS  (site ke variables use karta hai: --accent, --navy, --line ...)
# =====================================================================
cat > "$ROOT/public/css/skill-builders.css" <<'EOF'
/* ============================================================
   SHAUNIX SKILL BUILDERS page extras (style.css ke upar)
   ============================================================ */
.sb-banner{display:inline-flex;align-items:center;gap:10px;margin-bottom:18px;padding:8px 18px;border-radius:999px;
  background:rgba(247,144,9,.16);border:1px solid rgba(247,144,9,.45);color:#ffd9a0;font-weight:600;font-size:.9rem}
.sb-motto{font-family:var(--font-head);font-weight:700;letter-spacing:.02em;color:#ffb44d;margin:0 0 14px;font-size:1.05rem}
.sb-stats{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-top:44px}
.sb-stat{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.16);border-radius:var(--r-md);padding:18px 12px;text-align:center}
.sb-stat b{display:block;font-family:var(--font-head);font-size:2.1rem;line-height:1.1;color:#ffb44d}
.sb-stat span{display:block;margin-top:4px;font-size:.82rem;color:#cbd6ee;letter-spacing:.03em}

.sb-timeline{display:grid;grid-template-columns:repeat(5,1fr);gap:18px}
.sb-stage{background:#fff;border:1px solid var(--line);border-radius:var(--r-lg);padding:26px 20px;box-shadow:var(--shadow-sm)}
.sb-stage small{display:inline-block;font-weight:700;font-size:.74rem;letter-spacing:.07em;text-transform:uppercase;color:var(--accent)}
.sb-stage h3{margin:8px 0 8px;font-size:1.12rem}
.sb-stage p{font-size:.92rem;line-height:1.55}
.sb-stage.hot{background:var(--navy);border-color:var(--navy)}
.sb-stage.hot h3{color:#fff}.sb-stage.hot p{color:#cbd6ee}.sb-stage.hot small{color:#ffb44d}

.sb-chips{display:flex;flex-wrap:wrap;gap:12px;justify-content:center}
.sb-chip{display:inline-flex;align-items:center;gap:8px;padding:10px 18px;border-radius:999px;background:#fff;border:1px solid var(--line);
  box-shadow:var(--shadow-sm);font-weight:600;color:var(--ink);font-size:.95rem}
.sb-chip i{font-style:normal}

.sb-two{display:grid;grid-template-columns:1fr 1fr;gap:26px}
.sb-card{background:#fff;border:1px solid var(--line);border-radius:var(--r-lg);padding:30px;box-shadow:var(--shadow-sm)}
.sb-card h3{margin-bottom:14px}
.sb-ages{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}
.sb-age{background:var(--navy);color:#cbd6ee;border-radius:var(--r-md);padding:16px 10px;text-align:center;font-size:.85rem}
.sb-age b{display:block;font-family:var(--font-head);color:#ffb44d;font-size:1.05rem;margin-bottom:2px}
.sb-table{width:100%;border-collapse:collapse;font-size:.97rem}
.sb-table th,.sb-table td{padding:11px 14px;text-align:left;border-bottom:1px solid var(--line)}
.sb-table th{background:var(--navy);color:#fff;font-weight:600}
.sb-table td:last-child,.sb-table th:last-child{text-align:right;font-weight:700;color:var(--accent)}
.sb-table th:last-child{color:#fff}
.sb-table tr:last-child td{border-bottom:0;background:var(--bg);color:var(--ink)}

.sb-fee{display:flex;justify-content:center;margin-top:40px}
.sb-fee>div{text-align:center;padding:22px 44px;border-radius:var(--r-lg);background:linear-gradient(135deg,#f79009,#ffb44d);color:#fff;box-shadow:var(--shadow-md)}
.sb-fee small{display:block;font-weight:600;letter-spacing:.06em;text-transform:uppercase}
.sb-fee b{display:block;font-family:var(--font-head);font-size:2.6rem;line-height:1.1}
.sb-fee span{font-size:.88rem}

.sb-faq{max-width:820px;margin:0 auto;display:grid;gap:12px}
.sb-faq details{background:#fff;border:1px solid var(--line);border-radius:var(--r-md);padding:4px 22px;box-shadow:var(--shadow-sm)}
.sb-faq summary{cursor:pointer;list-style:none;padding:16px 0;font-weight:700;color:var(--ink);font-family:var(--font-head);display:flex;justify-content:space-between;gap:14px}
.sb-faq summary::-webkit-details-marker{display:none}
.sb-faq summary::after{content:'+';color:var(--accent);font-size:1.4rem;line-height:1}
.sb-faq details[open] summary::after{content:'\2212'}
.sb-faq details p{padding:0 0 18px;max-width:none}

.sb-note{max-width:760px;margin:26px auto 0;text-align:center;font-size:.88rem;color:var(--muted)}

.sb-promo{display:flex;align-items:center;justify-content:space-between;gap:28px;flex-wrap:wrap;padding:34px 38px;border-radius:var(--r-lg);
  background:linear-gradient(135deg,var(--navy),var(--navy-3));color:#cbd6ee;box-shadow:var(--shadow-lg)}
.sb-promo h2{color:#fff;font-size:clamp(1.3rem,2.4vw,1.8rem);margin:6px 0 8px}
.sb-promo p{max-width:56ch}

@media (max-width:1000px){
  .sb-timeline{grid-template-columns:repeat(2,1fr)}
  .sb-stats{grid-template-columns:repeat(2,1fr)}
  .sb-two{grid-template-columns:1fr}
}
@media (max-width:560px){
  .sb-timeline{grid-template-columns:1fr}
  .sb-ages{grid-template-columns:1fr}
  .sb-promo{padding:26px 22px}
  .sb-fee>div{padding:20px 24px}
}
EOF

# =====================================================================
# 3) PAGE VIEW  (placeholders @@...@@ neeche node script bharti hai)
# =====================================================================
cat > "$ROOT/views/skill-builders.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  {{SEO}}
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link
    href="https://fonts.googleapis.com/css2?family=Sora:wght@600;700;800&family=Inter:wght@400;500;600;700&display=swap"
    rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css">
  <link rel="stylesheet" href="/css/responsive.css">
  <link rel="stylesheet" href="/css/skill-builders.css">
</head>

<body data-theme="academy">
  {{HEADER}}

  <!-- ================= HERO ================= -->
  <section class="page-hero">
    <div class="container">
      <nav class="crumbs" aria-label="Breadcrumb"><a href="/">Home</a><i>›</i><a href="/academy">SHAUNIX ACADEMY</a><i>›</i><b>SKILL BUILDERS</b></nav>
      @@PILOT_BANNER@@
      <span class="eyebrow eyebrow-light">🏫 Practical Skill Programs for Schools</span>
      <h1>SHAUNIX <em>SKILL BUILDERS</em></h1>
      <p class="sb-motto">Learn it. Build it. Show it. &nbsp;·&nbsp; Seekho. Banao. Dikhao.</p>
      <p class="ph-sub">We bring hands-on technology education to your school. Students don't just sit and listen —
        they train for 7 days, build a live project in the next 3, and present it at a school showcase.</p>
      <div class="hero-actions">
        <a class="btn btn-primary" href="https://wa.me/{{WA_NUM}}?text=Hi%20SHAUNIX%20SKILL%20BUILDERS%2C%20we%20would%20like%20a%20free%20demo%20for%20our%20school." target="_blank" rel="noopener">Book a Free School Demo</a>
        <a class="btn btn-outline-light" href="#model">See the 7+3 Model</a>
      </div>
      <div class="sb-stats">
        <div class="sb-stat"><b>7</b><span>DAYS OF TRAINING</span></div>
        <div class="sb-stat"><b>3</b><span>DAYS LIVE PROJECT</span></div>
        <div class="sb-stat"><b>6</b><span>SKILL TRACKS</span></div>
        <div class="sb-stat"><b>1</b><span>FINAL SHOWCASE</span></div>
      </div>
    </div>
  </section>

  <!-- ================= 7+3 MODEL ================= -->
  <section class="section" id="model">
    <div class="container">
      <div class="section-head center reveal">
        <span class="eyebrow">The 7 + 3 Model</span>
        <h2>From classroom to <em>working project</em> in 10 days.</h2>
        <p>A complete extracurricular activity for your school — structured, supervised and built around doing, not just listening.</p>
      </div>
      <div class="sb-timeline" data-stagger>
        <div class="sb-stage reveal"><small>Day 1 – 2</small><h3>Foundation</h3><p>Core concepts explained simply, with a hands-on activity from the very first day.</p></div>
        <div class="sb-stage reveal"><small>Day 3 – 5</small><h3>Build Skills</h3><p>Tools, kits and practical exercises in small teams with a trainer on the floor.</p></div>
        <div class="sb-stage reveal"><small>Day 6 – 7</small><h3>Plan the Project</h3><p>Every team picks an idea, plans it and gets a project brief and materials guidance.</p></div>
        <div class="sb-stage hot reveal"><small>Day 8 – 10</small><h3>Live Project</h3><p>Students build their own working project with mentor support.</p></div>
        <div class="sb-stage reveal"><small>Final Day</small><h3>Showcase &amp; Awards</h3><p>Demo to teachers and parents, transparent judging, awards and certificates.</p></div>
      </div>
    </div>
  </section>

  <!-- ================= TRACKS ================= -->
  <section class="section section-alt" id="tracks">
    <div class="container">
      <div class="section-head center reveal">
        <span class="eyebrow">Skill Tracks</span>
        <h2>Pick a track. <em>Students build real things.</em></h2>
        <p>Your school chooses the track for each batch. We bring the kits, tools and trainers.</p>
      </div>
      <div class="course-grid" data-stagger>
        <article class="course-card reveal">
          <div class="course-top"><span class="course-ico">🤖</span><span class="duration">7 + 3 Days</span></div>
          <h3>AI &amp; Future Tech</h3>
          <div class="course-meta"><span>👦 Class 8–12</span><span>🔥 High Demand</span></div>
          <p>Understand how AI works, write good prompts, build a simple chatbot or image-recognition demo, and learn to use AI responsibly.</p>
          <div class="course-out">🎯 Project: School FAQ chatbot / AI poster studio</div>
        </article>
        <article class="course-card reveal">
          <div class="course-top"><span class="course-ico">💻</span><span class="duration">7 + 3 Days</span></div>
          <h3>Coding &amp; Apps</h3>
          <div class="course-meta"><span>👦 Class 6–12</span><span>⭐ Beginner Friendly</span></div>
          <p>HTML, CSS and JavaScript basics, game logic and live web apps that students can open on their own phones.</p>
          <div class="course-out">🎯 Project: portfolio website / live quiz game</div>
        </article>
        <article class="course-card reveal">
          <div class="course-top"><span class="course-ico">🖥️</span><span class="duration">7 + 3 Days</span></div>
          <h3>PC Hardware &amp; Networking</h3>
          <div class="course-meta"><span>👦 Class 6–12</span><span>🛠️ Hands-on</span></div>
          <p>Identify parts, assemble a PC, install an OS, diagnose faults and set up a small network, all with supervised, power-off assembly.</p>
          <div class="course-out">🎯 Project: build &amp; boot a team PC / PC Doctor challenge</div>
        </article>
        <article class="course-card reveal">
          <div class="course-top"><span class="course-ico">🔌</span><span class="duration">7 + 3 Days</span></div>
          <h3>Electronics &amp; Robotics</h3>
          <div class="course-meta"><span>👦 Class 8–12</span><span>⚡ Low Voltage Only</span></div>
          <p>Circuits, sensors and Arduino basics, leading to a small automation or robot that solves a real problem.</p>
          <div class="course-out">🎯 Project: smart dustbin / plant watering / obstacle robot</div>
        </article>
        <article class="course-card reveal">
          <div class="course-top"><span class="course-ico">☀️</span><span class="duration">7 + 3 Days</span></div>
          <h3>Green Energy</h3>
          <div class="course-meta"><span>👦 Class 6–10</span><span>🌱 Eco Friendly</span></div>
          <p>How solar cells work, safe low-voltage circuits and clean-energy ideas for the school and home.</p>
          <div class="course-out">🎯 Project: solar street light / solar mini fan</div>
        </article>
        <article class="course-card reveal">
          <div class="course-top"><span class="course-ico">🛡️</span><span class="duration">7 + 3 Days</span></div>
          <h3>Cyber Safety &amp; Digital Skills</h3>
          <div class="course-meta"><span>👦 Class 6–12</span><span>📣 Creator Skills</span></div>
          <p>Safe internet use, strong passwords and phishing awareness, plus design and short-video skills for young creators.</p>
          <div class="course-out">🎯 Project: cyber-safety awareness campaign</div>
        </article>
      </div>
      @@FEE_BLOCK@@
    </div>
  </section>

  <!-- ================= PROJECTS ================= -->
  <section class="section">
    <div class="container">
      <div class="section-head center reveal">
        <span class="eyebrow">Project Ideas</span>
        <h2>What students <em>actually build</em>.</h2>
        <p>A few of the projects students choose from. The final list depends on the track and class.</p>
      </div>
      <div class="sb-chips reveal">
        <span class="sb-chip"><i>🧑‍🔧</i>Build Your Own PC</span>
        <span class="sb-chip"><i>🩺</i>PC Doctor Challenge</span>
        <span class="sb-chip"><i>🎮</i>Live Quiz Game</span>
        <span class="sb-chip"><i>🧠</i>Image Recognition Demo</span>
        <span class="sb-chip"><i>🎨</i>AI Poster &amp; Story Studio</span>
        <span class="sb-chip"><i>🌐</i>Personal Portfolio Website</span>
        <span class="sb-chip"><i>🕹️</i>Retro Gaming Console</span>
        <span class="sb-chip"><i>🕵️</i>Cyber Safety Detective</span>
        <span class="sb-chip"><i>🗑️</i>Smart Dustbin</span>
        <span class="sb-chip"><i>🌿</i>Automatic Plant Watering</span>
        <span class="sb-chip"><i>💡</i>Solar Street Light</span>
        <span class="sb-chip"><i>🌀</i>Solar Mini Fan</span>
        <span class="sb-chip"><i>🤖</i>Obstacle Avoiding Robot</span>
        <span class="sb-chip"><i>🌦️</i>Mini Weather Station</span>
      </div>
    </div>
  </section>

  <!-- ================= WHY SCHOOLS ================= -->
  <section class="section section-alt">
    <div class="container why-split">
      <div class="why-copy reveal">
        <span class="eyebrow">Why Schools Choose Us</span>
        <h2>Real skills, <em>zero burden</em> on your staff.</h2>
        <p class="lead">Parents want future skills for their children. Schools want it without extra teachers, extra setup or extra risk. This program is built for exactly that.</p>
        <ul class="checklist">
          <li>No extra teacher needed: trainers, kits and lesson plans come with us</li>
          <li>Low-voltage, supervised activities only</li>
          <li>Written agreement and school permission before every batch</li>
          <li>Photos, report and showcase content for your annual day and social media</li>
        </ul>
      </div>
      <div class="feature-list" data-stagger>
        <div class="feat reveal"><span class="fi">🛠️</span>
          <div><h3>Learn by Building</h3><p>Hands-on activity from day one, with a working project at the end of every batch.</p></div>
        </div>
        <div class="feat reveal"><span class="fi">🦺</span>
          <div><h3>Safety First</h3><p>Trainer ID and details are shared with the school, and students never handle mains power.</p></div>
        </div>
        <div class="feat reveal"><span class="fi">⚖️</span>
          <div><h3>Transparent Judging</h3><p>Showcase marks are shared in writing before the program begins.</p></div>
        </div>
        <div class="feat reveal"><span class="fi">🎓</span>
          <div><h3>Certificate of Participation</h3><p>Every student receives a SHAUNIX SKILL BUILDERS participation certificate.</p></div>
        </div>
      </div>
    </div>
  </section>

  <!-- ================= AGE GROUPS + JUDGING ================= -->
  <section class="section">
    <div class="container">
      <div class="section-head center reveal">
        <span class="eyebrow">Batches &amp; Showcase</span>
        <h2>Right level for <em>every age group</em>.</h2>
      </div>
      <div class="sb-two">
        <div class="sb-card reveal">
          <h3>Age-wise batches</h3>
          <div class="sb-ages">
            <div class="sb-age"><b>Junior</b>Class 6–8<br>Basics, solar, simple electronics</div>
            <div class="sb-age"><b>Intermediate</b>Class 8–10<br>Coding, robotics, PC skills</div>
            <div class="sb-age"><b>Senior</b>Class 9–12<br>AI, apps, advanced projects</div>
          </div>
          <p style="margin-top:16px">We never mix very different classes in one syllabus, so every student learns at the right pace.</p>
        </div>
        <div class="sb-card reveal">
          <h3>How projects are judged</h3>
          <table class="sb-table">
            <tr><th>Criteria</th><th>Marks</th></tr>
            <tr><td>Working model</td><td>30</td></tr>
            <tr><td>Innovation</td><td>25</td></tr>
            <tr><td>Practical usefulness</td><td>20</td></tr>
            <tr><td>Presentation</td><td>15</td></tr>
            <tr><td>Creativity</td><td>10</td></tr>
            <tr><td>Total</td><td>100</td></tr>
          </table>
        </div>
      </div>
    </div>
  </section>

  <!-- ================= STEPS FOR SCHOOLS ================= -->
  <section class="section section-alt">
    <div class="container">
      <div class="section-head center reveal">
        <span class="eyebrow">For Schools</span>
        <h2>Getting started is <em>simple</em>.</h2>
      </div>
      <div class="grid-4" data-stagger>
        <div class="step reveal"><span class="step-ico">🎤</span>
          <div class="step-num">1</div>
          <h3>Free Demo</h3>
          <p>A 30-minute live demo activity with a small group of your students.</p>
        </div>
        <div class="step reveal"><span class="step-ico">📝</span>
          <div class="step-num">2</div>
          <h3>Agreement</h3>
          <p>Track, dates, class groups, fees and safety terms agreed in writing.</p>
        </div>
        <div class="step reveal"><span class="step-ico">🛠️</span>
          <div class="step-num">3</div>
          <h3>7 + 3 Program</h3>
          <p>Seven days of training, then three days of live project building.</p>
        </div>
        <div class="step reveal"><span class="step-ico">🏆</span>
          <div class="step-num">4</div>
          <h3>Showcase</h3>
          <p>Project demo, judging, awards and certificates, with a report for your school.</p>
        </div>
      </div>
    </div>
  </section>

  <!-- ================= FAQ ================= -->
  <section class="section">
    <div class="container">
      <div class="section-head center reveal">
        <span class="eyebrow">FAQ</span>
        <h2>Questions schools <em>ask us</em>.</h2>
      </div>
      <div class="sb-faq reveal">
        <details><summary>Is the certificate government recognised?</summary>
          <p>No. SHAUNIX SKILL BUILDERS is a private skill-development program. Students receive a Certificate of Participation from SHAUNIX SKILL BUILDERS, which is not a government-recognised qualification.</p></details>
        <details><summary>Who brings the materials and kits?</summary>
          <p>We bring the kits and tools. What is included for each batch is written clearly in the school agreement, so there are no hidden charges for parents.</p></details>
        <details><summary>Is it safe for children?</summary>
          <p>Yes. We use low-voltage kits only, assemble PCs with the power off, keep sessions supervised, and share trainer ID details with the school.</p></details>
        <details><summary>When can the program run?</summary>
          <p>After school hours, during activity periods or in vacations, whichever suits your timetable.</p></details>
        <details><summary>Can we choose the track?</summary>
          <p>Yes. Choose from AI, Coding, PC Hardware, Electronics, Green Energy or Cyber Safety. We recommend the right level for each class group.</p></details>
      </div>
      <p class="sb-note">SHAUNIX SKILL BUILDERS is a vertical of SHAUNIX GROUP. Participation certificates do not carry any government or board recognition.</p>
    </div>
  </section>

  {{CONTACT_SECTION}}

  {{FOOTER}}
</body>

</html>
EOF

# =====================================================================
# 4) NODE: placeholders bharo + baaki files edit karo (idempotent)
# =====================================================================
FEE="$FEE" PILOT="$PILOT" node - "$ROOT" <<'EOF'
const fs = require('fs'), path = require('path');
const root = process.argv[2];
const P = p => path.join(root, p);
const rd = p => fs.readFileSync(P(p), 'utf8');
const wr = (p, s) => fs.writeFileSync(P(p), s);
const SLUG = 'skill-builders';

/* ---- page placeholders ---- */
let page = rd('views/skill-builders.html');
const fee = (process.env.FEE || '').replace(/[^0-9.,]/g, '');
const pilot = /^y/i.test(process.env.PILOT || 'y');
page = page.replace('@@FEE_BLOCK@@', fee
  ? `<div class="sb-fee reveal"><div><small>Program fee</small><b>&#8377;${fee}</b><span>per student · 7+3 days · material scope as per the written school agreement</span></div></div>`
  : '');
page = page.replace('@@PILOT_BANNER@@', pilot
  ? '<div class="sb-banner">🚀 Now onboarding pilot partner schools · free 30-minute demo</div>'
  : '');
wr('views/skill-builders.html', page);
console.log('  DONE views/skill-builders.html (fee ' + (fee ? '₹' + fee : 'hidden') + ', pilot banner ' + (pilot ? 'on' : 'off') + ')');

/* ---- helper ---- */
function edit(file, label, fn) {
  if (!fs.existsSync(P(file))) { console.log('  SKIP ' + file + ' (nahi mila)'); return; }
  const a = rd(file);
  const b = fn(a);
  if (b === null) { console.log('  OK   ' + file + ' (pehle se hai)'); return; }
  if (b === a)    { console.log('  WARN ' + file + ': ' + label + ' - marker nahi mila, manual add karna padega'); return; }
  wr(file, b); console.log('  DONE ' + file + ': ' + label);
}

/* ---- server.js : redirect-all se PEHLE ---- */
edit('server.js', 'route registered', s => {
  if (s.includes('routes/skillbuilders')) return null;
  const add = "/* 3c) SHAUNIX SKILL BUILDERS — school programs page (/skill-builders) */\napp.use('/', require('./routes/skillbuilders'));\n\n";
  if (/\/\* 4\) Redirect/.test(s)) return s.replace(/\/\* 4\) Redirect/, add + '/* 4) Redirect');
  const m = s.match(/app\.use\(\(req,\s*res\)\s*=>\s*res\.redirect\('\/'\)\);/);
  return m ? s.replace(m[0], add + m[0]) : s;
});

/* ---- seo.config.js ---- */
edit('seo.config.js', 'SEO entry added', s => {
  if (s.includes("'skill-builders.html'")) return null;
  const J = JSON.stringify;
  const entry =
`
  /* SHAUNIX SKILL BUILDERS — school programs page */
  'skill-builders.html': {
    title: ${J('School Skill Programs in Delhi NCR — Hands-on AI, Coding, PC & Electronics Workshops | SHAUNIX SKILL BUILDERS')},
    description: ${J('SHAUNIX SKILL BUILDERS brings a 7+3 day hands-on skill program to schools: AI, coding, PC hardware, electronics, green energy and cyber safety, with live student projects, showcase and participation certificates.')},
    keywords: ${J('school workshops Delhi, STEM program for schools, AI workshop for school students, coding classes for schools, robotics workshop schools Delhi, skill development program schools, SHAUNIX SKILL BUILDERS, school activity program Delhi NCR')},
    canonical: '/${SLUG}',
    schemaName: 'SHAUNIX SKILL BUILDERS'
  },
`;
  return s.replace(/const PAGES = \{\s*\n/, m => m + entry);
});

/* ---- sitemap ---- */
edit('public/sitemap.xml', 'URL added', s => {
  if (s.includes('/' + SLUG)) return null;
  return s.replace('</urlset>', `  <url><loc>https://shaunixgroup.com/${SLUG}</loc><priority>0.8</priority></url>\n</urlset>`);
});

/* ---- header dropdown ---- */
edit('views/partials/header.html', 'dropdown link added', s => {
  if (s.includes('href="/' + SLUG + '"')) return null;
  const re = /<li><a href="\/academy"><i class="dot dot-academy"><\/i>[\s\S]*?<\/a><\/li>/;
  const li = `\n          <li><a href="/${SLUG}"><i class="dot dot-academy"></i>SKILL BUILDERS<span>School Programs • STEM • AI</span></a></li>`;
  return re.test(s) ? s.replace(re, m => m + li) : s;
});

/* ---- footer ---- */
edit('views/partials/footer.html', 'footer links added', s => {
  if (s.includes('href="/' + SLUG + '"')) return null;
  let out = s;
  out = out.replace(/(<li><a href="\/academy">🎓 SHAUNIX ACADEMY<\/a><\/li>)/, `$1\n        <li><a href="/${SLUG}">🛠️ SKILL BUILDERS (Schools)</a></li>`);
  out = out.replace(/(<li><a href="\/academy">Courses &amp; Training<\/a><\/li>)/, `$1\n        <li><a href="/${SLUG}">School Programs</a></li>`);
  return out;
});

/* ---- academy page: "For Schools" strip + css ---- */
edit('views/services/academy.html', 'For Schools strip added', s => {
  if (s.includes('<!-- sb-promo -->')) return null;
  let out = s.replace('<link rel="stylesheet" href="/css/responsive.css">',
    '<link rel="stylesheet" href="/css/responsive.css">\n  <link rel="stylesheet" href="/css/skill-builders.css">');
  const promo = `  <!-- sb-promo -->
  <section class="section section-tight">
    <div class="container">
      <div class="sb-promo reveal">
        <div>
          <span class="eyebrow eyebrow-light">🏫 For Schools</span>
          <h2>Want hands-on skills in your school?</h2>
          <p>SHAUNIX SKILL BUILDERS runs a 7+3 day practical program in AI, coding, PC hardware, electronics and green energy, ending with a student project showcase.</p>
        </div>
        <a class="btn btn-primary" href="/${SLUG}">Explore SKILL BUILDERS ➜</a>
      </div>
    </div>
  </section>

`;
  return out.replace(/ {2}\{\{CONTACT_SECTION\}\}/, promo + '  {{CONTACT_SECTION}}');
});
EOF

# =====================================================================
# 5) SMOKE TEST (optional, sirf agar node_modules hai)
# =====================================================================
echo; line
if [ -d "$ROOT/node_modules" ]; then
  read -r -p "  Quick test chalau? (server temporarily port 3999 par) (y/n) [y]: " T; T="${T:-y}"
  if [[ "$T" =~ ^[Yy] ]]; then
    ( cd "$ROOT" && PORT=3999 node server.js >/dev/null 2>&1 & echo $! > "$BK/pid" )
    sleep 2
    CODE=$(curl -s -o "$BK/page.html" -w '%{http_code}' http://localhost:3999/skill-builders)
    SEOOK=$(grep -c 'SKILL BUILDERS' "$BK/page.html" 2>/dev/null)
    LEFT=$(grep -c '{{' "$BK/page.html" 2>/dev/null)
    kill "$(cat "$BK/pid")" 2>/dev/null
    echo "  /skill-builders -> HTTP $CODE | page par naam $SEOOK jagah | bachi hui {{tokens}}: $LEFT"
    [ "$CODE" = "200" ] && [ "$LEFT" = "0" ] && echo "  Test PASS" || echo "  Test mein dikkat, upar ke messages check karo"
  fi
else
  echo "  (node_modules nahi mila: pehle 'npm install' chalao)"
fi

echo; line
echo "  Ho gaya! Ab chalao:"
echo "     cd \"$ROOT\" && npm start"
echo "  Phir kholo:  http://localhost:3000/skill-builders"
echo "  Undo:        bash $BK/RESTORE.sh"
echo "  Deploy ke baad Google Search Console mein /skill-builders URL submit kar dena."
line
