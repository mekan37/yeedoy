import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminKeyboardShortcuts extends StatelessWidget {
  const AdminKeyboardShortcuts({
    super.key,
    required this.child,
    required this.onNext,
    required this.onPrev,
    required this.onToggleModal,
    required this.onCloseModal,
    required this.onFocusSearch,
    required this.onAssignToggle,
    required this.onAction,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onToggleModal;
  final VoidCallback onCloseModal;
  final VoidCallback onFocusSearch;
  final VoidCallback onAssignToggle;
  final ValueChanged<String> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !enabled) return child;

    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.keyJ): _AdminIntent('next'),
          SingleActivator(LogicalKeyboardKey.keyK): _AdminIntent('prev'),
          SingleActivator(LogicalKeyboardKey.enter): _AdminIntent('toggle'),
          SingleActivator(LogicalKeyboardKey.escape): _AdminIntent('close'),
          SingleActivator(LogicalKeyboardKey.slash): _AdminIntent('search'),
          SingleActivator(LogicalKeyboardKey.keyA): _AdminIntent('assign'),
          SingleActivator(LogicalKeyboardKey.keyR): _AdminIntent('R'),
          SingleActivator(LogicalKeyboardKey.keyI): _AdminIntent('I'),
          SingleActivator(LogicalKeyboardKey.keyC): _AdminIntent('C'),
          SingleActivator(LogicalKeyboardKey.keyP): _AdminIntent('P'),
          SingleActivator(LogicalKeyboardKey.keyN): _AdminIntent('N'),
          SingleActivator(LogicalKeyboardKey.keyL): _AdminIntent('L'),
        },
        child: Actions(
          actions: {
            _AdminIntent: CallbackAction<_AdminIntent>(
              onInvoke: (intent) {
                if (_isEditingText()) return null;
                switch (intent.key) {
                  case 'next':
                    onNext();
                    break;
                  case 'prev':
                    onPrev();
                    break;
                  case 'toggle':
                    onToggleModal();
                    break;
                  case 'close':
                    onCloseModal();
                    break;
                  case 'search':
                    onFocusSearch();
                    break;
                  case 'assign':
                    onAssignToggle();
                    break;
                  default:
                    onAction(intent.key);
                }
                return null;
              },
            ),
          },
          child: child,
        ),
      ),
    );
  }
}

class _AdminIntent extends Intent {
  const _AdminIntent(this.key);
  final String key;
}

bool _isEditingText() {
  final focus = FocusManager.instance.primaryFocus;
  final ctx = focus?.context;
  if (ctx == null) return false;
  return ctx.widget is EditableText;
}
