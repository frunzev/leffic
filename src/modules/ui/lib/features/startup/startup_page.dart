import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/backend/backend_process.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/settings/openai_key_store.dart';
import '../../shared/widgets/captioned_spinner.dart';
import '../../shared/widgets/load_view.dart';
import 'backend_launch.dart';

enum _StartupStage { starting, failed }

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  static const OpenAiKeyStore _keyStore = OpenAiKeyStore(runCommand);

  _StartupStage _stage = _StartupStage.starting;
  String _failure = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    final link = BackendScope.linkOf(context);

    setState(() => _stage = _StartupStage.starting);

    final openAiKey = await _keyStore.readKey();

    await link.disconnect();

    try {
      final dataDirectory = await getApplicationSupportDirectory();
      final launched = await launchBackend(
        dataDirectory: dataDirectory,
        openAiKey: openAiKey,
      );

      if (!mounted) {
        await launched.running.stop();
        return;
      }

      link.connect(launched.client, launched.running);
      await Navigator.of(context).pushReplacementNamed(
        Routes.folder,
        arguments: const UnitArguments(id: homeFolderId),
      );
    } on BackendStartError catch (failure) {
      setState(() {
        _stage = _StartupStage.failed;
        _failure = failure.message;
      });
    }
  }

  Widget _stageView() {
    return switch (_stage) {
      _StartupStage.starting => const CaptionedSpinner(
        label: 'Starting Leffic...',
      ),
      _StartupStage.failed => FailureView(message: _failure, onRetry: _begin),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _stageView(),
        ),
      ),
    );
  }
}
