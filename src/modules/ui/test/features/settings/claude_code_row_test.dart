import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/claude_code_installer.dart';
import 'package:leffic/features/settings/claude_code_row.dart';
import 'package:leffic/shared/design/design_button.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const String _installLabel = 'Install Claude Code';
const String _signInNote = 'Run claude once in Terminal to sign in.';

class _ScriptedClaudeCode {
  _ScriptedClaudeCode({required this.location, this.installRefusal});

  String? location;
  final String? installRefusal;
  final String installedLocation = '/Users/someone/.local/bin/claude';
  int installCount = 0;

  Future<String?> find() async => location;

  Future<void> install() async {
    installCount++;

    final refusal = installRefusal;

    if (refusal != null) {
      throw ClaudeCodeInstallError(refusal);
    }

    location = installedLocation;
  }
}

Future<void> _pumpRow(WidgetTester tester, _ScriptedClaudeCode claude) async {
  await tester.pumpWidget(
    hostedPlainly(
      ClaudeCodeRow(
        key: UniqueKey(),
        findClaudeCode: claude.find,
        installClaudeCode: claude.install,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _installButton() => find.widgetWithText(DesignButton, _installLabel);

void main() {
  testWidgets('ClaudeCodeRow property names where Claude Code is', (
    tester,
  ) async {
    for (final location in examplesOf(
      (random) => '/${wordOf(random)}/bin/claude',
      runs: 5,
    )) {
      await _pumpRow(tester, _ScriptedClaudeCode(location: location));

      expect(find.text('Claude Code'), findsOneWidget);
      expect(find.text('Claude Code found at $location'), findsOneWidget);
      expect(_installButton(), findsNothing);
      expect(find.text(_signInNote), findsNothing);
    }
  });

  testWidgets('ClaudeCodeRow property installs only when asked', (
    tester,
  ) async {
    final claude = _ScriptedClaudeCode(location: null);

    await _pumpRow(tester, claude);

    expect(claude.installCount, 0);
    expect(_installButton(), findsOneWidget);

    await tester.tap(_installButton());
    await tester.pumpAndSettle();

    expect(claude.installCount, 1);
    expect(
      find.text('Claude Code found at ${claude.installedLocation}'),
      findsOneWidget,
    );
    expect(find.text(_signInNote), findsOneWidget);
    expect(_installButton(), findsNothing);
  });

  testWidgets('ClaudeCodeRow property explains a failed install', (
    tester,
  ) async {
    for (final refusal in examplesOf(
      (random) => 'Refused ${wordOf(random)}',
      runs: 5,
    )) {
      final claude = _ScriptedClaudeCode(
        location: null,
        installRefusal: refusal,
      );

      await _pumpRow(tester, claude);
      await tester.tap(_installButton());
      await tester.pumpAndSettle();

      expect(find.text(refusal), findsOneWidget);
      expect(_installButton(), findsOneWidget);
    }
  });
}
