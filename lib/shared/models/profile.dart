import 'enums.dart';
import 'json.dart';

/// Tabel `profiles`. `id` = `auth.users.id` = `auth.uid()`.
///
/// Baris dibuat otomatis trigger `on_auth_user_created` dari
/// `raw_user_meta_data` — aplikasi tidak perlu insert saat registrasi.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.role,
    required this.ecoPoints,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final UserRole role;
  final int ecoPoints;
  final String? avatarUrl;
  final DateTime createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: toStr(json['id']),
    name: toStr(json['name']),
    email: toStr(json['email']),
    phone: toStrOpsional(json['phone']),
    address: toStrOpsional(json['address']),
    role: UserRole.parse(json['role']),
    ecoPoints: toInt(json['eco_points']),
    avatarUrl: toStrOpsional(json['avatar_url']),
    createdAt: dtWajib(json['created_at']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'role': role.wire,
    'eco_points': ecoPoints,
    'avatar_url': avatarUrl,
  });

  Profile copyWith({
    String? name,
    String? phone,
    String? address,
    int? ecoPoints,
    String? avatarUrl,
  }) => Profile(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    role: role,
    ecoPoints: ecoPoints ?? this.ecoPoints,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt,
  );
}
