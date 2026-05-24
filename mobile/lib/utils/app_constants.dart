import 'package:flutter/material.dart';

class AppConstants {
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Image constraints
  static const int maxImageSizeMB = 10;
  static const int maxImageDimension = 2048;
  static const int imageQuality = 85;

  // Map settings
  static const double defaultLatitude = 42.8746;
  static const double defaultLongitude = 74.5698;
  static const double defaultZoom = 16.0;
  static const double minZoom = 14.0;
  static const double maxZoom = 19.0;
  static const int searchRadius = 2000; // meters

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheExpiry = Duration(minutes: 30);

  // Validation
  static const int minHintLength = 10;
  static const int maxHintLength = 200;

  // Points
  static const int photoPoints = 10;
  static const int hintPoints = 5;
  static const int codePoints = 15;

  // Status thresholds
  static const Map<String, int> statusThresholds = {
    'novice': 0,
    'helper': 51,
    'expert': 201,
    'master': 501,
  };

  // Status labels
  static const Map<String, String> statusLabels = {
    'novice': 'Новичок',
    'helper': 'Помощник',
    'expert': 'Эксперт',
    'master': 'Мастер',
  };

  // Status colors
  static const Map<String, Color> statusColors = {
    'novice': Color(0xFF8B95A8),
    'helper': Color(0xFF4A90E2),
    'expert': Color(0xFFFFB800),
    'master': Color(0xFFE91E63),
  };
}



