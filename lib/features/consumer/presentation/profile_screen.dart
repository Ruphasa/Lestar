import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/repositories/providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/consumer_providers.dart';
import 'widgets/consumer_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final busy = ref.watch(consumerSignOutBusyProvider);
    return ConsumerBackdrop(
      child: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ConsumerErrorState(
          message: pesanError(error),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              title: 'Sesi berakhir',
              message: 'Silakan masuk kembali.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            children: [
              Text(
                'Profil',
                style: LestarType.judulLayar(color: LestarTokens.forest),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: LestarTokens.emeraldTint,
                      foregroundImage: data.avatarUrl?.trim().isNotEmpty == true
                          ? NetworkImage(data.avatarUrl!)
                          : null,
                      child: Text(
                        data.name.trim().isEmpty
                            ? '?'
                            : data.name.trim()[0].toUpperCase(),
                        style: LestarType.display(
                          size: 30,
                          wght: 750,
                          color: LestarTokens.forest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data.name,
                      textAlign: TextAlign.center,
                      style: LestarType.judulKartu(color: LestarTokens.inkSoft),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.email,
                      style: LestarType.label(color: LestarTokens.muted),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: LestarTokens.emeraldTint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.eco_outlined,
                            color: LestarTokens.emeraldDeep,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Eco Points',
                              style: LestarType.label(
                                color: LestarTokens.forest,
                              ),
                            ),
                          ),
                          Text(
                            Fmt.angka(data.ecoPoints),
                            style: LestarType.judulKartu(
                              color: LestarTokens.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.phone_outlined,
                      label: 'Telepon',
                      value: data.phone ?? 'Belum diisi',
                    ),
                    const Divider(height: 1),
                    _ProfileRow(
                      icon: Icons.location_on_outlined,
                      label: 'Alamat',
                      value: data.address ?? 'Belum diisi',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _signOut(context, ref),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final busy = ref.read(consumerSignOutBusyProvider.notifier);
    busy.setValue(true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(pesanError(error))));
      }
    } finally {
      busy.setValue(false);
    }
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Icon(icon, color: LestarTokens.emeraldDeep),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: LestarType.caption(color: LestarTokens.muted)),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LestarType.isi(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
