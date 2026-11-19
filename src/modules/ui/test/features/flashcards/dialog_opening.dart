import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hosting.dart';

typedef DialogOpener = Future<Object?> Function(BuildContext context);

Widget openingDialog(DialogOpener open, List<Object?> answers) {
  return hostedPlainly(
    Builder(
      builder: (context) => TextButton(
        onPressed: () async => answers.add(await open(context)),
        child: const Text('open dialog'),
      ),
    ),
  );
}

Future<void> openDialog(WidgetTester tester) async {
  await tester.tap(find.text('open dialog'));
  await tester.pumpAndSettle();
}
