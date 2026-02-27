class MicrocopyStyleGuide {
  const MicrocopyStyleGuide._();

  // Action verbs: always use the same verb for the same intent.
  static const String save = 'Kaydet';
  static const String cancel = 'Vazgeç';
  static const String retry = 'Tekrar dene';
  static const String approve = 'Onayla';
  static const String reject = 'Reddet';
  static const String delete = 'Sil';
  static const String close = 'Kapat';

  // Empty-state task prompts.
  static const String addFirstMenu = 'İlk menüyü ekle';
  static const String verifyPrice = 'Fiyatı doğrula';

  static const Map<String, String> canonicalByIntent = <String, String>{
    'save': save,
    'cancel': cancel,
    'retry': retry,
    'approve': approve,
    'reject': reject,
    'delete': delete,
    'close': close,
  };

  static bool isCanonical({required String intent, required String text}) {
    final canonical = canonicalByIntent[intent];
    if (canonical == null) return false;
    return canonical == text.trim();
  }
}

