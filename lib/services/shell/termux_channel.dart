import 'package:flutter/services.dart';

/// Dart side of the Termux platform channel.
/// Native Android implementation: see android_native/MainActivity.kt
class TermuxChannel {
  static const _channel = MethodChannel('kitsune_byte/termux');

  static final TermuxChannel instance = TermuxChannel._();
  TermuxChannel._();

  /// Whether the com.termux package is installed.
  Future<bool> isTermuxInstalled() async {
    try {
      final v = await _channel.invokeMethod<bool>('isTermuxInstalled');
      return v ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Fire Termux RUN_COMMAND. Returns stdout-ish payload from native side
  /// when the plugin supports result capture; otherwise a status map.
  Future<Map<String, dynamic>> runCommand({
    required String executable,
    List<String> arguments = const [],
    String? workdir,
    bool background = true,
  }) async {
    try {
      final raw = await _channel.invokeMethod<Map>('runCommand', {
        'path': executable,
        'arguments': arguments,
        'workdir': workdir,
        'background': background,
      });
      return Map<String, dynamic>.from(raw ?? {});
    } on MissingPluginException {
      return {
        'ok': false,
        'error':
            'Termux channel not linked. Copy android_native/MainActivity.kt '
            'into your Flutter android host after `flutter create .`.',
      };
    } on PlatformException catch (e) {
      return {'ok': false, 'error': e.message ?? e.code};
    }
  }

  /// Convenience: run a shell one-liner via `/data/data/com.termux/files/usr/bin/bash -lc`
  Future<Map<String, dynamic>> runBash(String command, {String? workdir}) {
    return runCommand(
      executable: '/data/data/com.termux/files/usr/bin/bash',
      arguments: ['-lc', command],
      workdir: workdir,
      background: false,
    );
  }
}
