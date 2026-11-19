import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_field.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_text_field.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/settings/openai_key_store.dart';
import 'masked_api_key.dart';
import 'ruled_block.dart';

const String _invalidKeyProblem = 'That does not look like an API key.';

typedef KeyChange = Future<void> Function();

enum _KeyBlockMode { showingStoredKey, pastingKey }

class OpenAiKeyBlock extends StatefulWidget {
  const OpenAiKeyBlock({
    required this.storedKey,
    required this.onSave,
    required this.onRemove,
    super.key,
  });

  final String? storedKey;
  final Future<void> Function(String key) onSave;
  final KeyChange onRemove;

  @override
  State<OpenAiKeyBlock> createState() => _OpenAiKeyBlockState();
}

class _OpenAiKeyBlockState extends State<OpenAiKeyBlock> {
  final TextEditingController _maskedKey = TextEditingController();
  final TextEditingController _pastedKey = TextEditingController();
  _KeyBlockMode _mode = _KeyBlockMode.pastingKey;
  String? _problem;
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();

    final storedKey = widget.storedKey;

    if (storedKey != null) {
      _maskedKey.text = maskApiKey(storedKey);
      _mode = _KeyBlockMode.showingStoredKey;
    }
  }

  @override
  void dispose() {
    _maskedKey.dispose();
    _pastedKey.dispose();
    super.dispose();
  }

  void _replace() {
    setState(() {
      _mode = _KeyBlockMode.pastingKey;
      _problem = null;
    });
  }

  Future<void> _save() async {
    final key = _pastedKey.text.trim();

    if (!isStorableApiKey(key)) {
      setState(() => _problem = _invalidKeyProblem);
      return;
    }

    await _changeKey(() => widget.onSave(key));
  }

  Future<void> _changeKey(KeyChange change) async {
    setState(() {
      _problem = null;
      _isChanging = true;
    });

    try {
      await change();
    } on KeychainError catch (refusal) {
      setState(() => _problem = refusal.message);
    } finally {
      if (mounted) {
        setState(() => _isChanging = false);
      }
    }
  }

  List<Widget> _storedKeyRow() {
    return [
      Expanded(
        child: DesignTextField(
          controller: _maskedKey,
          editability: TextEditability.readOnly,
        ),
      ),
      DesignButton(label: 'Replace', onPressed: _isChanging ? null : _replace),
      DesignButton(
        label: 'Remove',
        variant: ButtonVariant.dangerOutline,
        onPressed: _isChanging ? null : () => _changeKey(widget.onRemove),
      ),
    ];
  }

  List<Widget> _pastedKeyRow() {
    final validity = _problem == null
        ? FieldValidity.valid
        : FieldValidity.invalid;

    return [
      Expanded(
        child: DesignTextField(
          controller: _pastedKey,
          placeholder: 'Paste your OpenAI key',
          visibility: TextVisibility.obscured,
          validity: validity,
          onSubmitted: (pasted) => _save(),
        ),
      ),
      DesignButton(label: 'Save key', onPressed: _isChanging ? null : _save),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    final keyRow = switch (_mode) {
      _KeyBlockMode.showingStoredKey => _storedKeyRow(),
      _KeyBlockMode.pastingKey => _pastedKeyRow(),
    };

    return RuledBlock(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step3,
        children: [
          Text(
            'OpenAI',
            style: textStyleForSize(TextSizes.small)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: Spacing.step3,
            children: keyRow,
          ),
          if (problem != null) FieldError(message: problem),
        ],
      ),
    );
  }
}
