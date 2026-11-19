import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../design/design_button.dart';
import '../design/design_modal.dart';
import '../design/toast_host.dart';
import 'file_picking.dart';
import 'file_source_panel.dart';
import 'footer_hint.dart';
import 'generation_choices.dart';
import 'import_buttons.dart';
import 'import_draft.dart';
import 'import_fields.dart';
import 'import_hints.dart';
import 'import_messages.dart';
import 'import_plan.dart';
import 'import_source.dart';
import 'import_step.dart';
import 'reading_source_notice.dart';
import 'review_step.dart';
import 'source_step.dart';
import 'source_text_panel.dart';
import 'text_and_choices.dart';

typedef SourceTextRead = Future<String> Function(ImportSource source);

const String _title = 'Import';
const String _cancelLabel = 'Cancel';
const String _backLabel = 'Back';
const String _uploadOnlyLabel = 'Upload only';
const String _pastedTextLabel = 'Text';
const String _pastedTextHint =
    'Everything comes from this text. Leffic adds nothing of its own.';

class ImportModal extends StatefulWidget {
  const ImportModal({
    required this.folderName,
    required this.pickFile,
    required this.readSourceText,
    this.sourceToRead,
    super.key,
  });

  final String folderName;
  final SourceFilePicker pickFile;
  final SourceTextRead readSourceText;
  final ImportSource? sourceToRead;

  @override
  State<ImportModal> createState() => _ImportModalState();
}

class _ImportModalState extends State<ImportModal> {
  final ImportFields _fields = ImportFields();
  ImportSourceKind _kind = ImportSourceKind.file;
  UploadedFile? _file;
  GenerationChoices _choices = GenerationChoices.starting;
  late ImportStep _step = firstImportStep(widget.sourceToRead);

  @override
  void initState() {
    super.initState();

    final sourceToRead = widget.sourceToRead;

    if (sourceToRead != null) {
      unawaited(_readText(sourceToRead));
    }
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  void _showTyped(String typed) {
    setState(() {});
  }

  void _selectKind(ImportSourceKind kind) {
    setState(() => _kind = kind);
  }

  void _changeChoices(GenerationChoices choices) {
    setState(() => _choices = choices);
  }

  Future<void> _browse() async {
    final pickedFile = await widget.pickFile();

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() => _file = pickedFile);
  }

  void _removeFile() {
    setState(() => _file = null);
  }

  void _goBack() {
    setState(() => _step = const ChoosingSource());
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _finish(ImportPlan plan) {
    Navigator.of(context).pop(plan);
  }

  Future<void> _read(ImportSource source) async {
    setState(() => _step = ReadingSource(source: source));
    await _readText(source);
  }

  Future<void> _readText(ImportSource source) async {
    final String text;

    try {
      text = await widget.readSourceText(source);
    } on Exception catch (failure) {
      _returnAfterFailedReading(source, failure);
      return;
    }

    if (!mounted) {
      return;
    }

    _fields.reviewedText.text = text;
    setState(() => _step = ReviewingText(source: source));
  }

  void _returnAfterFailedReading(ImportSource source, Exception failure) {
    if (!mounted) {
      return;
    }

    final message = readingFailureMessage(source.label, '$failure');

    ToastHost.of(context).show(message);
    setState(() => _step = const ChoosingSource());
  }

  ImportDraft _draft() {
    return ImportDraft(
      kind: _kind,
      file: _file,
      link: _fields.link.text,
      pastedText: _fields.pastedText.text,
      topic: _fields.topic.text,
      firstPageText: _fields.firstPage.text,
      lastPageText: _fields.lastPage.text,
    );
  }

  Widget _sourcePanel() {
    return switch (_kind) {
      ImportSourceKind.file => FileSourcePanel(
        file: _file,
        firstPage: _fields.firstPage,
        lastPage: _fields.lastPage,
        onBrowse: _browse,
        onRemove: _removeFile,
        onTyped: _showTyped,
      ),
      ImportSourceKind.link => SourceTextPanel(
        copy: linkFieldCopy,
        controller: _fields.link,
        onChanged: _showTyped,
      ),
      ImportSourceKind.text => TextAndChoices(
        label: _pastedTextLabel,
        hint: _pastedTextHint,
        controller: _fields.pastedText,
        onTyped: _showTyped,
        choices: _choices,
        onChoicesChanged: _changeChoices,
      ),
      ImportSourceKind.topic => SourceTextPanel(
        copy: topicFieldCopy,
        controller: _fields.topic,
        onChanged: _showTyped,
      ),
    };
  }

  Widget _body() {
    return switch (_step) {
      ChoosingSource() => SourceStep(
        kind: _kind,
        onKindSelected: _selectKind,
        panel: _sourcePanel(),
      ),
      ReadingSource(:final source) => ReadingSourceNotice(
        sourceLabel: source.label,
      ),
      ReviewingText(:final source) => ReviewStep(
        sourceLabel: source.label,
        controller: _fields.reviewedText,
        onTyped: _showTyped,
        choices: _choices,
        onChoicesChanged: _changeChoices,
      ),
    };
  }

  GenerationPlan? _planFor(ImportSource? readySource, String text) {
    if (readySource == null) {
      return null;
    }

    return GenerationPlan(source: readySource, text: text, choices: _choices);
  }

  List<Widget> _sourceActions() {
    final reading = _draft().read();
    final hint = sourceStepHint(
      reading: reading,
      kind: _kind,
      choices: _choices,
    );
    final readySource = switch (reading) {
      SourceReady(:final source) when hint == null => source,
      _ => null,
    };
    final chosenFile = _file;

    return [
      if (hint != null) FooterHint(text: hint),
      DesignButton(label: _cancelLabel, onPressed: _cancel),
      if (_kind == ImportSourceKind.file && chosenFile != null)
        DesignButton(
          label: _uploadOnlyLabel,
          onPressed: () => _finish(UploadPlan(file: chosenFile)),
        ),
      if (_kind == ImportSourceKind.text)
        GenerateButton(
          plan: _planFor(readySource, _fields.pastedText.text),
          onFinish: _finish,
        )
      else
        ContinueButton(readySource: readySource, onRead: _read),
    ];
  }

  List<Widget> _reviewActions(ImportSource source) {
    final reviewedText = _fields.reviewedText.text;
    final hint = reviewStepHint(reviewedText: reviewedText, choices: _choices);
    final readySource = hint == null ? source : null;

    return [
      if (hint != null) FooterHint(text: hint),
      DesignButton(label: _backLabel, onPressed: _goBack),
      GenerateButton(
        plan: _planFor(readySource, reviewedText),
        onFinish: _finish,
      ),
    ];
  }

  List<Widget> _actions() {
    return switch (_step) {
      ChoosingSource() => _sourceActions(),
      ReadingSource() => [
        DesignButton(label: _cancelLabel, onPressed: _cancel),
      ],
      ReviewingText(:final source) => _reviewActions(source),
    };
  }

  @override
  Widget build(BuildContext context) {
    return DesignModal(
      title: _title,
      description: 'Saved into ${widget.folderName}.',
      width: ModalWidth.wide,
      body: _body(),
      actions: _actions(),
    );
  }
}
