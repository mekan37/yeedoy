import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/colors.dart';
import '../../shared/ui/design_system.dart';
import '../data/receipt_upload_repository.dart';

/// Bottom sheet for optionally uploading a receipt / price-evidence photo.
///
/// Usage:
/// ```dart
/// final url = await showModalBottomSheet<String?>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => ReceiptUploadSheet(businessId: businessId),
/// );
/// ```
///
/// Returns the uploaded public URL on success, or `null` if the user dismissed
/// without uploading.
class ReceiptUploadSheet extends ConsumerStatefulWidget {
  const ReceiptUploadSheet({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<ReceiptUploadSheet> createState() => _ReceiptUploadSheetState();
}

class _ReceiptUploadSheetState extends ConsumerState<ReceiptUploadSheet> {
  final _picker = ImagePicker();

  Uint8List? _selectedBytes;
  String _selectedMimeType = 'image/jpeg';
  bool _uploading = false;
  String? _uploadedUrl;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Makbuz / Fiyat Kanıtı Yükle', style: context.sectionTitleStyle),
            const SizedBox(height: 4),
            const Text(
              'Fotoğraf isteğe bağlıdır. Yükleme yapmadan da devam edebilirsiniz.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_selectedBytes == null) _buildSourcePicker(),
            if (_selectedBytes != null) _buildPreview(),
            const SizedBox(height: 16),
            if (_selectedBytes != null && _uploadedUrl == null) _buildUploadButton(),
            if (_uploadedUrl != null) _buildSuccessBadge(),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(_uploadedUrl),
                child: Text(_uploadedUrl != null ? 'Kapat' : 'Şimdi değil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcePicker() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _uploading ? null : () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Fotoğraf Çek'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _uploading ? null : () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Galeriden Seç'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _selectedBytes!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        TextButton.icon(
          onPressed: _uploading ? null : _clearSelection,
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Kaldır'),
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _uploading ? null : _upload,
        child: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimary,
                ),
              )
            : const Text('Yükle'),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return const Row(
      children: [
        Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
        SizedBox(width: 6),
        Text('Makbuz yüklendi', style: TextStyle(color: AppColors.success)),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? 'image/jpeg';
      if (!mounted) return;
      setState(() {
        _selectedBytes = bytes;
        _selectedMimeType = mimeType;
        _uploadedUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedBytes = null;
      _selectedMimeType = 'image/jpeg';
      _uploadedUrl = null;
    });
  }

  Future<void> _upload() async {
    final bytes = _selectedBytes;
    if (bytes == null) return;

    final repo = ref.read(receiptUploadRepositoryProvider);
    final userId = repo.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yüklemek için oturum açmanız gerekiyor.'),
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final url = await repo.uploadReceipt(
        userId: userId,
        businessId: widget.businessId,
        bytes: bytes,
        mimeType: _selectedMimeType,
      );
      if (!mounted) return;
      setState(() => _uploadedUrl = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Makbuz yüklendi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Yükleme başarısız: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
