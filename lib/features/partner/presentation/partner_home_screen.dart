import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/supabase/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';
import '../../../shared/widgets/lestar_map.dart';
import '../application/partner_dashboard_controller.dart';
import 'widgets/partner_plain_widgets.dart';

class PartnerHomeScreen extends ConsumerStatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  ConsumerState<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends ConsumerState<PartnerHomeScreen> {
  List<NearbyWaste> _journey = const [];
  int _destinationIndex = 0;
  WasteStatus _journeyStatus = WasteStatus.matched;
  NearbyWaste? _focusedWaste;
  bool _showMap = false;
  bool _busy = false;

  Future<void> _pickup(List<NearbyWaste> rows, Partner partner) async {
    if (rows.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final repository = ref.read(wasteRepositoryProvider);
      for (final row in rows) {
        await repository.matchPartner(row.id, partner.id);
      }
      if (!mounted) return;
      setState(() {
        _journey = List.unmodifiable(rows);
        _destinationIndex = 0;
        _journeyStatus = WasteStatus.matched;
        _showMap = false;
        _focusedWaste = null;
      });
      _message('${rows.length} TITIK PENJEMPUTAN SUDAH DIAMBIL.');
    } catch (error) {
      if (mounted) _message(pesanError(error).toUpperCase());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advanceJourney() async {
    if (_journey.isEmpty || _busy) return;
    setState(() => _busy = true);
    final current = _journey[_destinationIndex];
    try {
      final repository = ref.read(wasteRepositoryProvider);
      if (_journeyStatus == WasteStatus.matched) {
        await repository.updateStatus(current.id, WasteStatus.pickedUp);
        if (mounted) setState(() => _journeyStatus = WasteStatus.pickedUp);
      } else {
        await repository.updateStatus(current.id, WasteStatus.completed);
        if (!mounted) return;
        if (_destinationIndex + 1 < _journey.length) {
          setState(() {
            _destinationIndex += 1;
            _journeyStatus = WasteStatus.matched;
          });
          _message('LANJUT KE TITIK BERIKUTNYA.');
        } else {
          setState(() {
            _journey = const [];
            _destinationIndex = 0;
            _journeyStatus = WasteStatus.matched;
          });
          _message('SEMUA PENJEMPUTAN SELESAI.');
        }
      }
    } catch (error) {
      if (mounted) _message(pesanError(error).toUpperCase());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final partnerAsync = ref.watch(currentPartnerProvider);
    if (profileAsync.isLoading || partnerAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profileAsync.hasError || partnerAsync.hasError) {
      return PartnerLoadError(
        message: pesanError(profileAsync.error ?? partnerAsync.error!),
      );
    }
    final partner = partnerAsync.value;
    if (partner == null) {
      return const PartnerLoadError(message: 'AKUN PENGEPUL TIDAK DITEMUKAN.');
    }

    if (_journey.isNotEmpty) {
      final destination = _journey[_destinationIndex];
      if (_showMap) {
        return PartnerWasteMapView(
          center: LatLng(destination.lat, destination.lng),
          waste: [destination],
          onBack: () => setState(() => _showMap = false),
          onSelect: (_) => setState(() => _showMap = false),
        );
      }
      return PartnerJourneyView(
        destination: destination,
        status: _journeyStatus,
        busy: _busy,
        onOpenMap: () => setState(() => _showMap = true),
        onAdvance: _advanceJourney,
      );
    }

    final nearbyAsync = ref.watch(partnerNearbyWasteProvider(partner));
    final rows = nearbyAsync.value ?? const <NearbyWaste>[];
    if (_showMap) {
      return PartnerWasteMapView(
        center: LatLng(partner.baseLat, partner.baseLng),
        waste: rows,
        onBack: () => setState(() => _showMap = false),
        onSelect: (row) => setState(() {
          _focusedWaste = row;
          _showMap = false;
        }),
      );
    }
    if (nearbyAsync.isLoading && nearbyAsync.value == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (nearbyAsync.hasError && nearbyAsync.value == null) {
      return PartnerLoadError(message: pesanError(nearbyAsync.error!));
    }
    final shownRows = _focusedWaste == null
        ? rows
        : rows.where((row) => row.id == _focusedWaste!.id).toList();
    if (shownRows.isEmpty) {
      return PartnerEmptyView(onShowMap: () => setState(() => _showMap = true));
    }
    return PartnerAvailableView(
      name: profileAsync.value?.name ?? 'Pak Budi',
      waste: shownRows,
      busy: _busy,
      onShowMap: () => setState(() => _showMap = true),
      onPickup: () => _pickup(shownRows, partner),
    );
  }
}

class PartnerAvailableView extends StatelessWidget {
  const PartnerAvailableView({
    super.key,
    required this.name,
    required this.waste,
    required this.onPickup,
    this.onShowMap,
    this.busy = false,
  });

  final String name;
  final List<NearbyWaste> waste;
  final VoidCallback onPickup;
  final VoidCallback? onShowMap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final totalKg = waste.fold<double>(0, (sum, row) => sum + row.weightKg);
    final nearest = waste.reduce(
      (current, row) => row.jarakKm < current.jarakKm ? row : current,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Text(
          'Halo, $name',
          style: LestarType.display(
            size: 24,
            wght: 700,
            color: LestarTokens.muted,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: InkWell(
            onTap: onShowMap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: LestarTokens.surfaceGrey,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 30,
                    color: LestarTokens.emerald,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DESA SUKAMAJU',
                    style: LestarType.display(
                      size: 20,
                      wght: 700,
                      color: LestarTokens.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'ADA SAMPAH\nORGANIK',
          textAlign: TextAlign.center,
          style: LestarType.display(
            size: 40,
            wght: 600,
            height: 1.25,
            color: LestarTokens.muted,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'TERSEDIA',
          textAlign: TextAlign.center,
          style: LestarType.judulPengepul(color: LestarTokens.ink),
        ),
        Text(
          _weight(totalKg),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: LestarType.angkaRaksasa(color: LestarTokens.emeraldDeep),
        ),
        const SizedBox(height: 14),
        Text(
          'JARAK ${Fmt.jarak(nearest.jarakKm).toUpperCase()} DARI RUMAH',
          textAlign: TextAlign.center,
          style: LestarType.display(
            size: 22,
            wght: 700,
            color: LestarTokens.muted,
          ),
        ),
        const SizedBox(height: 24),
        PartnerPrimaryButton(
          label: 'JEMPUT\nSEKARANG',
          icon: Icons.local_shipping_outlined,
          loading: busy,
          onPressed: onPickup,
        ),
      ],
    );
  }
}

class PartnerJourneyView extends StatelessWidget {
  const PartnerJourneyView({
    super.key,
    required this.destination,
    required this.status,
    required this.onOpenMap,
    required this.onAdvance,
    this.busy = false,
  });

  final NearbyWaste destination;
  final WasteStatus status;
  final VoidCallback onOpenMap;
  final VoidCallback onAdvance;
  final bool busy;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
    children: [
      Text(
        status == WasteStatus.pickedUp
            ? 'BARANG SUDAH DIAMBIL'
            : 'SEDANG MENUJU',
        textAlign: TextAlign.center,
        style: LestarType.display(size: 32, wght: 800, color: LestarTokens.ink),
      ),
      const SizedBox(height: 54),
      Text(
        destination.storeName,
        textAlign: TextAlign.center,
        style: LestarType.display(size: 34, wght: 800, color: LestarTokens.ink),
      ),
      const SizedBox(height: 12),
      Text(
        destination.pickupAddress,
        textAlign: TextAlign.center,
        style: LestarType.body(size: 20, wght: 600, color: LestarTokens.muted),
      ),
      const SizedBox(height: 38),
      Text(
        Fmt.jarak(destination.jarakKm).toUpperCase(),
        textAlign: TextAlign.center,
        style: LestarType.angkaRaksasa(color: LestarTokens.emeraldDeep),
      ),
      const SizedBox(height: 36),
      PartnerOutlineButton(
        label: 'BUKA PETA',
        icon: Icons.map_outlined,
        onPressed: onOpenMap,
      ),
      const SizedBox(height: 20),
      PartnerPrimaryButton(
        label: status == WasteStatus.pickedUp ? 'SELESAI' : 'SUDAH SAMPAI',
        icon: status == WasteStatus.pickedUp
            ? Icons.check_circle_outline
            : Icons.location_on_outlined,
        loading: busy,
        onPressed: onAdvance,
      ),
    ],
  );
}

class PartnerEmptyView extends StatelessWidget {
  const PartnerEmptyView({super.key, required this.onShowMap});

  final VoidCallback onShowMap;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco_outlined, size: 72, color: LestarTokens.emerald),
          const SizedBox(height: 24),
          Text(
            'BELUM ADA\nSAMPAH HARI INI',
            textAlign: TextAlign.center,
            style: LestarType.display(
              size: 36,
              wght: 800,
              height: 1.2,
              color: LestarTokens.ink,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'KAMI KABARI KALAU ADA',
            textAlign: TextAlign.center,
            style: LestarType.body(
              size: 18,
              wght: 600,
              color: LestarTokens.ink,
            ),
          ),
          const SizedBox(height: 42),
          PartnerOutlineButton(
            label: 'LIHAT PETA SEKITAR',
            icon: Icons.map_outlined,
            onPressed: onShowMap,
          ),
        ],
      ),
    ),
  );
}

class PartnerWasteMapView extends StatelessWidget {
  const PartnerWasteMapView({
    super.key,
    required this.center,
    required this.waste,
    required this.onBack,
    required this.onSelect,
  });

