import 'package:flutter/material.dart';

import '../../shared/api/chat_api.dart';
import '../../shared/api/chat_models.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_modal.dart';
import '../../shared/widgets/load_view.dart';
import 'flashcard_faces.dart';
import 'mnemonic_prompt.dart';

Future<void> showMnemonicDialog({
  required BuildContext context,
  required ChatApi chatApi,
  required FlashcardFace face,
}) {
  return showDesignModal<void>(
    context: context,
    builder: (context) => MnemonicDialog(chatApi: chatApi, face: face),
  );
}

class MnemonicDialog extends StatelessWidget {
  const MnemonicDialog({required this.chatApi, required this.face, super.key});

  final ChatApi chatApi;
  final FlashcardFace face;

  Future<String> _askForMnemonic() {
    final prompt = mnemonicPrompt(question: face.question, answer: face.answer);
    final question = ChatMessage(role: ChatRole.user, content: prompt);

    return chatApi.ask([question]);
  }

  @override
  Widget build(BuildContext context) {
    return DesignModal(
      title: mnemonicTitle(face.question),
      width: ModalWidth.wide,
      body: LoadView<String>(
        load: _askForMnemonic,
        builder: (context, mnemonic, reload) => SelectableText(mnemonic),
      ),
      actions: [
        DesignButton(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
