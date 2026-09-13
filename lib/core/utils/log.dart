import 'package:flutter/foundation.dart';

/// Debug-only logging. Unlike a bare `print`, this is gated on [kDebugMode]
/// so MQTT traffic (feed commands, schedule payloads, connection state)
/// never ships into a release build's console output.
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
