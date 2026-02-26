import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../data/admin_table_feedback_repository.dart';
import '../domain/admin_table_feedback_models.dart';

class AdminTableFeedbackPage extends ConsumerStatefulWidget {
  const AdminTableFeedbackPage({super.key});

  @override
  ConsumerState<AdminTableFeedbackPage> createState() =>
      _AdminTableFeedbackPageState();
}

class _AdminTableFeedbackPageState
    extends ConsumerState<AdminTableFeedbackPage> {
  final _scrollCtrl = ScrollController();
  bool _loadingMore = false;
  final int _limit = 50;
  int _offset = 0;
  List<AdminTableFeedbackItem> _items = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    try {
      if (reset) {
        _offset = 0;
        _items = const [];
      }
      final repo = ref.read(adminTableFeedbackRepositoryProvider);
      final data = await repo.listFeedback(limit: _limit, offset: _offset);
      setState(() {
        _error = null;
        _items = [..._items, ...data];
        _offset = _items.length;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Masa Geri Bildirimleri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              AppErrorMapper.message(_error),
              style: const TextStyle(color: AppColors.danger),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _items.isEmpty && _error == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    controller: _scrollCtrl,
                    itemCount: _items.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = _items[index];
                      return ListTile(
                        title: Text(
                          item.businessName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Masa ${item.tableNo} • Puan ${item.rating}'),
                            if (item.note.isNotEmpty)
                              Text(
                                item.note,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${_fmtDate(item.createdAt)} • ${item.clientId}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'İşletme',
                          onPressed: () =>
                              _openBusiness(context, item.businessId),
                          icon: const Icon(Icons.open_in_new),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openBusiness(BuildContext context, String businessId) {
    if (businessId.isEmpty) return;
    context.go('/b/$businessId');
  }
}

String _fmtDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
