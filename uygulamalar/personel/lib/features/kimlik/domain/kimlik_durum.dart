import 'package:supabase_flutter/supabase_flutter.dart';

sealed class KimlikDurum {
  const KimlikDurum();
}

class KimlikYukleniyor extends KimlikDurum {
  const KimlikYukleniyor();
}

class KimlikGirilmemis extends KimlikDurum {
  const KimlikGirilmemis();
}

class KimlikDogrulaniyor extends KimlikDurum {
  final User user;
  const KimlikDogrulaniyor(this.user);
}

/// owner_claims.status != 'approved'
class KimlikYetkisiz extends KimlikDurum {
  final String? mesaj;
  const KimlikYetkisiz({this.mesaj});
}

class KimlikGirilmis extends KimlikDurum {
  final User user;
  final String isletmeId;
  final String isletmeAdi;
  const KimlikGirilmis({
    required this.user,
    required this.isletmeId,
    required this.isletmeAdi,
  });
}
