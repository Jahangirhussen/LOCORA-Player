import 'package:flutter/foundation.dart';

/// Non-web platforms never have a browser install prompt.
class PwaInstall {
  static final ValueNotifier<bool> canInstall = ValueNotifier(false);
  static void listen() {}
  static Future<void> promptInstall() async {}
}
