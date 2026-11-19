import 'dart:convert';
import 'dart:io';

import '../api/json_reading.dart';
import 'chat_engine_choice.dart';

const String _preferencesFile = 'preferences.json';
const String _chatEngineKey = 'chat_engine';

class AppPreferences {
  const AppPreferences({required this.chatEngine});

  final ChatEngineChoice chatEngine;
}

String encodePreferences(AppPreferences preferences) {
  return jsonEncode({_chatEngineKey: preferences.chatEngine.setting});
}

AppPreferences decodePreferences(String encoded) {
  final stored = asObject(jsonDecode(encoded));
  final chatEngine = chatEngineNamed(readText(stored, _chatEngineKey));

  return AppPreferences(chatEngine: chatEngine);
}

Future<AppPreferences> loadPreferences(Directory dataDirectory) async {
  final file = File('${dataDirectory.path}/$_preferencesFile');

  if (!await file.exists()) {
    return const AppPreferences(chatEngine: ChatEngineChoice.claudeCode);
  }

  return decodePreferences(await file.readAsString());
}

Future<void> savePreferences(
  Directory dataDirectory,
  AppPreferences preferences,
) async {
  final file = File('${dataDirectory.path}/$_preferencesFile');

  await file.writeAsString(encodePreferences(preferences));
}
