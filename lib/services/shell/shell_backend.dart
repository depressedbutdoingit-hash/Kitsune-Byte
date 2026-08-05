import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result of a single shell invocation.
class ShellResult {
  final String command;
  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;
  final String backend;

  const ShellResult({
    required this.command,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
    required this.backend,
  });

  bool get ok => exitCode == 0;

  String get combined {
    final out = stdout.trim();
    final err = stderr.trim();
    if (out.isEmpty && err.isEmpty) return '(no output, exit $exitCode)';
    if (err.isEmpty) return out;
    if (out.isEmpty) return err;
    return '$out\n$err';
  }
}

/// Pluggable backends so the terminal can run on:
/// - pure Flutter (simulated / project-scoped virtual FS)
/// - Termux via RUN_COMMAND intent (Android)
/// - proot-distro Linux userspace inside Termux
/// - local HTTP bridge (python/node helper on device)
abstract class ShellBackend {
  String get name;
  Future<bool> isAvailable();
  Future<ShellResult> run(String command, {String? workingDirectory});

  /// Progressive stdout/stderr chunks for live tool cards.
  /// Default: run once, then yield the full combined output.
  Stream<String> runStream(String command, {String? workingDirectory}) async* {
    final result = await run(command, workingDirectory: workingDirectory);
    if (result.combined.isNotEmpty) yield result.combined;
  }
}

/// Always-available fallback: no real OS process, useful for UI + AI demos.
class SimulatedShellBackend implements ShellBackend {
  @override
  String get name => 'simulated';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ShellResult> run(String command, {String? workingDirectory}) async {
    final sw = Stopwatch()..start();
    await Future.delayed(const Duration(milliseconds: 180));
    final lc = command.trim().toLowerCase();
    String out;
    int code = 0;

    if (lc == 'pwd') {
      out = workingDirectory ?? '/data/kitsune/project';
    } else if (lc == 'ls' || lc.startsWith('ls ')) {
      out = 'lib/\npubspec.yaml\nREADME.md\nassets/\n.android/\n';
    } else if (lc.startsWith('echo ')) {
      out = command.substring(5);
    } else if (lc == 'whoami') {
      out = 'kitsune';
    } else if (lc == 'uname' || lc == 'uname -a') {
      out = 'KitsunéByte simulated-linux arm64';
    } else if (lc.startsWith('flutter ')) {
      out = _fakeFlutter(lc);
    } else if (lc == 'help' || lc == '--help') {
      out = 'simulated shell — install Termux bridge for real commands';
    } else {
      out = 'simulated: command accepted, no real process\n\$ $command';
    }

    sw.stop();
    return ShellResult(
      command: command,
      stdout: out,
      stderr: '',
      exitCode: code,
      duration: sw.elapsed,
      backend: name,
    );
  }

  String _fakeFlutter(String lc) {
    if (lc.contains('doctor')) {
      return '[✓] Flutter (simulated)\n[✓] Android toolchain (stub)\n[!] Connect Termux for real doctor';
    }
    if (lc.contains('pub get')) return 'Got dependencies! (simulated)';
    if (lc.contains('analyze')) return 'Analyzing… No issues found! (simulated)';
    if (lc.contains('build')) return '✓ Built build/app/outputs (simulated)';
    return 'flutter (simulated) — $lc';
  }

  @override
  Stream<String> runStream(String command, {String? workingDirectory}) async* {
    final result = await run(command, workingDirectory: workingDirectory);
    // Chunk output so the tool card animates like a real stream.
    final text = result.combined;
    const step = 24;
    for (var i = 0; i < text.length; i += step) {
      final end = (i + step < text.length) ? i + step : text.length;
      yield text.substring(i, end);
      await Future.delayed(const Duration(milliseconds: 28));
    }
  }
}

/// Talks to a local helper (Python/Node) that runs inside Termux.
/// Pattern used by mobile agentic IDEs: WebSocket/HTTP on localhost.
///
/// Expected bridge API:
///   POST http://127.0.0.1:$port/exec
///   body: { "cmd": "...", "cwd": "..." }
///   resp: { "stdout": "...", "stderr": "...", "code": 0 }
class LocalBridgeShellBackend implements ShellBackend {
  final String host;
  final int port;
  final Duration timeout;

  LocalBridgeShellBackend({
    this.host = '127.0.0.1',
    this.port = 8765,
    this.timeout = const Duration(seconds: 60),
  });

  @override
  String get name => 'termux-bridge:$port';