  final LatLng center;
  final List<NearbyWaste> waste;
  final VoidCallback onBack;
  final ValueChanged<NearbyWaste> onSelect;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.82,
          0.10,
          0.08,
          0,
          0,
          0.10,
          0.82,
          0.08,
          0,
          0,
          0.10,
          0.10,
          0.80,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: LestarMap(
          center: center,
          showUser: true,
          markers: [
            for (final row in waste)
              LestarMapMarker(
                point: LatLng(row.lat, row.lng),
                payload: row,
                width: 92,
                height: 92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.white,
                      child: Text(
                        _weight(row.weightKg),
                        style: LestarType.display(
                          size: 16,
                          wght: 800,
                          color: LestarTokens.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 54,
                      color: LestarTokens.emeraldDeep,
                    ),
                  ],
                ),
              ),
          ],
          onMarkerTap: (marker) {
            final payload = marker.payload;
            if (payload is NearbyWaste) onSelect(payload);
          },
        ),
      ),
      Positioned(
        left: 16,
        top: 16,
        child: SizedBox.square(
          dimension: 64,
          child: FilledButton(
            onPressed: onBack,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              foregroundColor: LestarTokens.ink,
              shape: const RoundedRectangleBorder(),
            ),
            child: const Icon(Icons.arrow_back, size: 34),
          ),
        ),
      ),
    ],
  );
}

class PartnerLoadError extends StatelessWidget {
  const PartnerLoadError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        message.toUpperCase(),
        textAlign: TextAlign.center,
        style: LestarType.display(size: 24, wght: 700, color: LestarTokens.ink),
      ),
    ),
  );
}

String _weight(double value) {
  final rounded = value.roundToDouble();
  final number = (value - rounded).abs() < 0.05
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return '$number KG';
}
