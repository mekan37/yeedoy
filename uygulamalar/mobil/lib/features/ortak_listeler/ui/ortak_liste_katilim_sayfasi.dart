import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../../../features/shared/ui/bilesenler/uygulama_iskele.dart';
import '../data/ortak_liste_deposu.dart';

class CollabListJoinPage extends ConsumerStatefulWidget {
  const CollabListJoinPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<CollabListJoinPage> createState() => _CollabListJoinPageState();
}

class _CollabListJoinPageState extends ConsumerState<CollabListJoinPage> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _join() async {
    if (widget.token.isEmpty) {
      setState(() => _error = 'Invalid invite link.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listId = await ref
          .read(collabListRepositoryProvider)
          .joinViaToken(widget.token);
      if (mounted) context.go('/ortak-listeler/$listId');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppErrorMapper.message(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppAppBar(title: Text(t.collabListJoining)),
      body: Center(
        child: _loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(t.collabListJoining),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(_error ?? t.collabListInvalidInvite),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => context.go('/ortak-listeler'),
                    child: Text(t.goToMyLists),
                  ),
                ],
              ),
      ),
    );
  }
}



