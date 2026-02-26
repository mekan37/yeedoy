import 'package:flutter/material.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? semanticLabel,
    bool scrollControlled = true,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: scrollControlled,
      showDragHandle: showDragHandle,
      builder: (_) => SafeArea(
        child: Semantics(container: true, label: semanticLabel, child: child),
      ),
    );
  }
}
