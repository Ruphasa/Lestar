import { describe, expect, test } from 'bun:test';
import { resolveSwipe, resolveTarget } from '../src/scripts/deck-controller';

describe('deck navigation', () => {
  test('key navigation terikat pada bounds', () => {
    expect(resolveTarget('ArrowRight', 0, 12)).toBe(1);
    expect(resolveTarget('ArrowLeft', 0, 12)).toBe(0);
    expect(resolveTarget('End', 2, 12)).toBe(11);
    expect(resolveTarget('Home', 9, 12)).toBe(0);
    expect(resolveTarget('x', 4, 12)).toBeNull();
  });

  test('swipe butuh threshold 48px', () => {
    expect(resolveSwipe(200, 130)).toBe(1);
    expect(resolveSwipe(130, 200)).toBe(-1);
    expect(resolveSwipe(130, 160)).toBe(0);
  });
});
