// Lestar Landing Page - Lenis Smooth Scroll & Anime.js Micro-interactions
document.addEventListener('DOMContentLoaded', () => {
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // 1. Initialize Lenis Smooth Scrolling
  let lenis;
  if (!reduceMotion && typeof Lenis !== 'undefined') {
    lenis = new Lenis({
      duration: 1.1,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
      touchMultiplier: 1.5,
    });

    function raf(time) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }
    requestAnimationFrame(raf);

    // Smooth scroll for all internal hash anchors
    document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
      anchor.addEventListener('click', (e) => {
        const href = anchor.getAttribute('href');
        if (href && href !== '#') {
          const target = document.querySelector(href);
          if (target) {
            e.preventDefault();
            lenis.scrollTo(target, { offset: 0, duration: 1.2 });
          }
        }
      });
    });
  }

  // 2. Active Section Tracker for Floating Dot Navigation
  const navDots = document.querySelectorAll('.section-nav__dot');
  const sections = document.querySelectorAll('.section-page');

  if ('IntersectionObserver' in window) {
    const sectionObserver = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          const id = entry.target.id;
          navDots.forEach((dot) => {
            if (dot.getAttribute('data-section') === id) {
              dot.classList.add('is-active');
            } else {
              dot.classList.remove('is-active');
            }
          });

          // Trigger Anime.js entrance animation if available
          if (!reduceMotion && typeof anime !== 'undefined') {
            const cards = entry.target.querySelectorAll('.fact-card, .actor-arch-card, .cascade-stage, .impact-box');
            if (cards.length > 0 && !entry.target.dataset.animated) {
              entry.target.dataset.animated = 'true';
              anime({
                targets: cards,
                translateY: [24, 0],
                opacity: [0, 1],
                delay: anime.stagger(100, { start: 100 }),
                duration: 700,
                easing: 'easeOutCubic',
              });
            }
          }
        }
      }
    }, { threshold: 0.45 });

    sections.forEach((sec) => sectionObserver.observe(sec));
  }

  // 3. Anime.js Vine Drawing on Hero Load
  if (!reduceMotion && typeof anime !== 'undefined') {
    const vinePath = document.querySelector('.vine-draw-path');
    if (vinePath) {
      anime({
        targets: vinePath,
        strokeDashoffset: [anime.setDashoffset, 0],
        easing: 'easeInOutSine',
        duration: 1600,
        delay: 250,
      });
    }
  }
});
