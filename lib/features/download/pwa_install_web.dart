import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Wraps the browser's native `beforeinstallprompt` PWA install flow so the
/// Download page can offer a real "Install App" button instead of only
/// linking out to GitHub Releases.
class PwaInstall {
  static final ValueNotifier<bool> canInstall = ValueNotifier(false);
  static JSObject? _deferredEvent;
  static bool _listening = false;

  static void listen() {
    if (_listening) return;
    _listening = true;
    web.window.addEventListener(
      'beforeinstallprompt',
      (web.Event event) {
        event.preventDefault();
        _deferredEvent = event as JSObject;
        canInstall.value = true;
      }.toJS,
    );
  }

  static Future<void> promptInstall() async {
    final ev = _deferredEvent;
    if (ev == null) return;
    ev.callMethod('prompt'.toJS);
    _deferredEvent = null;
    canInstall.value = false;
  }
}
