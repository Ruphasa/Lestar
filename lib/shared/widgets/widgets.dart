/// Widget bersama Lestar — kerangka.
///
/// ```dart
/// import 'package:lestar/shared/widgets/widgets.dart';
/// ```
///
/// **Tanda tangan setiap widget di sini dikunci.** D, E, dan F memperkaya
/// tampilannya (lewat tema masing-masing atau isi `build`), tapi tidak
/// menambah, menghapus, atau mengubah tipe parameter — kalau berubah, dua
/// agent lain ikut rusak tanpa tahu sebabnya.
///
/// Empat belas widget:
/// `GlassCard` · `DarkGlassCard` · `PlainCard` · `BigButton` · `StatTile` ·
/// `SourceBadge` · `DiscountPill` · `PriceText` · `CountdownChip` ·
/// `LestarMap` · `QrDisplay` · `QrScanner` · `EmptyState` · `OfflineBanner`
library;

export 'badges.dart';
export 'big_button.dart';
export 'cards.dart';
export 'lestar_map.dart';
export 'qr_widgets.dart';
export 'states.dart';
export 'stat_tile.dart';
