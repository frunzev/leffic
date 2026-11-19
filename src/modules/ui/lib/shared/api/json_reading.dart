typedef JsonObject = Map<String, Object?>;

JsonObject asObject(Object? decoded) {
  if (decoded is Map<String, Object?>) {
    return decoded;
  }

  throw const FormatException('Expected a JSON object');
}

String readText(JsonObject json, String key) {
  final value = json[key];

  if (value is String) {
    return value;
  }

  throw FormatException('Expected text at "$key"');
}

String readTextOr(JsonObject json, String key, String fallback) {
  final value = json[key];

  if (value == null) {
    return fallback;
  }

  return readText(json, key);
}

int readWholeNumber(JsonObject json, String key) {
  final value = json[key];

  if (value is int) {
    return value;
  }

  throw FormatException('Expected a whole number at "$key"');
}

int readWholeNumberOr(JsonObject json, String key, int fallback) {
  if (json[key] == null) {
    return fallback;
  }

  return readWholeNumber(json, key);
}

JsonObject readObject(JsonObject json, String key) {
  final value = json[key];

  if (value is Map<String, Object?>) {
    return value;
  }

  throw FormatException('Expected an object at "$key"');
}

List<JsonObject> readObjects(JsonObject json, String key) {
  final value = json[key];

  if (value is! List<Object?>) {
    throw FormatException('Expected a list at "$key"');
  }

  final objects = <JsonObject>[];

  for (final entry in value) {
    objects.add(asObject(entry));
  }

  return objects;
}

List<String> readTexts(JsonObject json, String key) {
  final value = json[key];

  if (value is! List<Object?>) {
    throw FormatException('Expected a list at "$key"');
  }

  final texts = <String>[];

  for (final entry in value) {
    if (entry is! String) {
      throw FormatException('Expected only text in "$key"');
    }

    texts.add(entry);
  }

  return texts;
}

List<int> readWholeNumbers(JsonObject json, String key) {
  final value = json[key];

  if (value is! List<Object?>) {
    throw FormatException('Expected a list at "$key"');
  }

  final numbers = <int>[];

  for (final entry in value) {
    if (entry is! int) {
      throw FormatException('Expected only whole numbers in "$key"');
    }

    numbers.add(entry);
  }

  return numbers;
}
