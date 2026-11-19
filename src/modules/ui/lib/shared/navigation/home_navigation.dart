import 'package:flutter/widgets.dart';

import 'routes.dart';

void openHomeFolder(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    Routes.folder,
    (route) => route.isFirst,
    arguments: const UnitArguments(id: homeFolderId),
  );
}
