# Holdor - Lessons Learned

(Updated as we go)

## Website Standards
- Accessibility (ARIA), SEO, and GEO are important for the landing page — always include from the start
- Every page must have: semantic HTML, ARIA landmarks, skip links, focus-visible styles, prefers-reduced-motion, structured data, Open Graph/Twitter meta, canonical URLs
- Optimize for Lighthouse score: performance, accessibility, best practices, SEO all near 100
- Mobile optimization is important: use multiple breakpoints (tablet 768px, mobile 480px), ensure 44px min touch targets, full-width CTAs on mobile, proper font scaling

## SEO / GEO / Page Speed Checklist (ALWAYS apply)
- **Fonts**: Load via `<link>` tags in HTML, never `@import` in CSS (render-blocking). Use `display=swap`.
- **hreflang**: Always include `<link rel="alternate" hreflang="en">` and `hreflang="x-default"`
- **Sitemap**: Always include `<lastmod>` date, update on every deploy
- **OG image**: Every page needs an Open Graph image for social sharing previews
- **Structured data**: Include `sameAs` for entity recognition (GitHub, LinkedIn). Add `FAQPage` schema for common questions — LLMs and search engines both use these.
- **llms.txt**: Keep in sync with app features. Include FAQ section for GEO. Update on every feature change.
- **WCAG contrast**: Body text on dark backgrounds needs minimum 4.5:1 ratio. Always verify muted text colors — `#706e68` on `#0b0b0f` FAILS (3.6:1), use `#918f88` or lighter (5.7:1).

## Website Design Direction — "Raw Control Room"
- **Aesthetic**: Industrial / control room / utilitarian — NOT generic AI/tech startup
- **Typography**: Bebas Neue (headlines, monumental stencil), IBM Plex Mono (body, everything else reads like a terminal)
- **Colors**: Near-black bg (#0b0b0f), warm amber accent (#e59500), green (#22c55e) ONLY for active/running status, red for warnings, warm off-white text (#e0ddd5), warm gray muted (#918f88 — WCAG AA compliant)
- **Visual language**: Sharp rectangles (no border-radius), thin ruled lines as dividers, dot-grid background, subtle noise grain overlay. NO section labels (removed SYS/ALERT/PROTOCOL/SPECS — too noisy)
- **Motion**: Scroll-triggered reveals (IntersectionObserver), staggered grid children, pulsing LED indicators, animated door in hero
- **Layout**: Left-aligned hero (not centered), data-table-style grids with 1px gap, generous vertical spacing between sections
- **The unforgettable thing**: CSS-animated door that opens/closes in the hero
- **Separators**: Use em dashes (&mdash;) instead of "//" or dots or pipes. Keep it clean and simple.
- **z-index lesson**: Fixed overlays (grain, dot-grid) must use z-index: -1 to avoid blocking clicks. Header needs higher z-index than main since later DOM elements paint on top at equal z-index