  @override
  Future<bool> isAvailable() async {
    try {
      final r = await http
          .get(Uri.parse('http://$host:$port/health'))
          .timeout(const Duration(seconds: 2));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ShellResult> run(String command, {String? workingDirectory}) async {
    final sw = Stopwatch()..start();
    try {
      final r = await http
          .post(
            Uri.parse('http://$host:$port/exec'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cmd': command,
              if (workingDirectory != null) 'cwd': workingDirectory,
            }),
          )
          .timeout(timeout);
      sw.stop();
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return ShellResult(
        command: command,
        stdout: '${data['stdout'] ?? ''}',
        stderr: '${data['stderr'] ?? ''}',
        exitCode: (data['code'] as num?)?.toInt() ?? r.statusCode,
        duration: sw.elapsed,
        backend: name,
      );
    } catch (e) {
      sw.stop();
      return ShellResult(
        command: command,
        stdout: '',
        stderr: 'bridge error: $e',
        exitCode: 1,
        duration: sw.elapsed,
        backend: name,
      );
    }
  }
}

/// Termux RUN_COMMAND via platform channel (see android_native/MainActivity.kt).
class TermuxIntentShellBackend implements ShellBackend {
  @override
  String get name => 'termux-intent';

  @override
  Future<bool> isAvailable() async {
    // Lazy import avoided — channel handles MissingPluginException.
    try {
      // ignore: avoid_dynamic_calls
      final installed = await TermuxChannelProbe.isInstalled();
      return installed;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ShellResult> run(String command, {String? workingDirectory}) async {
    final sw = Stopwatch()..start();
    final map = await TermuxChannelProbe.runBash(
      command,
      workdir: workingDirectory,
    );
    sw.stop();
    final ok = map['ok'] == true;
    return ShellResult(
      command: command,
      stdout: '${map['stdout'] ?? map['note'] ?? ''}',
      stderr: ok ? '' : '${map['error'] ?? 'termux intent failed'}',
      exitCode: ok ? 0 : 1,
      duration: sw.elapsed,
      backend: name,
    );
  }
}

/// Thin indirection so shell_backend.dart does not hard-depend on Flutter
/// services at import graph leaves in pure-dart tests.
class TermuxChannelProbe {
  static Future<bool> isInstalled() async {
    final m = await _invoke();
    return m;
  }

  static Future<bool> _invoke() async {
    try {
      // Imported from termux_channel.dart at call sites that have Flutter.
      return await _termuxInstalled();
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> runBash(
    String command, {
    String? workdir,
  }) async {
    try {
      return await _termuxBash(command, workdir);
    } catch (e) {
      return {'ok': false, 'error': '$e'};
    }
  }
}

// Bound in termux_channel_binding.dart / overridden by real channel.
Future<bool> Function() _termuxInstalled = () async => false;
Future<Map<String, dynamic>> Function(String, String?) _termuxBash =
    (cmd, cwd) async => {
          'ok': false,
          'error': 'Termux channel not registered',
        };

/// Call once from main() or terminal bootstrap to wire the real channel.
void registerTermuxChannelBindings({
  required Future<bool> Function() isInstalled,
  required Future<Map<String, dynamic>> Function(String cmd, String? cwd) runBash,
}) {
  _termuxInstalled = isInstalled;
  _termuxBash = runBash;
}

/// proot-distro (Ubuntu/Debian) inside Termux — full userspace without root.
/// Commands are prefixed: `proot-distro login ubuntu -- bash -lc '...'`
class ProotShellBackend implements ShellBackend {
  final ShellBackend inner;
  final String distro;

  ProotShellBackend({required this.inner, this.distro = 'ubuntu'});

  @override
  String get name => 'proot:$distro';

  @override
  Future<bool> isAvailable() => inner.isAvailable();

  @override
  Future<ShellResult> run(String command, {String? workingDirectory}) {
    final wrapped =
        "proot-distro login $distro -- bash -lc ${jsonEncode(command)}";
    return inner.run(wrapped, workingDirectory: workingDirectory);
  }
}

/// Picks the best available backend at runtime.
class ShellRouter {
  final List<ShellBackend> backends;
  ShellBackend? _active;

  ShellRouter({List<ShellBackend>? backends})
      : backends = backends ??
            [
              LocalBridgeShellBackend(),
              TermuxIntentShellBackend(),
              SimulatedShellBackend(),
            ];

  Future<ShellBackend> resolve() async {
    if (_active != null) return _active!;
    for (final b in backends) {
      if (await b.isAvailable()) {
        _active = b;
        return b;
      }
    }
    _active = SimulatedShellBackend();
    return _active!;
  }

  Future<ShellResult> run(String command, {String? workingDirectory}) async {
    final b = await resolve();
    return b.run(command, workingDirectory: workingDirectory);
  }

  Stream<String> runStream(String command, {String? workingDirectory}) async* {
    final b = await resolve();
    yield* b.runStream(command, workingDirectory: workingDirectory);
  }

  Future<String> activeName() async => (await resolve()).name;
}
