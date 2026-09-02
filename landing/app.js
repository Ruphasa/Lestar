const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

if (!reduceMotion && 'IntersectionObserver' in window) {
  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    }
  }, { threshold: 0.18 });

  document.querySelectorAll('[data-reveal]').forEach((node) => observer.observe(node));
} else {
  document.querySelectorAll('[data-reveal]').forEach((node) => node.classList.add('is-visible'));
}
