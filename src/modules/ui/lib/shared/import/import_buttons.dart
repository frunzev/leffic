import 'package:flutter/material.dart';

import '../design/button_look.dart';
import '../design/design_button.dart';
import 'import_plan.dart';
import 'import_source.dart';

const String _generateLabel = 'Generate';
const String _continueLabel = 'Continue';

class GenerateButton extends StatelessWidget {
  const GenerateButton({required this.plan, required this.onFinish, super.key});

  final GenerationPlan? plan;
  final ValueChanged<ImportPlan> onFinish;

  @override
  Widget build(BuildContext context) {
    final readyPlan = plan;
    VoidCallback? generate;

    if (readyPlan != null) {
      generate = () => onFinish(readyPlan);
    }

    return DesignButton(
      label: _generateLabel,
      variant: ButtonVariant.primary,
      onPressed: generate,
    );
  }
}

class ContinueButton extends StatelessWidget {
  const ContinueButton({
    required this.readySource,
    required this.onRead,
    super.key,
  });

  final ImportSource? readySource;
  final ValueChanged<ImportSource> onRead;

  @override
  Widget build(BuildContext context) {
    final source = readySource;
    VoidCallback? readSource;

    if (source != null) {
      readSource = () => onRead(source);
    }

    return DesignButton(
      label: _continueLabel,
      variant: ButtonVariant.primary,
      onPressed: readSource,
    );
  }
}
