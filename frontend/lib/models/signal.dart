import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SignalType { sell, housing, event, community, help }

extension SignalTypeX on SignalType {
  String get wire => name; // 'sell' | 'housing' | 'event' | 'community' | 'help'

  String get label {
    switch (this) {
      case SignalType.sell:
        return 'Sell';
      case SignalType.housing:
        return 'Housing';
      case SignalType.event:
        return 'Event';
      case SignalType.community:
        return 'Community';
      case SignalType.help:
        return 'Help';
    }
  }

  IconData get icon {
    switch (this) {
      case SignalType.sell:
        return Icons.sell_outlined;
      case SignalType.housing:
        return Icons.home_outlined;
      case SignalType.event:
        return Icons.event_outlined;
      case SignalType.community:
        return Icons.groups_outlined;
      case SignalType.help:
        return Icons.volunteer_activism_outlined;
    }
  }

  Color get color {
    switch (this) {
      case SignalType.sell:
        return ZoneColors.sell;
      case SignalType.housing:
        return ZoneColors.housing;
      case SignalType.event:
        return ZoneColors.event;
      case SignalType.community:
        return ZoneColors.community;
      case SignalType.help:
        return ZoneColors.help;
    }
  }

  /// Pale background tint used behind the icon on cards and chips.
  Color get tint {
    switch (this) {
      case SignalType.sell:
        return ZoneColors.sellTint;
      case SignalType.housing:
        return ZoneColors.housingTint;
      case SignalType.event:
        return ZoneColors.eventTint;
      case SignalType.community:
        return ZoneColors.communityTint;
      case SignalType.help:
        return ZoneColors.helpTint;
    }
  }

  static SignalType fromWire(String s) =>
      SignalType.values.firstWhere((t) => t.name == s,
          orElse: () => SignalType.sell);
}

class Signal {
  final String id;
  final String posterId;
  final String message;
  final SignalType type;
  final int radiusMeters;
  final double lat;
  final double lng;
  final String status;
  final DateTime expiresAt;
  final int? distanceMeters;

  const Signal({
    required this.id,
    required this.posterId,
    required this.message,
    required this.type,
    required this.radiusMeters,
    required this.lat,
    required this.lng,
    required this.status,
    required this.expiresAt,
    this.distanceMeters,
  });

  factory Signal.fromJson(Map<String, dynamic> j) {
    final loc = j['location'] as Map<String, dynamic>?;
    return Signal(
      id: j['id'] as String,
      posterId: j['posterId'] as String? ?? '',
      message: j['message'] as String? ?? '',
      type: SignalTypeX.fromWire(j['type'] as String? ?? 'ride'),
      radiusMeters: (j['radiusMeters'] as num?)?.toInt() ?? 500,
      lat: (loc?['lat'] ?? j['lat'] as num).toDouble(),
      lng: (loc?['lng'] ?? j['lng'] as num).toDouble(),
      status: j['status'] as String? ?? 'active',
      expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      distanceMeters: (j['distanceMeters'] as num?)?.toInt(),
    );
  }
}

enum VerificationTier { none, phone, kyc }

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final double rating;
  final VerificationTier verification;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.rating,
    required this.verification,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Zone user',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        rating: (j['rating'] as num?)?.toDouble() ?? 5.0,
        verification: VerificationTier.values.firstWhere(
          (v) => v.name == (j['verification'] as String? ?? 'phone'),
          orElse: () => VerificationTier.phone,
        ),
      );
}
