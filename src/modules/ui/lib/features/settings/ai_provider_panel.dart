import 'package:flutter/material.dart';

import 'settings_layout.dart';
import 'settings_panel.dart';

const String aiProviderKeysText =
    'Optional. Leffic generates flashcards, notes and tests with your '
    'OpenAI key. Saving or removing it restarts Leffic.';

class AiProviderPanel extends StatelessWidget {
  const AiProviderPanel({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return SettingsPanel(
      title: aiProviderKeysTitle,
      text: aiProviderKeysText,
      body: body,
    );
  }
}
