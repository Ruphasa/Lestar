export type SlideKind = 'title' | 'problem' | 'gap' | 'cascade' | 'demo' | 'architecture' | 'fallback' | 'three-ui' | 'business' | 'market' | 'roadmap' | 'closing';

export interface SlideSource { path: string; detail: string }
export interface SlideItem { value?: string; label: string; detail?: string }
export interface SlideSpec {
  number: number;
  kind: SlideKind;
  title: string;
  kicker?: string;
  body: readonly string[];
  items?: readonly SlideItem[];
  images?: readonly string[];
  sources: readonly SlideSource[];
}

export const slides = [
  { number: 1, kind: 'title', title: 'Setiap kilogram punya jalur nilai', kicker: 'Lestar', body: ['Tim Lestar Â· 2 September 2026'], sources: [{ path: 'assets/logo.png', detail: 'Logo Lestar' }] },
  { number: 2, kind: 'problem', title: 'Food waste Indonesia adalah kerugian ekonomi berskala nasional', body: [], items: [
    { value: '14,73 juta ton', label: 'sampah makanan per tahun' },
    { value: 'Rp213â€“551 triliun', label: 'kerugian ekonomi per tahun' },
    { value: '7,29%', label: 'kontribusi emisi gas rumah kaca' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Bab I Â§1.1' }] },
  { number: 3, kind: 'gap', title: 'Solusi yang ada berhenti sebelum seluruh nilai dipulihkan', body: [], items: [
    { label: 'Flash sale', detail: 'hanya B2C' },
    { label: 'Donasi', detail: 'bergantung relawan' },
    { label: 'Limbah', detail: 'pickup manual dan informal' },
    { label: 'Pricing', detail: 'subjektif' },
    { label: 'ESG', detail: 'manual atau tidak ada' },
    { label: 'Forecasting', detail: 'tidak tersedia' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Tabel 2.1.1' }] },
  { number: 4, kind: 'cascade', title: 'Lestar mencegah kerugian lalu memulihkan sisa nilainya', body: ['Prediksi permintaan','Surplus','Triage AI','Validasi fisik','Flash Sale B2C','Limbah Organik B2B','Laporan ESG'], sources: [
    { path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Â§2.3.1' },
    { path: 'docs/00-PRD.md', detail: 'Â§4' }
  ] },
  { number: 5, kind: 'demo', title: 'Sekarang lihat alurnya bekerja', body: ['DEMO', 'Pindah ke aplikasi Lestar di HP.'], sources: [{ path: 'docs/05-demo-script.md', detail: 'Â§5' }] },
  { number: 6, kind: 'architecture', title: 'Empat komponen menjaga jalur data tetap sederhana', body: [], items: [
    { label: 'Flutter APK', detail: 'tiga antarmuka aktor' },
    { label: 'Supabase', detail: 'data, auth, dan realtime' },
    { label: 'FastAPI @ Railway', detail: 'forecast dan triage' },
    { label: 'Landing @ Vercel', detail: 'unduh APK dan cerita produk' }
  ], sources: [{ path: 'docs/01-architecture.md', detail: 'Â§1' }] },
  { number: 7, kind: 'fallback', title: 'Sistem selalu mengaku dari mana angkanya berasal', body: ['forecasts.source mencatat asal setiap angka'], items: [
    { label: 'LSTM + Gemini', detail: 'lstm_gemini' },
    { label: 'LSTM saja', detail: 'lstm_only' },
    { label: 'Heuristik lokal', detail: 'heuristic' }
  ], sources: [
    { path: 'docs/01-architecture.md', detail: 'Â§6' },
    { path: 'docs/05-demo-script.md', detail: 'Â§6' }
  ] },
  { number: 8, kind: 'three-ui', title: 'Tiga dunia kerja membutuhkan tiga antarmuka berbeda', body: [
    'Konsumen mendapat pengalaman ringan dan menyenangkan.',
    'Merchant mendapat kokpit data.',
    'Pengepul mendapat antarmuka yang terbaca di bawah terik matahari dengan satu tangan.'
  ], images: ['/assets/screenshots/consumer.png','/assets/screenshots/merchant.png','/assets/screenshots/partner.png'], sources: [
    { path: 'docs/03-design-system.md', detail: 'Â§1.1' },
    { path: 'landing/assets/screenshots/consumer.png', detail: 'capture aplikasi asli' },
    { path: 'landing/assets/screenshots/merchant.png', detail: 'capture aplikasi asli' },
    { path: 'landing/assets/screenshots/partner.png', detail: 'capture aplikasi asli' }
  ] },
  { number: 9, kind: 'business', title: 'Tiga arus pendapatan membiayai ekosistem', body: [], items: [
    { label: 'Komisi transaksi B2C' },
    { label: 'Langganan mitra B2B' },
    { value: 'Rp1.000', label: 'green fee per transaksi' }
  ], sources: [
    { path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Tabel 2.2.1' },
    { path: 'docs/00-PRD.md', detail: 'Â§6.3' }
  ] },
  { number: 10, kind: 'market', title: 'Pasar awal cukup fokus untuk dimenangkan dan cukup besar untuk tumbuh', body: ['Panjang garis memakai skala log agar tiga besaran tetap terbaca.'], items: [
    { value: 'Rp960 miliar/tahun', label: 'TAM' },
    { value: 'Rp48 miliar/tahun', label: 'SAM' },
    { value: 'Rp480 juta/tahun', label: 'SOM' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Â§2.6' }] },
  { number: 11, kind: 'roadmap', title: 'Dua belas bulan membawa Lestar dari fondasi ke scaling', body: [], items: [
    { label: 'Fase 0 Â· Bulan 1â€“2', detail: 'Fondasi' },
    { label: 'Fase 1 Â· Bulan 3â€“4', detail: 'MVP + Data Foundation' },
    { label: 'Fase 2 Â· Bulan 5â€“6', detail: 'AI Integration' },
    { label: 'Fase 3 Â· Bulan 7â€“9', detail: 'Pilot Launch' },
    { label: 'Fase 4 Â· Bulan 10â€“12', detail: 'Scaling' }
  ], sources: [{ path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Tabel 2.7.1' }] },
  { number: 12, kind: 'closing', title: 'Dimulai dari Malang, dikembangkan menuju skala nasional.', kicker: 'Lestar', body: ['Setiap kilogram punya jalur nilai'], sources: [
    { path: 'LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md', detail: 'Â§2.7.2' },
    { path: 'assets/logo.png', detail: 'Logo Lestar' }
  ] }
] as const satisfies readonly SlideSpec[];
