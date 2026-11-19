import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/widgets/app_shell.dart';
import 'assessment_api.dart';
import 'assessment_review.dart';
import 'file_progress_memory.dart';

class TestPage extends StatelessWidget {
  const TestPage({required this.arguments, super.key});

  final UnitArguments arguments;

  @override
  Widget build(BuildContext context) {
    final api = AssessmentApi(BackendScope.clientOf(context));

    return AppShell(
      selectedRoute: Routes.test,
      body: AssessmentReview(
        api: api,
        loadPage: (pageNumber) =>
            api.testItemsPage(testId: arguments.id, pageNumber: pageNumber),
        loadMissedPage: (finishedSession, pageNumber) =>
            api.missedTestItemsPage(
              testId: arguments.id,
              finishedSession: finishedSession,
              pageNumber: pageNumber,
            ),
        memory: FileProgressMemory(
          scopeId: arguments.id,
          locateDirectory: getApplicationSupportDirectory,
        ),
      ),
    );
  }
}
