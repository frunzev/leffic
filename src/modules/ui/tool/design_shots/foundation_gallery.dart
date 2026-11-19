import 'package:flutter/material.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/choice_marks.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_divider.dart';
import 'package:leffic/shared/design/design_dropdown.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/design_metrics.dart';
import 'package:leffic/shared/design/design_text_field.dart';
import 'package:leffic/shared/design/hint_tip.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/meter.dart';
import 'package:leffic/shared/design/section_label.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/design/shortcut_chip.dart';
import 'package:leffic/shared/design/spinner.dart';
import 'package:leffic/shared/design/toast.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/captioned_spinner.dart';

const double _columnWidth = 400;
const List<String> _sourceKinds = ['File', 'Link', 'Text', 'Topic'];
const List<String> _engines = ['Claude Code on this Mac', 'OpenAI'];

void _press() {}

void _choose(String choice) {}

void _check(bool isChecked) {}

String _labelOf(String choice) => choice;

Widget _section(String title, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: Spacing.step3,
    children: [SectionLabel(title), ...children],
  );
}

Widget _buttonRow(VoidCallback? onPressed) {
  return Wrap(
    spacing: Spacing.step2,
    runSpacing: Spacing.step2,
    children: [
      DesignButton(label: 'Default', onPressed: onPressed),
      DesignButton(
        label: 'Primary',
        variant: ButtonVariant.primary,
        onPressed: onPressed,
      ),
      DesignButton(
        label: 'Quiet',
        variant: ButtonVariant.quiet,
        onPressed: onPressed,
      ),
      DesignButton(
        label: 'Danger',
        variant: ButtonVariant.danger,
        onPressed: onPressed,
      ),
      DesignButton(
        label: 'Remove',
        variant: ButtonVariant.dangerOutline,
        onPressed: onPressed,
      ),
    ],
  );
}

Widget _buttons() {
  return _section('Buttons', [
    _buttonRow(_press),
    _buttonRow(null),
    const Wrap(
      spacing: Spacing.step2,
      runSpacing: Spacing.step2,
      children: [
        DesignButton(
          label: 'Import',
          icon: DesignIcons.aiImport,
          variant: ButtonVariant.primary,
          size: ButtonSize.large,
          onPressed: _press,
        ),
        DesignButton(
          label: 'Show answer',
          variant: ButtonVariant.primary,
          trailing: ShortcutChip(
            label: 'Space',
            tone: ShortcutChipTone.onBrand,
          ),
          onPressed: _press,
        ),
        DesignButton(
          label: 'New folder',
          icon: DesignIcons.newFolder,
          onPressed: _press,
        ),
      ],
    ),
    const Row(
      spacing: Spacing.step2,
      children: [
        DesignIconButton(
          icon: DesignIcons.dots,
          semanticLabel: 'More',
          variant: ButtonVariant.quiet,
          onPressed: _press,
        ),
        DesignIconButton(
          icon: DesignIcons.closePlain,
          semanticLabel: 'Close',
          onPressed: _press,
        ),
        DesignIconButton(
          icon: DesignIcons.send,
          semanticLabel: 'Send',
          variant: ButtonVariant.primary,
          dimension: ControlHeights.small,
          borderRadius: Radii.pill,
          onPressed: _press,
        ),
        ShortcutChip(label: '1', tone: ShortcutChipTone.plain),
      ],
    ),
  ]);
}

Widget _fields() {
  return _section('Fields', [
    DesignField(
      label: 'Folder name',
      input: DesignTextField(
        controller: TextEditingController(),
        placeholder: 'e.g. Neuroscience',
      ),
    ),
    DesignField(
      label: 'Page address',
      hint: 'Leffic reads the page and uses only what is on it.',
      input: DesignTextField(
        controller: TextEditingController(text: 'https://en.wikipedia.org'),
      ),
    ),
    DesignField(
      label: 'Username',
      error: 'That username is taken. Try vlad2 or vlad-neuro.',
      input: DesignTextField(
        controller: TextEditingController(text: 'vlad'),
        size: TextFieldSize.large,
        validity: FieldValidity.invalid,
      ),
    ),
    DesignField(
      label: 'Front',
      input: DesignTextArea(
        controller: TextEditingController(
          text: 'What is the resting membrane potential of a neuron?',
        ),
      ),
    ),
    const Row(
      spacing: Spacing.step3,
      children: [
        DesignCheckbox(isChecked: true, onChanged: _check),
        DesignCheckbox(isChecked: false, onChanged: _check),
        DesignRadio<String>(value: 'a', groupValue: 'a', onChanged: _choose),
        DesignRadio<String>(value: 'b', groupValue: 'a', onChanged: _choose),
      ],
    ),
  ]);
}

Widget _feedback() {
  return _section('Choices and feedback', [
    const SegmentedControl<String>(
      choices: _sourceKinds,
      labelOf: _labelOf,
      selected: 'Link',
      onSelected: _choose,
    ),
    const SegmentedControl<String>(
      choices: _engines,
      labelOf: _labelOf,
      selected: 'OpenAI',
      onSelected: _choose,
      size: SegmentedSize.large,
    ),
    const MeterBlock(
      startLabel: 'Reviewed 21 of 50',
      endLabel: '29 left',
      fraction: 0.42,
    ),
    const Row(
      spacing: Spacing.step5,
      children: [
        Spinner(),
        CaptionedSpinner(label: 'Opening action-potentials.pdf…'),
        HintTip(
          text: 'The key stays in the macOS Keychain on this Mac.',
          semanticLabel: 'Where the key lives',
        ),
      ],
    ),
    const DropdownPanel(
      children: [
        DropdownItem(
          icon: DesignIcons.study,
          label: 'Review now',
          hint: '12 due',
          onPressed: _press,
        ),
        DropdownItem(
          icon: DesignIcons.folderOpen,
          label: 'Move to folder',
          onPressed: _press,
        ),
        DesignDivider(),
        DropdownItem(
          icon: DesignIcons.trash,
          label: 'Delete deck',
          tone: DropdownTone.danger,
          onPressed: _press,
        ),
      ],
    ),
    Toast(
      message: const ToastMessage(
        tone: ToastTone.success,
        title: '30 flashcards ready',
      ),
      onDismiss: _press,
    ),
  ]);
}

class FoundationGallery extends StatelessWidget {
  const FoundationGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedRoute: Routes.folder,
      body: Padding(
        padding: const EdgeInsets.all(Spacing.step6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.step6,
          children: [
            SizedBox(width: _columnWidth, child: _buttons()),
            SizedBox(width: _columnWidth, child: _fields()),
            SizedBox(width: _columnWidth, child: _feedback()),
          ],
        ),
      ),
    );
  }
}
