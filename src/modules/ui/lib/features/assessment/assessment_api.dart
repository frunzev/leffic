import '../../shared/api/api_client.dart';
import '../../shared/api/json_reading.dart';
import '../../shared/api/json_unless_missing.dart';
import 'assessment_models.dart';
import 'edited_test_item.dart';
import 'test_answer.dart';

typedef TestItemsPageLoader = Future<TestItemsPage> Function(int pageNumber);
typedef MissedItemsPageLoader = Future<TestItemsPage> Function(
  String finishedSession,
  int pageNumber,
);

const int _itemsPerPage = 10;
const String _missedInSessionKey = 'missed_in_session';

class AssessmentApi {
  const AssessmentApi(this.client);

  final ApiClient client;

  Future<TestItemsPage> testItemsPage({
    required String testId,
    required int pageNumber,
  }) {
    return _itemsPage({'test_id': testId}, pageNumber);
  }

  Future<TestItemsPage> folderItemsPage({
    required String folderId,
    required int pageNumber,
  }) {
    return _itemsPage({'folder_id': folderId}, pageNumber);
  }

  Future<TestItemsPage> missedTestItemsPage({
    required String testId,
    required String finishedSession,
    required int pageNumber,
  }) {
    return _itemsPage({
      'test_id': testId,
      _missedInSessionKey: finishedSession,
    }, pageNumber);
  }

  Future<TestItemsPage> missedFolderItemsPage({
    required String folderId,
    required String finishedSession,
    required int pageNumber,
  }) {
    return _itemsPage({
      'folder_id': folderId,
      _missedInSessionKey: finishedSession,
    }, pageNumber);
  }

  Future<void> submitAnswers({
    required int testItemId,
    required String testSession,
    required List<TestAnswer> answers,
  }) async {
    final wireAnswers = <Object>[];

    for (final answer in answers) {
      wireAnswers.add(answer.wireValue);
    }

    await client.sendJson('POST', '/review-test-item', {
      'test_item_id': testItemId,
      'test_session': testSession,
      'answers': wireAnswers,
    });
  }

  Future<TestSessionResult> sessionResult(String testSession) {
    return readJsonUnlessMissing(
      client: client,
      path: '/test-session-results',
      query: {'test_session': testSession},
      whenMissing: TestSessionResult.nothingAnswered,
      read: TestSessionResult.fromJson,
    );
  }

  Future<void> updateItem({
    required int testItemId,
    required EditedTestItem edited,
  }) async {
    await client.sendJson('PATCH', '/update-test-item', {
      'test_item_id': testItemId,
      'content': edited.toContent(),
    });
  }

  Future<TestItemsPage> _itemsPage(
    QueryParameters scope,
    int pageNumber,
  ) async {
    final reply = await client.getJson('/test-items', {
      ...scope,
      'page': '$pageNumber',
      'per_page': '$_itemsPerPage',
    });

    return TestItemsPage.fromJson(asObject(reply));
  }
}
