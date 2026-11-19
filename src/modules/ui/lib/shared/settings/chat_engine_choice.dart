enum ChatEngineChoice {
  openAi('openai', 'OpenAI'),
  claudeCode('claude-code', 'Claude Code on this Mac');

  const ChatEngineChoice(this.setting, this.label);

  final String setting;
  final String label;
}

ChatEngineChoice chatEngineNamed(String setting) {
  for (final engine in ChatEngineChoice.values) {
    if (engine.setting == setting) {
      return engine;
    }
  }

  throw FormatException('Unknown chat engine "$setting"');
}
