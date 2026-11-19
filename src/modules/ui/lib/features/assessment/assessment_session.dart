import 'dart:math';

import 'package:flutter/material.dart';

import '../../shared/api/api_error.dart';
import '../../shared/design/toast.dart';
import '../../shared/design/toast_host.dart';
import 'assessment_api.dart';
import 'assessment_models.dart';
import 'empty_test_view.dart';
import 'progress_memory.dart';
import 'test_answer.dart';
import 'test_item_editor_dialog.dart';
import 'test_position.dart';
import 'test_question_view.dart';
import 'test_result_view.dart';
import 'unsaved_progress.dart';

typedef OpenedTest = ({TestItemsPage page, int itemIndex});
typedef AssessmentStep = Future<void> Function();
typedef _TestRound = ({TestItemsPageLoader loadPage, ProgressMemory memory});

const int _firstPosition = 1;
const String _answerFailure = "Couldn't save your answer";
const String _editFailure = "Couldn't save the question";
const String _retakeFailure = "Couldn't restart the test";
const String _missedFailure = "Couldn't open the missed questions";

class AssessmentSession extends StatefulWidget {
  const AssessmentSession({
    required this.api,
    required this.loadPage,
    required this.loadMissedPage,
    required this.memory,
    required this.opened,
    super.key,
  });

  final AssessmentApi api;
  final TestItemsPageLoader loadPage;
  final MissedItemsPageLoader loadMissedPage;
  final ProgressMemory memory;
  final OpenedTest opened;

  @override
  State<AssessmentSession> createState() => _AssessmentSessionState();
}

class _AssessmentSessionState extends State<AssessmentSession> {
  late TestItemsPage _page = widget.opened.page;
  late int _itemIndex = widget.opened.itemIndex;
  late _TestRound _round = _wholeTest();
  Map<int, List<TestAnswer>> _chosenAnswers = const {};
  TestSessionResult? _result;

  _TestRound _wholeTest() {
    return (loadPage: widget.loadPage, memory: widget.memory);
  }

  List<TestAnswer> _answersFor(TestItem item) {
    return _chosenAnswers[item.id] ?? item.lastAnswers;
  }

  void _choose(TestItem item, TestAnswer answer) {
    setState(
      () => _chosenAnswers = {
        ..._chosenAnswers,
        item.id: [answer],
      },
    );
  }

  Future<void> _submit(TestItem item) async {
    final answers = _answersFor(item);

    if (answers.isEmpty) {
      return;
    }

    await widget.api.submitAnswers(
      testItemId: item.id,
      testSession: _page.testSession,
      answers: answers,
    );
  }

  Future<void> _goForward(TestItem item) async {
    await _submit(item);

    final nextIndex = _itemIndex + 1;

    if (nextIndex < _page.items.length) {
      await _moveTo(_page, nextIndex);
      return;
    }

    if (overallPosition(_page, _itemIndex) >= _page.totalItems) {
      await _finish();
      return;
    }

    await _moveTo(await _round.loadPage(_page.pageNumber + 1), 0);
  }

  Future<void> _goBack(TestItem item) async {
    await _submit(item);

    if (_itemIndex > 0) {
      await _moveTo(_page, _itemIndex - 1);
      return;
    }

    final previousPageNumber = max(firstPageNumber, _page.pageNumber - 1);
    final previousPage = await _round.loadPage(previousPageNumber);

    await _moveTo(previousPage, max(0, previousPage.items.length - 1));
  }

  Future<void> _finish() async {
    final result = await widget.api.sessionResult(_page.testSession);

    await _round.memory.forget();

    if (mounted) {
      setState(() => _result = result);
    }
  }

  Future<void> _startRound(_TestRound round) async {
    final firstPage = await round.loadPage(firstPageNumber);

    if (!mounted) {
      return;
    }

    setState(() {
      _round = round;
      _page = firstPage;
      _itemIndex = 0;
      _result = null;
      _chosenAnswers = const {};
    });
    await round.memory.remember(TestPosition.start);
  }

  Future<void> _retake() async {
    await _startRound(_wholeTest());
  }

  Future<void> _reviewMissed() async {
    final finishedSession = _page.testSession;
    final _TestRound missedRound = (
      loadPage: (pageNumber) =>
          widget.loadMissedPage(finishedSession, pageNumber),
      memory: const UnsavedProgress(),
    );

    await _startRound(missedRound);
  }

  Future<void> _moveTo(TestItemsPage page, int itemIndex) async {
    final position = TestPosition(
      pageNumber: page.pageNumber,
      itemIndex: itemIndex,
    );

    await _round.memory.remember(position);

    if (mounted) {
      setState(() {
        _page = page;
        _itemIndex = itemIndex;
      });
    }
  }

  Future<void> _edit(TestItem item) async {
    final edited = await showTestItemEditor(context: context, item: item);

    if (edited == null) {
      return;
    }

    await _safely(_editFailure, () async {
      await widget.api.updateItem(testItemId: item.id, edited: edited);

      final reloadedPage = await widget.loadPage(_page.pageNumber);

      if (mounted) {
        setState(() => _page = reloadedPage);
      }
    });
  }

  Future<void> _safely(String failureTitle, AssessmentStep step) async {
    final toasts = ToastHost.of(context);

    try {
      await step();
    } on ApiError catch (failure) {
      toasts.show(
        ToastMessage(
          tone: ToastTone.failure,
          title: failureTitle,
          detail: failure.detail,
        ),
      );
    }
  }

  void _backToFolder() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    if (result != null) {
      return TestResultView(
        correctCount: result.correctCount,
        totalItems: _page.totalItems,
        missedCount: result.missedItemIds.length,
        onReviewMissed: () => _safely(_missedFailure, _reviewMissed),
        onRetake: () => _safely(_retakeFailure, _retake),
        onBackToFolder: _backToFolder,
      );
    }

    if (_page.totalItems == 0) {
      return EmptyTestView(onBackToFolder: _backToFolder);
    }

    final item = _page.items[_itemIndex];
    final position = overallPosition(_page, _itemIndex);

    return TestQuestionView(
      item: item,
      chosenAnswers: _answersFor(item),
      position: position,
      totalItems: _page.totalItems,
      onChoose: (answer) => _choose(item, answer),
      onEdit: item.isEditable ? () => _edit(item) : null,
      onBack: position > _firstPosition
          ? () => _safely(_answerFailure, () => _goBack(item))
          : null,
      onNext: () => _safely(_answerFailure, () => _goForward(item)),
    );
  }
}
