import 'package:flutter/material.dart';

enum ResourceType {
  holyPoints,
  faithCoins,
  blessings,
  grace,
}

extension ResourceTypeX on ResourceType {
  String get displayName {
    switch (this) {
      case ResourceType.holyPoints:
        return 'Holy Points';
      case ResourceType.faithCoins:
        return 'Faith Coins';
      case ResourceType.blessings:
        return 'Blessings';
      case ResourceType.grace:
        return 'Grace';
    }
  }

  String get iconPath {
    switch (this) {
      case ResourceType.holyPoints:
        return 'assets/images/resources/holy_points.png';
      case ResourceType.faithCoins:
        return 'assets/images/resources/faith_coins.png';
      case ResourceType.blessings:
        return 'assets/images/resources/blessings.png';
      case ResourceType.grace:
        return 'assets/images/resources/grace.png';
    }
  }

  Color get color {
    switch (this) {
      case ResourceType.holyPoints:
        return const Color(0xFFFFD700); // Gold
      case ResourceType.faithCoins:
        return const Color(0xFFC0C0C0); // Silver
      case ResourceType.blessings:
        return const Color(0xFF87CEEB); // Sky blue
      case ResourceType.grace:
        return const Color(0xFF9B59B6); // Purple
    }
  }
}
