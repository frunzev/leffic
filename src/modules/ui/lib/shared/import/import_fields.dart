import 'package:flutter/widgets.dart';

class ImportFields {
  final TextEditingController link = TextEditingController();
  final TextEditingController pastedText = TextEditingController();
  final TextEditingController topic = TextEditingController();
  final TextEditingController firstPage = TextEditingController();
  final TextEditingController lastPage = TextEditingController();
  final TextEditingController reviewedText = TextEditingController();

  void dispose() {
    link.dispose();
    pastedText.dispose();
    topic.dispose();
    firstPage.dispose();
    lastPage.dispose();
    reviewedText.dispose();
  }
}
