const NEXT_KEYS = new Set(['ArrowRight', 'ArrowDown', 'PageDown', ' ']);
const PREVIOUS_KEYS = new Set(['ArrowLeft', 'ArrowUp', 'PageUp']);

export function resolveTarget(key: string, current: number, total: number): number | null {
  if (NEXT_KEYS.has(key)) return Math.min(total - 1, current + 1);
  if (PREVIOUS_KEYS.has(key)) return Math.max(0, current - 1);
  if (key === 'Home') return 0;
  if (key === 'End') return total - 1;
  return null;
}

export function resolveSwipe(startX: number, endX: number, threshold = 48): -1 | 0 | 1 {
  const delta = endX - startX;
  return Math.abs(delta) < threshold ? 0 : delta < 0 ? 1 : -1;
}

export function resolveFullscreenControlState(isFullscreen: boolean) {
  return isFullscreen
    ? { pressed: 'true', label: 'Keluar dari layar penuh' }
    : { pressed: 'false', label: 'Buka layar penuh' };
}

export function createDeckController(root: HTMLElement) {
  const slides = [...root.querySelectorAll<HTMLElement>('[data-slide]')];
  const progress = document.querySelector<HTMLOutputElement>('[data-progress]');
  const announcer = document.querySelector<HTMLElement>('[data-announcer]');
  let activeIndex = Math.max(0, slides.findIndex((slide) => `#${slide.id}` === location.hash));
  let pointerStartX: number | null = null;
  let initialized = false;
  let frameLocked = false;

  const goTo = (target: number, updateHash = true) => {
    const nextIndex = Math.max(0, Math.min(slides.length - 1, target));
    if (initialized && (nextIndex === activeIndex || frameLocked)) return;
    activeIndex = nextIndex;
    initialized = true;
    frameLocked = true;
    requestAnimationFrame(() => { frameLocked = false; });
    slides.forEach((slide, index) => {
      if (index === activeIndex) slide.setAttribute('data-active', 'true');
      else slide.removeAttribute('data-active');
    });
    const active = slides[activeIndex];
    if (!active) return;
    progress && (progress.value = `${activeIndex + 1} / ${slides.length}`);
    const title = active.querySelector('h1,h2')?.textContent?.trim() ?? '';
    announcer && (announcer.textContent = `Slide ${activeIndex + 1}: ${title}`);
    if (updateHash) history.replaceState(null, '', `#${active.id}`);
  };

  const onKey = (event: KeyboardEvent) => {
    const targetElement = event.target as HTMLElement | null;
    if (targetElement?.matches('a[href],button,input,textarea,select,[contenteditable="true"]')) return;
    const target = resolveTarget(event.key, activeIndex, slides.length);
    if (target === null) return;
    event.preventDefault();
    goTo(target);
  };

  document.documentElement.classList.add('deck-enhanced');
  document.addEventListener('keydown', onKey);
  root.addEventListener('pointerdown', (event) => { pointerStartX = event.clientX; });
  root.addEventListener('pointerup', (event) => {
    if (pointerStartX === null) return;
    const direction = resolveSwipe(pointerStartX, event.clientX);
    pointerStartX = null;
    if (direction) goTo(activeIndex + direction);
  });
  const bindNavigationControl = (action: 'previous' | 'next', direction: -1 | 1) => {
    const control = document.querySelector<HTMLElement>(`[data-action="${action}"]`);
    control?.addEventListener('click', () => goTo(activeIndex + direction));
    control?.addEventListener('keydown', (event) => {
      if (event.key !== ' ') return;
      event.preventDefault();
      goTo(activeIndex + direction);
    });
  };
  bindNavigationControl('previous', -1);
  bindNavigationControl('next', 1);
  const fullscreenControl = document.querySelector<HTMLElement>('[data-action="fullscreen"]');
  const syncFullscreenControl = () => {
    const state = resolveFullscreenControlState(Boolean(document.fullscreenElement));
    fullscreenControl?.setAttribute('aria-pressed', state.pressed);
    fullscreenControl?.setAttribute('aria-label', state.label);
  };
  syncFullscreenControl();
  document.addEventListener('fullscreenchange', syncFullscreenControl);
  fullscreenControl?.addEventListener('click', async () => {
    if (!document.fullscreenElement) await document.documentElement.requestFullscreen?.();
    else await document.exitFullscreen?.();
  });
  window.addEventListener('hashchange', () => {
    const index = slides.findIndex((slide) => `#${slide.id}` === location.hash);
    if (index >= 0) goTo(index, false);
  });
  goTo(activeIndex, false);
  return { goTo, get activeIndex() { return activeIndex; } };
}

if (typeof document !== 'undefined') {
  const root = document.querySelector<HTMLElement>('[data-deck]');
  if (root) createDeckController(root);
}
