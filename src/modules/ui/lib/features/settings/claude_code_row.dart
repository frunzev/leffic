import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_field.dart';
import '../../shared/design/icons/design_icons.dart';
import 'claude_code_installer.dart';
import 'component_row.dart';
import 'secure_note.dart';

typedef ClaudeCodeFinder = Future<String?> Function();
typedef ClaudeCodeInstall = Future<void> Function();

const String _title = 'Claude Code';
const String _installLabel = 'Install Claude Code';
const String _lookingText = 'Looking for Claude Code on this Mac…';
const String _missingText =
    'Not found on this Mac. The Ask chat runs on Claude Code.';
const String _installingText = 'Installing Claude Code…';
const String _signInNote = 'Run claude once in Terminal to sign in.';
const String _notFoundAfterInstall =
    'The installer finished, but Claude Code was not found.';

sealed class _ClaudeCodeStatus {
  const _ClaudeCodeStatus();
}

final class _Looking extends _ClaudeCodeStatus {
  const _Looking();
}

final class _Found extends _ClaudeCodeStatus {
  const _Found(this.location);

  final String location;
}

final class _InstalledNow extends _ClaudeCodeStatus {
  const _InstalledNow(this.location);

  final String location;
}

final class _Missing extends _ClaudeCodeStatus {
  const _Missing();
}

final class _Installing extends _ClaudeCodeStatus {
  const _Installing();
}

final class _InstallFailed extends _ClaudeCodeStatus {
  const _InstallFailed(this.reason);

  final String reason;
}

String _foundText(String location) => 'Claude Code found at $location';

class ClaudeCodeRow extends StatefulWidget {
  const ClaudeCodeRow({
    required this.findClaudeCode,
    required this.installClaudeCode,
    super.key,
  });

  final ClaudeCodeFinder findClaudeCode;
  final ClaudeCodeInstall installClaudeCode;

  @override
  State<ClaudeCodeRow> createState() => _ClaudeCodeRowState();
}

class _ClaudeCodeRowState extends State<ClaudeCodeRow> {
  _ClaudeCodeStatus _status = const _Looking();

  @override
  void initState() {
    super.initState();
    unawaited(_lookForClaudeCode());
  }

  Future<void> _lookForClaudeCode() async {
    final location = await widget.findClaudeCode();

    _show(location == null ? const _Missing() : _Found(location));
  }

  Future<void> _install() async {
    _show(const _Installing());

    try {
      await widget.installClaudeCode();
    } on ClaudeCodeInstallError catch (refusal) {
      _show(_InstallFailed(refusal.message));
      return;
    }

    final location = await widget.findClaudeCode();

    if (location == null) {
      _show(const _InstallFailed(_notFoundAfterInstall));
      return;
    }

    _show(_InstalledNow(location));
  }

  void _show(_ClaudeCodeStatus status) {
    if (!mounted) {
      return;
    }

    setState(() => _status = status);
  }

  Widget _signInNoteBlock() {
    return SecureNote(
      icon: DesignIcons.success,
      iconColor: DesignColors.of(context).success,
      children: const [Text(_signInNote)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final installButton = DesignButton(
      label: _installLabel,
      onPressed: _install,
    );

    return switch (_status) {
      _Looking() => const ComponentRow(
        title: _title,
        description: _lookingText,
      ),
      _Found(:final location) => ComponentRow(
        title: _title,
        description: _foundText(location),
      ),
      _InstalledNow(:final location) => ComponentRow(
        title: _title,
        description: _foundText(location),
        details: [_signInNoteBlock()],
      ),
      _Missing() => ComponentRow(
        title: _title,
        description: _missingText,
        actions: [installButton],
      ),
      _Installing() => const ComponentRow(
        title: _title,
        description: _installingText,
        actions: [DesignButton(label: _installLabel, onPressed: null)],
      ),
      _InstallFailed(:final reason) => ComponentRow(
        title: _title,
        description: _missingText,
        actions: [installButton],
        details: [FieldError(message: reason)],
      ),
    };
  }
}
