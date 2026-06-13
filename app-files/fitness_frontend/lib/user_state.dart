import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState {
  static final ValueNotifier<String> username = ValueNotifier<String>(
    'Fitness User',
  );

  static final ValueNotifier<String> emoji = ValueNotifier<String>('⚡');

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      username.value = prefs.getString('username') ?? 'Fitness User';
      emoji.value = prefs.getString('user_emoji') ?? '⚡';
    } catch (e) {
      // ignore errors
    }
  }
}
