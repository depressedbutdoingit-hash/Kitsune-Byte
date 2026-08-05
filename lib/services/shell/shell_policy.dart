import 'dart:convert';

/// Allowlist gate for real shell execution.
/// Modes: ask every time · session remember · always allow binary · deny.
enum ShellConsent { ask, allowSession, allowAlways, deny }

class ShellPolicy {
  static final ShellPolicy instance = ShellPolicy._();
  ShellPolicy._();

  /// Binaries considered safe by default (still gated by consent mode).
  static const defaultAllowlist = {
    'ls',
    'pwd',
    'echo',
    'cat',
    'uname',
    'whoami',
    'date',
    'clear',
    'flutter',
    'dart',
    'git',
    'npm',
    'node',
    'python',
    'python3',
    'pip',
    'mkdir',
    'touch',
    'cp',
    'mv',
    'grep',
    'find',
    'head',
    'tail',
    'wc',
    'pkg',
    'proot-distro',
  };

  /// Always blocked — destructive or network-exfil risk without explicit opt-in.
  static const denylist = {
    'rm',
    'rmdir',
    'dd',
    'mkfs',
    'reboot',
    'su',
    'sudo',
    'chmod',
    'chown',
    'curl',
    'wget',
    'nc',
    'ncat',
    'ssh',
    'scp',
  };

  final Set<String> _sessionAllowed = {};
  final Set<String> _alwaysAllowed = {...defaultAllowlist};
  bool _sessionTrustAll = false;

  bool get sessionTrustAll => _sessionTrustAll;

  void trustAllForSession() => _sessionTrustAll = true;

  void allowAlways(String binary) {
    _alwaysAllowed.add(binary);
    _sessionAllowed.add(binary);
  }

  void allowSession(String binary) => _sessionAllowed.add(binary);

  void deny(String binary) {
    _sessionAllowed.remove(binary);
    _alwaysAllowed.remove(binary);
  }

  /// First token of the command = binary name.
  String binaryOf(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return '';
    final first = trimmed.split(RegExp(r'\s+')).first;
    // strip path: /data/data/.../ls → ls
    return first.split('/').last;
  }

  /// Returns null if execution may proceed; otherwise a human reason to block
  /// or a sentinel 'NEEDS_CONSENT' so the UI can prompt.
  String? check(String command) {
    final bin = binaryOf(command);
    if (bin.isEmpty) return 'empty command';
    if (denylist.contains(bin)) {
      return '`$bin` is blocked by policy (destructive / network).';
    }
    if (_sessionTrustAll) return null;
    if (_alwaysAllowed.contains(bin) || _sessionAllowed.contains(bin)) {
      return null;
    }
    return 'NEEDS_CONSENT';
  }

  Map<String, dynamic> toJson() => {
        'always': _alwaysAllowed.toList()..sort(),
        'session': _sessionAllowed.toList()..sort(),
        'trust_session': _sessionTrustAll,
      };

  @override
  String toString() => jsonEncode(toJson());
}
