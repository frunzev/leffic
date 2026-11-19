import 'package:flutter/material.dart';

class FileStage extends StatelessWidget {
  const FileStage({required this.bar, required this.content, super.key});

  final Widget bar;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        Expanded(child: content),
      ],
    );
  }
}
