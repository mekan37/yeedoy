import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/media/app_network_image.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../domain/owner_menu_controller.dart';

// ─── AI image generation via Edge Function ──────────────────────────────────

Future<_AiImageResult> _callAiImageGen(
  SupabaseClient client,
  String itemName,
) async {
  final res = await client.functions.invoke(
    'ai-menu-image-gen',
    body: {'item_name': itemName},
  );
  final data = res.data as Map<String, dynamic>?;
  if (data == null || data['ok'] != true) {
    final err = data?['error'] ?? 'unknown_error';
    throw Exception(err.toString());
  }
  return _AiImageResult(
    imageUrl: data['image_url'] as String,
    prompt: data['prompt'] as String? ?? '',
  );
}

class _AiImageResult {
  const _AiImageResult({required this.imageUrl, required this.prompt});
  final String imageUrl;
  final String prompt;
}

// ─── Main sheet widget ───────────────────────────────────────────────────────

/// Üç seçenekli fotoğraf ekleme sayfası:
/// 1. Kendi görselini yükle
/// 2. Yapay zeka ile oluştur (Gemma → Pollinations.ai)
class MenuItemImagePickerSheet extends ConsumerStatefulWidget {
  const MenuItemImagePickerSheet({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  final String itemId;
  final String itemName;

  @override
  ConsumerState<MenuItemImagePickerSheet> createState() =>
      _MenuItemImagePickerSheetState();
}

class _MenuItemImagePickerSheetState
    extends ConsumerState<MenuItemImagePickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fotoğraf Ekle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(icon: Icon(Icons.upload_outlined), text: 'Yükle'),
              Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'AI Oluştur'),
            ],
          ),
          SizedBox(
            height: 340,
            child: TabBarView(
              controller: _tab,
              children: [
                _UploadTab(
                  itemId: widget.itemId,
                  onDone: () => Navigator.pop(context, true),
                ),
                _AiGenerateTab(
                  itemId: widget.itemId,
                  itemName: widget.itemName,
                  onDone: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Tab 1: Yükle ───────────────────────────────────────────────────────────

class _UploadTab extends ConsumerStatefulWidget {
  const _UploadTab({required this.itemId, required this.onDone});
  final String itemId;
  final VoidCallback onDone;

  @override
  ConsumerState<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends ConsumerState<_UploadTab> {
  bool _uploading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 48,
            color: AppColors.muted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bilgisayarınızdan veya kameranızdan fotoğraf yükleyin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_outlined),
              label: Text(_uploading ? 'Yükleniyor…' : 'Dosya Seç ve Yükle'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(ownerMenuItemPhotosProvider(widget.itemId).notifier)
          .uploadPhoto();
      if (res != null && mounted) widget.onDone();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

// ─── Tab 2: AI Oluştur ───────────────────────────────────────────────────────

class _AiGenerateTab extends ConsumerStatefulWidget {
  const _AiGenerateTab({
    required this.itemId,
    required this.itemName,
    required this.onDone,
  });
  final String itemId;
  final String itemName;
  final VoidCallback onDone;

  @override
  ConsumerState<_AiGenerateTab> createState() => _AiGenerateTabState();
}

class _AiGenerateTabState extends ConsumerState<_AiGenerateTab> {
  _AiImageResult? _result;
  bool _generating = false;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _PreviewSection(
        result: _result!,
        saving: _saving,
        onRegenerate: _generate,
        onSave: _save,
        generating: _generating,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ürün adı',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gemma AI ürün adından profesyonel yemek fotoğrafı oluşturur.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(
                _generating ? 'Oluşturuluyor…' : 'AI ile Görsel Oluştur',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
      _result = null;
    });
    try {
      final client = ref.read(supabaseProvider);
      final result = await _callAiImageGen(client, widget.itemName);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Görsel oluşturulamadı: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _save() async {
    if (_result == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerMenuItemPhotosProvider(widget.itemId).notifier)
          .addPhotoFromUrl(url: _result!.imageUrl);
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Kaydedilemedi: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.result,
    required this.saving,
    required this.generating,
    required this.onRegenerate,
    required this.onSave,
  });

  final _AiImageResult result;
  final bool saving;
  final bool generating;
  final VoidCallback onRegenerate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AppNetworkImage(
                url: result.imageUrl,
                variant: AppImageVariant.medium,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (result.prompt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.prompt,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (saving || generating) ? null : onRegenerate,
                  icon: generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_outlined, size: 18),
                  label: const Text('Yeniden Oluştur'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (saving || generating) ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_outlined, size: 18),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

