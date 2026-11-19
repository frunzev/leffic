import 'package:flutter/material.dart';

import '../design/design_button.dart';
import '../design/icons/design_icons.dart';
import '../design/spinner.dart';
import '../design/state_block.dart';

const String _failureTitle = "Couldn't load this";

typedef LoadingBuilder = Widget Function(
  BuildContext context,
  VoidCallback reload,
);

Widget _centredSpinner(BuildContext context, VoidCallback reload) {
  return const Center(child: Spinner());
}

class LoadView<T> extends StatefulWidget {
  const LoadView({
    required this.load,
    required this.builder,
    this.placeholder = _centredSpinner,
    super.key,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T value, VoidCallback reload)
  builder;
  final LoadingBuilder placeholder;

  @override
  State<LoadView<T>> createState() => _LoadViewState<T>();
}

class _LoadViewState<T> extends State<LoadView<T>> {
  late Future<T> _loading = widget.load();

  void _reload() {
    final loading = widget.load();

    loading.ignore();
    setState(() {
      _loading = loading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FailureView(message: '${snapshot.error}', onRetry: _reload);
        }

        if (!snapshot.hasData) {
          return widget.placeholder(context, _reload);
        }

        return widget.builder(context, snapshot.requireData, _reload);
      },
    );
  }
}

class FailureView extends StatelessWidget {
  const FailureView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StateBlock(
        icon: DesignIcons.failure,
        title: _failureTitle,
        text: message,
        action: DesignButton(label: 'Try again', onPressed: onRetry),
      ),
    );
  }
}
