import 'package:flutter/material.dart';

import '../../shared/widgets/load_view.dart';
import '../../shared/widgets/review_stage.dart';
import 'assessment_api.dart';
import 'assessment_session.dart';
import 'progress_memory.dart';
import 'test_position.dart';

Future<OpenedTest> openRememberedTest({
  required TestItemsPageLoader loadPage,
  required ProgressMemory memory,
}) async {
  final position = await memory.recall();
  final page = await loadPage(position.pageNumber);
  final isEmptyTest = page.totalItems == 0;
  final isRememberedItemThere = position.itemIndex < page.items.length;

  if (isEmptyTest || isRememberedItemThere) {
    return (page: page, itemIndex: position.itemIndex);
  }

  return (page: await loadPage(firstPageNumber), itemIndex: 0);
}

class AssessmentReview extends StatelessWidget {
  const AssessmentReview({
    required this.api,
    required this.loadPage,
    required this.loadMissedPage,
    required this.memory,
    super.key,
  });

  final AssessmentApi api;
  final TestItemsPageLoader loadPage;
  final MissedItemsPageLoader loadMissedPage;
  final ProgressMemory memory;

  @override
  Widget build(BuildContext context) {
    return ReviewStage(
      child: LoadView<OpenedTest>(
        load: () => openRememberedTest(loadPage: loadPage, memory: memory),
        builder: (context, opened, reload) => AssessmentSession(
          api: api,
          loadPage: loadPage,
          loadMissedPage: loadMissedPage,
          memory: memory,
          opened: opened,
        ),
      ),
    );
  }
}
