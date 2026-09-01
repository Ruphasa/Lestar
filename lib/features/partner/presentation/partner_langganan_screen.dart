import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';
import 'partner_home_screen.dart';
import 'widgets/partner_plain_widgets.dart';

class PartnerLanggananScreen extends ConsumerStatefulWidget {
  const PartnerLanggananScreen({super.key});

  @override
  ConsumerState<PartnerLanggananScreen> createState() =>
      _PartnerLanggananScreenState();
}

class _PartnerLanggananScreenState
    extends ConsumerState<PartnerLanggananScreen> {
  bool _busy = false;

  Future<void> _extend(Partner partner) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final base = partner.subscriptionExpiry?.isAfter(now) ?? false
          ? partner.subscriptionExpiry!
          : now;
      await ref.read(profileRepositoryProvider).updatePartner(partner.id, {
        'subscription_expiry': base
            .add(const Duration(days: 30))
            .toUtc()
            .toIso8601String(),
      });
      ref.invalidate(currentPartnerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LANGGANAN DIPERPANJANG 30 HARI.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanError(error).toUpperCase())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerAsync = ref.watch(currentPartnerProvider);
    return partnerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => PartnerLoadError(message: pesanError(error)),
      data: (partner) => partner == null
          ? const PartnerLoadError(message: 'AKUN PENGEPUL TIDAK DITEMUKAN.')
          : PartnerSubscriptionView(
              partner: partner,
              busy: _busy,
              onExtend: () => _extend(partner),
            ),
    );
  }
}

class PartnerSubscriptionView extends StatelessWidget {
  const PartnerSubscriptionView({
    super.key,
    required this.partner,
    required this.busy,
    required this.onExtend,
  });

  final Partner partner;
  final bool busy;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final expiry = partner.subscriptionExpiry;
    final active = partner.langgananAktif;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        const PartnerScreenTitle('STATUS LANGGANAN'),
        const SizedBox(height: 34),
        PartnerSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Icon(
                active ? Icons.verified_outlined : Icons.error_outline,
                size: 76,
                color: active ? LestarTokens.emeraldDeep : LestarTokens.orange,
              ),
              const SizedBox(height: 20),
              Text(
                active ? 'LANGGANAN AKTIF' : 'LANGGANAN TIDAK AKTIF',
                textAlign: TextAlign.center,
                style: LestarType.display(
                  size: 30,
                  wght: 800,
                  color: LestarTokens.ink,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                expiry == null
                    ? 'BELUM ADA TANGGAL BERAKHIR'
                    : 'BERAKHIR ${Fmt.tanggalPanjang(expiry).toUpperCase()}',
                textAlign: TextAlign.center,
                style: LestarType.body(
                  size: 17,
                  wght: 600,
                  color: LestarTokens.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        PartnerPrimaryButton(
          label: 'PERPANJANG 30 HARI',
          icon: Icons.autorenew,
          loading: busy,
          onPressed: onExtend,
        ),
      ],
    );
  }
}
