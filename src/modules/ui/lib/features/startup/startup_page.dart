import 'package:flutter/material.dart';

import '../../shared/backend/backend_process.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/widgets/captioned_spinner.dart';
import '../../shared/widgets/load_view.dart';

enum _StartupStage { starting, failed }

class StartupPage extends StatefulWidget {
  const StartupPage({required this.relaunchBackend, super.key});

  final BackendRelauncher relaunchBackend;

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  _StartupStage _stage = _StartupStage.starting;
  String _failure = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    final link = BackendScope.linkOf(context);
    final navigator = Navigator.of(context);

    setState(() => _stage = _StartupStage.starting);

    try {
      await widget.relaunchBackend(link);
    } on BackendStartError catch (failure) {
      if (mounted) {
        setState(() {
          _stage = _StartupStage.failed;
          _failure = failure.message;
        });
      }

      return;
    }

    if (mounted) {
      await navigator.pushReplacementNamed(
        Routes.folder,
        arguments: const UnitArguments(id: homeFolderId),
      );
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
