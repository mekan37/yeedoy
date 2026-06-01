import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class OyVeItem {
  final String id;
  final String businessId;
  final String isletmeAdi;
  final String? slug;
  final String? kategori;
  final String? konum;
  int upVotes;
  int downVotes;
  int? userVote; // 1, -1 veya null

  OyVeItem({
    required this.id,
    required this.businessId,
    required this.isletmeAdi,
    this.slug,
    this.kategori,
    this.konum,
    this.upVotes = 0,
    this.downVotes = 0,
    this.userVote,
  });
}

class _OyVerState {
  final String listeId;
  final String listAdi;
  final String? aciklama;
  final List<OyVeItem> items;
  final bool loading;
  final String? hata;

  const _OyVerState({
    required this.listeId,
    required this.listAdi,
    this.aciklama,
    required this.items,
    this.loading = false,
    this.hata,
  });

  _OyVerState copyWith({List<OyVeItem>? items, bool? loading, String? hata}) =>
      _OyVerState(
        listeId: listeId,
        listAdi: listAdi,
        aciklama: aciklama,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        hata: hata ?? this.hata,
      );
}

// ─── Sayfa ───────────────────────────────────────────────────────────────────

class OyVerSayfasi extends StatefulWidget {
  const OyVerSayfasi({super.key, required this.token});
  final String token;

  @override
  State<OyVerSayfasi> createState() => _OyVerSayfasiState();
}

class _OyVerSayfasiState extends State<OyVerSayfasi> {
  _OyVerState? _state;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final supabase = Supabase.instance.client;

      final listeRes =
          await (supabase as dynamic)
                  .from('collab_lists')
                  .select('id, name, description')
                  .eq('invite_token', widget.token)
                  .single()
              as Map<String, dynamic>;

      final listeId = listeRes['id'] as String;
      final listAdi = listeRes['name'] as String;
      final aciklama = listeRes['description'] as String?;

      final kalemRes =
          await (supabase as dynamic)
                  .from('collab_list_items')
                  .select(
                    'id, business_id, businesses(name, slug, category, city, district)',
                  )
                  .eq('list_id', listeId)
              as List<dynamic>;

      final oyRes =
          await (supabase as dynamic)
                  .from('collab_list_votes')
                  .select('item_id, vote')
                  .eq('list_id', listeId)
              as List<dynamic>;

      // Oy sayılarını grupla
      final oyMap = <String, Map<String, int>>{};
      for (final oy in oyRes) {
        final itemId = oy['item_id'] as String;
        final vote = oy['vote'] as int;
        oyMap.putIfAbsent(itemId, () => {'up': 0, 'down': 0});
        if (vote == 1) {
          oyMap[itemId]!['up'] = (oyMap[itemId]!['up'] ?? 0) + 1;
        }
        if (vote == -1) {
          oyMap[itemId]!['down'] = (oyMap[itemId]!['down'] ?? 0) + 1;
        }
      }

      final items = kalemRes.map((k) {
        final biz = k['businesses'] as Map<String, dynamic>? ?? {};
        final itemId = k['id'] as String;
        final konum = [
          biz['district'],
          biz['city'],
        ].where((x) => x != null).join(', ');
        return OyVeItem(
          id: itemId,
          businessId: k['business_id'] as String,
          isletmeAdi: biz['name'] as String? ?? '?',
          slug: biz['slug'] as String?,
          kategori: biz['category'] as String?,
          konum: konum.isEmpty ? null : konum,
          upVotes: oyMap[itemId]?['up'] ?? 0,
          downVotes: oyMap[itemId]?['down'] ?? 0,
        );
      }).toList();

      setState(() {
        _state = _OyVerState(
          listeId: listeId,
          listAdi: listAdi,
          aciklama: aciklama,
          items: items,
        );
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  Future<void> _oyCast(OyVeItem item, int vote) async {
    final oncekiVote = item.userVote;
    final yeniVote = oncekiVote == vote ? null : vote;

    // Optimistic update
    setState(() {
      final idx = _state!.items.indexWhere((i) => i.id == item.id);
      if (idx < 0) return;
      final current = _state!.items[idx];
      // Önceki oyu geri al
      if (oncekiVote == 1) {
        current.upVotes = (current.upVotes - 1).clamp(0, 999);
      }
      if (oncekiVote == -1) {
        current.downVotes = (current.downVotes - 1).clamp(0, 999);
      }
      // Yeni oyu ekle
      if (yeniVote == 1) current.upVotes++;
      if (yeniVote == -1) current.downVotes++;
      current.userVote = yeniVote;
    });

    try {
      final supabase = Supabase.instance.client;
      if (yeniVote == null) {
        await (supabase as dynamic)
            .from('collab_list_votes')
            .delete()
            .eq('list_id', _state!.listeId)
            .eq('item_id', item.id);
      } else {
        await (supabase as dynamic).rpc(
          'upsert_collab_vote_v1',
          params: {
            'p_list_id': _state!.listeId,
            'p_item_id': item.id,
            'p_vote': yeniVote,
          },
        );
      }
    } catch (_) {
      _yukle(); // Hata durumunda taze yükle
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        title: Text(_state?.listAdi ?? 'Grup Oyu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _yukle,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.link_off_outlined,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Liste bulunamadı',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Token geçersiz olabilir.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : _state!.items.isEmpty
          ? const Center(child: Text('Bu listede henüz işletme yok.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_state!.aciklama != null &&
                    _state!.aciklama!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _state!.aciklama!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  '${_state!.items.length} seçenek — beğenin veya beğenmeyin',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ..._state!.items.map(
                  (item) =>
                      _OyKarti(item: item, onVote: (v) => _oyCast(item, v)),
                ),
              ],
            ),
    );
  }
}

class _OyKarti extends StatelessWidget {
  const _OyKarti({required this.item, required this.onVote});
  final OyVeItem item;
  final void Function(int) onVote;

  @override
  Widget build(BuildContext context) {
    final totalVotes = item.upVotes + item.downVotes;
    final upPct = totalVotes > 0 ? item.upVotes / totalVotes : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.isletmeAdi,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textStrong,
              ),
            ),
            if (item.kategori != null || item.konum != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  [
                    item.kategori,
                    item.konum,
                  ].where((x) => x != null).join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),

            // Oy bar
            if (totalVotes > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: upPct,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${item.upVotes} ✓',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.downVotes} ✗',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onVote(1),
                    icon: Icon(
                      Icons.thumb_up_outlined,
                      size: 18,
                      color: item.userVote == 1
                          ? AppColors.success
                          : AppColors.muted,
                    ),
                    label: const Text('Gidelim'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: item.userVote == 1
                          ? AppColors.success
                          : AppColors.muted,
                      side: BorderSide(
                        color: item.userVote == 1
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onVote(-1),
                    icon: Icon(
                      Icons.thumb_down_outlined,
                      size: 18,
                      color: item.userVote == -1
                          ? AppColors.danger
                          : AppColors.muted,
                    ),
                    label: const Text('Hayır'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: item.userVote == -1
                          ? AppColors.danger
                          : AppColors.muted,
                      side: BorderSide(
                        color: item.userVote == -1
                            ? AppColors.danger
                            : AppColors.border,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
