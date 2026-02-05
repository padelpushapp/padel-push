// lib/features/utils/notification_state.dart
import 'package:flutter/material.dart';

class NotificationState {
  static final ValueNotifier<Map<String, dynamic>?> data =
      ValueNotifier(null);

  static void show(Map<String, dynamic> payload) {
    data.value = payload;
  }

  static void clear() {
    data.value = null;
  }
}
