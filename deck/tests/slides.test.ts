import { describe, expect, test } from 'bun:test';
import { slides } from '../src/data/slides';

describe('slide narrative', () => {
  test('tepat 12 slide bernomor urut', () => {
    expect(slides).toHaveLength(12);
    expect(slides.map((slide) => slide.number)).toEqual([1,2,3,4,5,6,7,8,9,10,11,12]);
  });

  test('setiap slide punya sumber lokal yang eksplisit', () => {
    for (const slide of slides) {
      expect(slide.sources.length).toBeGreaterThan(0);
      expect(slide.sources.every((source) => source.path.length > 0 && source.detail.length > 0)).toBe(true);
    }
  });

  test('angka proposal dan fallback chain tidak berubah', () => {
    const copy = JSON.stringify(slides);
    for (const required of ['14,73 juta ton','Rp213–551 triliun','7,29%','Rp960 miliar/tahun','Rp48 miliar/tahun','Rp480 juta/tahun','Rp1.000','forecasts.source','lstm_gemini','lstm_only','heuristic']) {
      expect(copy).toContain(required);
    }
  });

  test('slide 8 memakai tiga screenshot asli', () => {
    const slide = slides[7];
    expect(slide.kind).toBe('three-ui');
    expect(slide.images).toEqual([
      '/assets/screenshots/consumer.png',
      '/assets/screenshots/merchant.png',
      '/assets/screenshots/partner.png'
    ]);
    expect(JSON.stringify(slide)).not.toContain('mockup.png');
  });
});
