import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/settings/app_preferences.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';

import '../../support/hosting.dart';
import 'settings_fakes.dart';
import 'settings_page_harness.dart';

void main() {
  testWidgets('SettingsPage property lists the optional components', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final directory = await tester.runAsync(
      () => preferencesDirectoryWith(ChatEngineChoice.claudeCode),
    );

    await pumpSettings(
      tester,
      connectedLink(),
      settingsPageWith(preferencesDirectory: directory!),
    );

    expect(find.text('Components'), findsOneWidget);
    expect(find.text('LibreOffice'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(
      find.text('Claude Code found at $claudeCodeLocation'),
      findsOneWidget,
    );
  });

  testWidgets('SettingsPage property shows the stored chat engine', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final engine in ChatEngineChoice.values) {
      final directory = await tester.runAsync(
        () => preferencesDirectoryWith(engine),
      );
      final link = connectedLink();

      await pumpSettings(
        tester,
        link,
        settingsPageWith(preferencesDirectory: directory!),
      );

      final selector = tester.widget<SegmentedControl<ChatEngineChoice>>(
        find.byType(SegmentedControl<ChatEngineChoice>),
      );

      expect(selector.selected, engine);
      expect(link.value, isNotNull);
    }
  });

  testWidgets('SettingsPage property saves a new engine and stays open', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final engine in ChatEngineChoice.values) {
      final directory = await tester.runAsync(
        () => preferencesDirectoryWith(engine),
      );
      final link = connectedLink();
      final relauncher = RecordingRelauncher();
      final chosenEngine = otherEngine(engine);

      await pumpSettings(
        tester,
        link,
        settingsPageWith(
          preferencesDirectory: directory!,
          relauncher: relauncher,
        ),
      );
      await settleAfterDisk(tester, () async {
        await tester.tap(
          find.descendant(
            of: find.byType(SegmentedControl<ChatEngineChoice>),
            matching: find.text(chosenEngine.label),
          ),
        );
      });
      await settleAfterDisk(tester, () async {});

      final stored = await tester.runAsync(() => loadPreferences(directory));
      final selector = tester.widget<SegmentedControl<ChatEngineChoice>>(
        find.byType(SegmentedControl<ChatEngineChoice>),
      );

      expect(stored!.chatEngine, chosenEngine);
      expect(selector.selected, chosenEngine);
      expectRestartedInPlace(relauncher, link);
    }
  });

  testWidgets('SettingsPage property opens startup when no backend starts', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => preferencesDirectoryWith(ChatEngineChoice.claudeCode),
    );
    final relauncher = RecordingRelauncher(failure: 'port taken');

    await pumpSettings(
      tester,
      connectedLink(),
      settingsPageWith(
        preferencesDirectory: directory!,
        relauncher: relauncher,
      ),
    );
    await settleAfterDisk(tester, () async {
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedControl<ChatEngineChoice>),
          matching: find.text(ChatEngineChoice.openAi.label),
        ),
      );
    });

    expect(find.byType(SettingsPage), findsNothing);
    expect(find.text(startupPlaceholder), findsOneWidget);
  });
}
