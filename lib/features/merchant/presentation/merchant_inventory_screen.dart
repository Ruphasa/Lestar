import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/supabase/session.dart';
import '../../../core/theme/dark_glass.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/merchant_inventory_controller.dart';
import 'widgets/merchant_inventory_widgets.dart';

class MerchantInventoryScreen extends ConsumerStatefulWidget {
  const MerchantInventoryScreen({super.key});

  @override
  ConsumerState<MerchantInventoryScreen> createState() =>
      _MerchantInventoryScreenState();
}

class _MerchantInventoryScreenState
    extends ConsumerState<MerchantInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '12');
  final _priceController = TextEditingController(text: '88000');

  String _category = 'roti';
  DateTime _cookedAt = DateTime.now().subtract(const Duration(hours: 8));
  XFile? _image;
  TriageSubmission? _submission;
  bool _showForm = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _qtyController.text = '12';
    _priceController.text = '88000';
    setState(() {
      _category = 'roti';
      _cookedAt = DateTime.now().subtract(const Duration(hours: 8));
      _image = null;
      _submission = null;
      _showForm = false;
      _busy = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked != null && mounted) setState(() => _image = picked);
  }

  Future<void> _pickCookedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_cookedAt),
      helpText: 'Jam makanan selesai dimasak',
    );
    if (picked == null) return;
    final now = DateTime.now();
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (candidate.isAfter(now)) {
      candidate = candidate.subtract(const Duration(days: 1));
    }
    setState(() => _cookedAt = candidate);
  }

  Future<void> _runTriage(Merchant merchant) async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      _showMessage('Foto makanan wajib ditambahkan sebelum triage.');
      return;
    }
    setState(() => _busy = true);
    try {
      final quantity = int.parse(_qtyController.text);
      final price = double.parse(
        _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      final result = await ref
          .read(merchantInventoryControllerProvider)
          .triage(
            merchant: merchant,
            name: _nameController.text.trim(),
            category: _category,
            quantity: quantity,
            cookedAt: _cookedAt,
            originalPrice: price,
            image: _image!,
          );
      if (mounted) setState(() => _submission = result);
    } catch (error) {
      if (mounted) _showMessage(pesanError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _validateAndPublish(Merchant merchant) async {
    final submission = _submission;
    if (submission == null) return;
    setState(() => _busy = true);
    try {
      final listing = await ref
          .read(merchantInventoryControllerProvider)
          .validateAndPublish(merchant: merchant, submission: submission);
      if (!mounted) return;
      _showMessage(
        '${listing.name} tayang di radar dengan harga '
        '${Fmt.rupiah(listing.price)}.',
      );
      _resetForm();
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Listing belum tayang. ${pesanError(error)} '
          'Data tetap aman sebagai draft bila sudah tersimpan.',
        );
        _resetForm();
      }
    } finally {
      if (mounted && _showForm) setState(() => _busy = false);
    }
  }

  Future<void> _routeToB2b(Merchant merchant) async {
    final submission = _submission;
    if (submission == null) return;
    setState(() => _busy = true);
    try {
      final batch = await ref
          .read(merchantInventoryControllerProvider)
          .routeToB2b(merchant: merchant, submission: submission);
      if (!mounted) return;
      _showMessage('${Fmt.kg(batch.weightKg)} dialihkan ke radar mitra B2B.');
      _resetForm();
    } catch (error) {
      if (mounted) _showMessage(pesanError(error));
    } finally {
      if (mounted && _showForm) setState(() => _busy = false);
    }
  }

  Future<void> _runCascade(Merchant merchant) async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(merchantInventoryControllerProvider)
          .runDemoCascade(merchant.id);
      if (!mounted) return;
      final cascaded = result['cascaded'] ?? 0;
      final batches = result['waste_batches_created'] ?? 0;
      final rawKg = result['total_kg'];
      final kg = rawKg is num ? rawKg : num.tryParse('$rawKg') ?? 0;
      _showMessage(
        'Kaskade selesai: $cascaded listing, $batches batch, ${Fmt.kg(kg)}.',
      );
    } catch (error) {
      if (mounted) _showMessage(pesanError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(currentMerchantProvider);
    return merchantAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Inventaris belum dapat dimuat',
        message: pesanError(error),
      ),
      data: (merchant) {
        if (merchant == null) {
          return const EmptyState(title: 'Akun merchant tidak ditemukan');
        }
        final listings = ref.watch(merchantListingsProvider(merchant.id));
        final waste = ref.watch(merchantWasteProvider(merchant.id));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            _InventoryHeader(
              showForm: _showForm,
              busy: _busy,
              onToggleForm: () => setState(() {
                _showForm = !_showForm;
                if (!_showForm) _submission = null;
              }),
              onCascade: LestarConstants.demoMode
                  ? () => _runCascade(merchant)
                  : null,
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: MediaQuery.maybeOf(context)?.disableAnimations ?? false
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              child: _showForm
                  ? _buildForm(merchant)
                  : _buildListings(listings, waste),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListings(
    AsyncValue<List<Listing>> listings,
    AsyncValue<List<WasteBatch>> waste,
  ) {
    if (listings.isLoading || waste.isLoading) {
      return const Padding(
        key: ValueKey('inventory-loading'),
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (listings.hasError) {
      return EmptyState(
        key: const ValueKey('inventory-error'),
        title: 'Daftar listing belum dapat dimuat',
        message: pesanError(listings.error!),
      );
    }
    return MerchantListingList(
      key: const ValueKey('inventory-list'),
      listings: listings.value ?? const [],
      waste: waste.value ?? const [],
    );
  }

  Widget _buildForm(Merchant merchant) => Form(
    key: _formKey,
    child: Column(
      key: const ValueKey('surplus-form'),
      children: [
        DarkGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Surplus',
                style: LestarType.judulKartu(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Foto dan data ini menjadi dasar triage keamanan pangan.',
                style: LestarType.body(
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.48),
                ),
              ),
              const SizedBox(height: 18),
              _PhotoPicker(
                image: _image,
                onCamera: _busy ? null : () => _pickImage(ImageSource.camera),
                onGallery: _busy ? null : () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_busy && _submission == null,
                decoration: const InputDecoration(
                  labelText: 'Nama makanan',
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama makanan wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in LestarConstants.kategoriListing)
                    DropdownMenuItem(
                      value: category,
                      child: Text(Fmt.kategori(category)),
                    ),
                ],
                onChanged: _busy || _submission != null
                    ? null
                    : (value) => setState(() => _category = value ?? 'lainnya'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      enabled: !_busy && _submission == null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        suffixText: 'pcs',
                      ),
                      validator: (value) {
                        final qty = int.tryParse(value ?? '');
                        return qty == null || qty <= 0
                            ? 'Jumlah harus lebih dari nol.'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      enabled: !_busy && _submission == null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Harga normal',
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        final price = double.tryParse(
                          (value ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
                        );
                        return price == null || price <= 0
                            ? 'Harga wajib lebih dari nol.'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _busy || _submission != null ? null : _pickCookedTime,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Selesai dimasak',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  child: Text(
                    '${Fmt.jam(_cookedAt)} · ${Fmt.sejak(_cookedAt)}',
                    style: LestarType.isi(color: Colors.white),
                  ),
                ),
              ),
              if (_submission == null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _runTriage(merchant),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: LestarTokens.emeraldDeep,
                      foregroundColor: Colors.white,
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.health_and_safety_outlined),
                    label: Text(
                      'Periksa keamanan pangan',
                      style: LestarType.display(size: 18, wght: 700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_submission != null) ...[
          const SizedBox(height: 14),
          FoodSafetyResultCard(
            submission: _submission!,
            busy: _busy,
            onValidate: () => _validateAndPublish(merchant),
            onRouteB2b: () => _routeToB2b(merchant),
          ),
        ],
      ],
    ),
  );
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({
    required this.showForm,
    required this.busy,
    required this.onToggleForm,
    required this.onCascade,
  });

  final bool showForm;
  final bool busy;
  final VoidCallback onToggleForm;
  final VoidCallback? onCascade;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory',
                  style: LestarType.judulLayar(color: Colors.white),
                ),
                Text(
                  'Surplus · keamanan · kaskade',
                  style: LestarType.isi(
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: busy ? null : onToggleForm,
            style: FilledButton.styleFrom(
              backgroundColor: showForm
                  ? DarkGlassTheme.tile
                  : LestarTokens.forest,
              foregroundColor: Colors.white,
            ),
            icon: Icon(showForm ? Icons.close : Icons.add),
            label: Text(showForm ? 'Tutup' : 'Surplus'),
          ),
        ],
      ),
      if (onCascade != null && !showForm) ...[
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: busy ? null : onCascade,
          style: OutlinedButton.styleFrom(
            foregroundColor: LestarTokens.orange,
            side: BorderSide(
              color: LestarTokens.orange.withValues(alpha: 0.45),
            ),
          ),
          icon: const Icon(Icons.alt_route),
          label: const Text('Picu kaskade demo untuk merchant ini'),
        ),
      ],
    ],
  );
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.image,
    required this.onCamera,
    required this.onGallery,
  });

  final XFile? image;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DarkGlassTheme.tile,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Column(
      children: [
        if (image == null)
          const SizedBox(
            height: 90,
            child: Center(
              child: Icon(
                Icons.add_a_photo_outlined,
                size: 34,
                color: LestarTokens.emerald,
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(image!.path),
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Ambil foto'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
