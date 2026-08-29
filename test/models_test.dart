import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/shared/models/models.dart';

void main() {
  test('enum tak dikenal jatuh ke default, bukan crash', () {
    expect(UserRole.parse('merchant'), UserRole.merchant);
    expect(UserRole.parse('alien'), UserRole.consumer);
    expect(UserRole.parse(null), UserRole.consumer);

    expect(ListingStatus.parse('cascaded'), ListingStatus.cascaded);
    expect(ListingStatus.parse('sold_out'), ListingStatus.soldOut);
    expect(ListingStatus.parse('???'), ListingStatus.draft);

    expect(OrderStatus.parse('claimed'), OrderStatus.claimed);
    expect(OrderStatus.parse(42), OrderStatus.pending);

    expect(WasteStatus.parse('picked_up'), WasteStatus.pickedUp);
    expect(WasteStatus.parse(''), WasteStatus.available);

    expect(ForecastSource.parse('lstm_gemini'), ForecastSource.lstmGemini);
    expect(ForecastSource.parse('x'), ForecastSource.heuristic);

    expect(EsgEventType.parse('b2b_diverted'), EsgEventType.b2bDiverted);
    expect(WasteType.parse('dry'), WasteType.dry);
  });

  test('waste_preference array enum jadi List<WasteType>', () {
    expect(WasteType.parseList(['wet', 'dry']), [WasteType.wet, WasteType.dry]);
    expect(WasteType.parseList('{wet,dry}'), [WasteType.wet, WasteType.dry]);
    expect(WasteType.parseList('{}'), isEmpty);
    expect(WasteType.parseList(null), isEmpty);
  });

  test('Listing.fromJson membaca timestamptz ISO 8601', () {
    final l = Listing.fromJson({
      'id': 'l1',
      'merchant_id': 'm1',
      'name': 'Nasi Padang',
      'description': null,
      'category': 'nasi_lauk',
      'image_url': null,
      'qty_total': 10,
      'qty_remaining': 4,
      'original_price': 25000,
      'price': 12000,
      'cooked_at': '2026-08-29T03:00:00+00:00',
      'expires_at': '2026-08-29T11:00:00+00:00',
      'triage_score': 82,
      'triage_reason': 'aman',
      'physical_validated': true,
      'physical_validated_at': null,
      'status': 'live',
      'created_at': '2026-08-29T03:05:00+00:00',
    });
    expect(l.name, 'Nasi Padang');
    expect(l.qtyRemaining, 4);
    expect(l.price, 12000);
    expect(l.status, ListingStatus.live);
    expect(l.imageUrl, isNull);
    expect(l.cookedAt.isUtc, false);
    expect(l.cookedAt.toUtc().hour, 3);
    expect(l.discountPercent, closeTo(0.52, 0.001));
  });

  test('numeric yang datang sebagai String tetap terbaca', () {
    final l = Listing.fromJson({
      'id': 'l2',
      'merchant_id': 'm1',
      'name': 'Roti',
      'category': 'roti',
      'qty_total': '6',
      'qty_remaining': '2',
      'original_price': '15000.00',
      'price': '7500.00',
      'cooked_at': '2026-08-29T03:00:00Z',
      'expires_at': '2026-08-30T03:00:00Z',
      'physical_validated': 't',
      'status': 'live',
      'created_at': '2026-08-29T03:00:00Z',
    });
    expect(l.qtyRemaining, 2);
    expect(l.price, 7500);
    expect(l.physicalValidated, true);
  });

  test('Partner memetakan array enum dan langganan', () {
    final p = Partner.fromJson({
      'id': 'p1',
      'org_name': 'Maggot Jaya',
      'partner_type': 'maggot',
      'waste_preference': ['wet', 'dry'],
      'vehicle_type': 'pickup',
      'license_plate': 'B 1 XX',
      'service_radius_km': 10,
      'base_lat': -6.9,
      'base_lng': 107.6,
      'total_pickups': 3,
      'subscription_expiry': null,
    });
    expect(p.wastePreference, [WasteType.wet, WasteType.dry]);
    expect(p.serviceRadiusKm, 10);
    expect(p.subscriptionExpiry, isNull);
    expect(p.langgananAktif, false);
    expect(p.toJson()['waste_preference'], ['wet', 'dry']);
  });

  test('toJson membuang id dan bisa dibaca balik oleh fromJson', () {
    final now = DateTime.parse('2026-08-29T10:00:00Z').toLocal();
    final w = WasteBatch(
      id: 'w1',
      sourceMerchantId: 'm1',
      sourceListingId: null,
      wasteType: WasteType.wet,
      description: null,
      weightKg: 9.2,
      price: 5000,
      pickupAddress: 'Jl. Mawar',
      lat: -6.9,
      lng: 107.6,
      status: WasteStatus.available,
      createdAt: now,
    );
    final json = w.toJson();
    expect(json.containsKey('id'), false);
    expect(json.containsKey('source_listing_id'), false); // null dibuang
    expect(json['status'], 'available');
    expect(WasteBatch.fromJson({...json, 'id': 'w1'}).weightKg, 9.2);
    expect(w.dariKaskade, false);
  });

  test('kolom date tidak bergeser oleh zona waktu', () {
    final s = SalesHistory.fromJson({
      'id': 'h1',
      'merchant_id': 'm1',
      'date': '2026-08-29',
      'portions_sold': 72,
      'revenue': 720000,
      'day_of_week': 4,
      'is_holiday': false,
      'weather_code': 0,
      'surplus_kg': 2.4,
    });
    expect(s.date.year, 2026);
    expect(s.date.month, 8);
    expect(s.date.day, 29);
    expect(s.toJson()['date'], '2026-08-29');
    // 0 = Senin, bukan konvensi DateTime.weekday
    expect(SalesHistory.dayOfWeekDari(DateTime(2026, 8, 31)), 0);
  });

  test('Order menghitung QR valid hanya saat sudah dibayar', () {
    Order buat(OrderStatus status, DateTime? kedaluwarsa) => Order(
      id: 'o1',
      consumerId: 'c1',
      merchantId: 'm1',
      subtotal: 24000,
      greenFee: 1000,
      total: 25000,
      status: status,
      qrToken: 'tok',
      qrExpiresAt: kedaluwarsa,
      orderedAt: DateTime.now(),
    );
    final nanti = DateTime.now().add(const Duration(hours: 1));
    final tadi = DateTime.now().subtract(const Duration(hours: 1));

    expect(buat(OrderStatus.paid, nanti).qrValid, true);
    expect(buat(OrderStatus.paid, tadi).qrValid, false);
    expect(buat(OrderStatus.pending, nanti).qrValid, false);
    expect(buat(OrderStatus.claimed, nanti).qrValid, false);
  });

  test('Order membaca order_items bersarang', () {
    final o = Order.fromJson({
      'id': 'o1',
      'consumer_id': 'c1',
      'merchant_id': 'm1',
      'subtotal': 24000,
      'green_fee': 1000,
      'total': 25000,
      'status': 'paid',
      'ordered_at': '2026-08-29T03:00:00Z',
      'order_items': [
        {
          'id': 'i1',
          'order_id': 'o1',
          'listing_id': 'l1',
          'name_snapshot': 'Nasi Padang',
          'qty': 2,
          'unit_price': 12000,
        },
      ],
    });
    expect(o.items.length, 1);
    expect(o.totalPorsi, 2);
    expect(o.items.first.lineTotal, 24000);
  });

  test('Forecast jujur soal sumber dan tanggal', () {
    final f = Forecast.fromJson({
      'id': 'f1',
      'merchant_id': 'm1',
      'forecast_date': '2026-08-30',
      'demand_x': 55,
      'surplus_probability_y': 0.34,
      'surplus_volume_est_kg': 2.8,
      'recommended_production': 58,
      'confidence': 0.72,
      'narrative': 'Besok Jumat',
      'source': 'lstm_gemini',
      'created_at': '2026-08-29T03:00:00Z',
    });
    expect(f.source, ForecastSource.lstmGemini);
    expect(f.dariModel, true);
    expect(f.forecastDate.day, 30);
    expect(f.toJson()['forecast_date'], '2026-08-30');
  });

  test('NearbyListing dan NearbyWaste membaca jarak_km', () {
    final nl = NearbyListing.fromJson({
      'id': 'l1',
      'merchant_id': 'm1',
      'store_name': 'Verde Kitchen',
      'store_address': 'Jl. Anggrek',
      'store_image': null,
      'name': 'Croissant',
      'description': null,
      'category': 'roti',
      'image_url': null,
      'qty_remaining': 3,
      'original_price': 20000,
      'price': 8000,
      'cooked_at': '2026-08-29T01:00:00Z',
      'expires_at': '2026-08-30T01:00:00Z',
      'triage_score': 88,
      'triage_reason': null,
      'lat': -6.9,
      'lng': 107.6,
      'jarak_km': 1.06,
    });
    expect(nl.storeName, 'Verde Kitchen');
    expect(nl.jarakKm, 1.06);
    expect(nl.discountPercent, closeTo(0.6, 0.001));

    final nw = NearbyWaste.fromJson({
      'id': 'w1',
      'source_merchant_id': 'm1',
      'store_name': 'Verde Kitchen',
      'source_listing_id': 'l9',
      'waste_type': 'wet',
      'description': null,
      'weight_kg': 9.2,
      'price': 5000,
      'pickup_address': 'Jl. Anggrek',
      'lat': -6.9,
      'lng': 107.6,
      'pickup_window_start': null,
      'pickup_window_end': null,
      'image_url': null,
      'status': 'available',
      'created_at': '2026-08-29T01:00:00Z',
      'jarak_km': 0.765,
    });
    expect(nw.dariKaskade, true);
    expect(nw.jarakKm, 0.765);
  });

  test('EsgEvent hanya dibaca, tidak punya toJson', () {
    final e = EsgEvent.fromJson({
      'id': 'e1',
      'merchant_id': 'm1',
      'event_type': 'b2b_diverted',
      'ref_id': 'w1',
      'weight_kg': 9.2,
      'co2_saved_kg': 2.3,
      'revenue_recovered': 5000,
      'occurred_at': '2026-08-29T03:00:00Z',
    });
    expect(e.eventType, EsgEventType.b2bDiverted);
    expect(e.co2SavedKg, 2.3);
  });
}
