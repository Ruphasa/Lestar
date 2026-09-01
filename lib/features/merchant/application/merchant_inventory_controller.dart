import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_models.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/constants.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';

class TriageSubmission {
  const TriageSubmission({
    required this.name,
    required this.category,
    required this.quantity,
    required this.cookedAt,
    required this.originalPrice,
    required this.imageUrl,
    required this.triage,
  });

  final String name;
  final String category;
  final int quantity;
  final DateTime cookedAt;
  final double originalPrice;
  final String imageUrl;
  final TriageResult triage;

  bool get canPublishB2c =>
      triage.score >= LestarConstants.ambangTriageB2c && triage.keB2c;
}

final merchantListingsProvider = StreamProvider.family<List<Listing>, String>(
  (ref, merchantId) =>
      ref.watch(listingRepositoryProvider).merchantListings(merchantId),
);

final merchantWasteProvider = StreamProvider.family<List<WasteBatch>, String>(
  (ref, merchantId) =>
      ref.watch(wasteRepositoryProvider).merchantWaste(merchantId),
);

final merchantInventoryControllerProvider = Provider(
  (ref) => MerchantInventoryController(ref),
);

class MerchantInventoryController {
  MerchantInventoryController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<TriageSubmission> triage({
    required Merchant merchant,
    required String name,
    required String category,
    required int quantity,
    required DateTime cookedAt,
    required double originalPrice,
    required XFile image,
  }) async {
    final imageUrl = await _uploadPhoto(merchant.id, image);
    final elapsed = DateTime.now().difference(cookedAt);
    final hours = elapsed.isNegative ? 0.0 : elapsed.inMinutes / 60;
    final result = await _ref
        .read(lestarApiProvider)
        .triage(kategori: category, jamSejakMasak: hours, ambientTemp: 28);
    return TriageSubmission(
      name: name,
      category: category,
      quantity: quantity,
      cookedAt: cookedAt,
      originalPrice: originalPrice,
      imageUrl: imageUrl,
      triage: result,
    );
  }

  Future<Listing> validateAndPublish({
    required Merchant merchant,
    required TriageSubmission submission,
  }) async {
    if (!submission.canPublishB2c) {
      throw StateError(
        'Skor keamanan di bawah ambang B2C. Alihkan ke jalur B2B.',
      );
    }

    final shelfLife = LestarConstants.shelfLife(submission.category);
    final expiresAt = submission.cookedAt.add(Duration(hours: shelfLife));
    final remainingMinutes = expiresAt.difference(DateTime.now()).inMinutes;
    final pricing = await _ref
        .read(lestarApiProvider)
        .pricing(
          originalPrice: submission.originalPrice,
          jamTersisa: (remainingMinutes / 60)
              .clamp(0, shelfLife.toDouble())
              .toDouble(),
          jamTotal: shelfLife.toDouble(),
          qtyRemaining: submission.quantity,
          qtyTotal: submission.quantity,
        );

    final now = DateTime.now();
    final draft = Listing(
      id: '',
      merchantId: merchant.id,
      name: submission.name,
      description: submission.triage.reason,
      category: submission.category,
      imageUrl: submission.imageUrl,
      qtyTotal: submission.quantity,
      qtyRemaining: submission.quantity,
      originalPrice: submission.originalPrice,
      price: pricing.harga,
      cookedAt: submission.cookedAt,
      expiresAt: expiresAt,
      triageScore: submission.triage.score,
      triageReason: submission.triage.reason,
      physicalValidated: false,
      status: ListingStatus.draft,
      createdAt: now,
    );

    final savedDraft = await _ref
        .read(listingRepositoryProvider)
        .createListing(draft);
    return _ref.read(listingRepositoryProvider).validatePhysical(savedDraft.id);
  }

  Future<WasteBatch> routeToB2b({
    required Merchant merchant,
    required TriageSubmission submission,
  }) {
    if (submission.canPublishB2c) {
      throw StateError('Produk ini masih memenuhi ambang jalur B2C.');
    }
    final now = DateTime.now();
    final batch = WasteBatch(
      id: '',
      sourceMerchantId: merchant.id,
      wasteType: WasteType.wet,
      description:
          '${submission.name} · skor ${submission.triage.score}. '
          '${submission.triage.reason}',
      weightKg:
          submission.quantity * LestarConstants.beratPorsi(submission.category),
      price: 0,
      pickupAddress: merchant.storeAddress,
      lat: merchant.lat,
      lng: merchant.lng,
      pickupWindowStart: now,
      pickupWindowEnd: now.add(const Duration(hours: 2)),
      imageUrl: submission.imageUrl,
      status: WasteStatus.available,
      createdAt: now,
    );
    return _ref.read(wasteRepositoryProvider).createBatch(batch);
  }

  Future<Map<String, dynamic>> runDemoCascade(String merchantId) async {
    if (!LestarConstants.demoMode) {
      throw StateError('Pemicu kaskade hanya tersedia pada build demo.');
    }
    if (merchantId.trim().isEmpty) {
      throw StateError('Merchant belum teridentifikasi. Kaskade dibatalkan.');
    }
    // RPC langsung dicabut dari role authenticated oleh migration 0010.
    // Edge Function membawa JWT merchant, lalu memanggil RPC yang sama dengan
    // service role di server. Logika kaskadenya tetap satu sumber.
    final response = await supabase.functions.invoke(
      'auto_cascade',
      // Edge Function meneruskan nilai wajib ini sebagai p_merchant_id.
      body: {'force': true, 'merchant_id': merchantId},
    );
    final result = response.data;
    if (result is Map) return Map<String, dynamic>.from(result);
    return const {};
  }

  Future<String> _uploadPhoto(String merchantId, XFile image) async {
    final rawExtension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    final extension = RegExp(r'^[a-z0-9]{2,5}$').hasMatch(rawExtension)
        ? rawExtension
        : 'jpg';
    final objectPath = '$merchantId/${_uuid.v4()}.$extension';
    await supabase.storage
        .from('product-images')
        .upload(
          objectPath,
          File(image.path),
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: image.mimeType,
          ),
        );
    return supabase.storage.from('product-images').getPublicUrl(objectPath);
  }
}
