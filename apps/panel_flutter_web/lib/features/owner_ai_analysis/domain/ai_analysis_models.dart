class AiOcrJob {
  const AiOcrJob({
    required this.id,
    required this.fileUrl,
    this.fileName,
    required this.status,
    this.itemCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fileUrl;
  final String? fileName;
  final String status; // queued | processing | completed | failed
  final int? itemCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'queued' || status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory AiOcrJob.fromMap(Map<String, dynamic> map) {
    return AiOcrJob(
      id: map['id'] as String,
      fileUrl: map['file_url'] as String,
      fileName: map['file_name'] as String?,
      status: map['status'] as String,
      itemCount: map['item_count'] as int?,
      errorMessage: map['error_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class AiAnalysisItem {
  const AiAnalysisItem({
    required this.id,
    this.ocrJobId,
    required this.sourceText,
    this.normalizedText,
    required this.ingredients,
    required this.allergens,
    this.calorieMin,
    this.calorieMax,
    required this.confidence,
    required this.requiresReview,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String? ocrJobId;
  final String sourceText;
  final String? normalizedText;
  final List<String> ingredients;
  final List<String> allergens;
  final int? calorieMin;
  final int? calorieMax;
  final double confidence;
  final bool requiresReview;
  final String status; // pending_review | approved | rejected
  final DateTime createdAt;

  String get displayName => normalizedText?.isNotEmpty == true ? normalizedText! : sourceText;

  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.90) return ConfidenceLevel.high;
    if (confidence >= 0.70) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  factory AiAnalysisItem.fromMap(Map<String, dynamic> map) {
    List<String> toStringList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return AiAnalysisItem(
      id: map['id'] as String,
      ocrJobId: map['ocr_job_id'] as String?,
      sourceText: map['source_text'] as String,
      normalizedText: map['normalized_text'] as String?,
      ingredients: toStringList(map['ingredients_json']),
      allergens: toStringList(map['allergens_json']),
      calorieMin: map['calorie_min'] as int?,
      calorieMax: map['calorie_max'] as int?,
      confidence: (map['confidence'] as num).toDouble(),
      requiresReview: map['requires_review'] as bool,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum ConfidenceLevel { high, medium, low }
