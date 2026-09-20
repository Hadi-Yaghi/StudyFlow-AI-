class CourseMaterial {
  final int id;
  final int courseId;
  final String originalFilename;
  final String mimeType;
  final int fileSize;
  final DateTime uploadedAt;
  final String processingStatus;

  CourseMaterial({
    required this.id,
    required this.courseId,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
    required this.processingStatus,
  });

  factory CourseMaterial.fromJson(Map<String, dynamic> json) {
    return CourseMaterial(
      id: (json['id'] as num?)?.toInt() ?? 0,
      courseId: (json['courseId'] as num?)?.toInt() ?? 0,
      originalFilename: json['originalFilename'] as String? ??
          json['filename'] as String? ??
          json['fileName'] as String? ??
          'Untitled',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString()) ?? DateTime.now()
          : (json['uploadDate'] != null
              ? DateTime.tryParse(json['uploadDate'].toString()) ?? DateTime.now()
              : DateTime.now()),
      processingStatus: json['processingStatus'] as String? ??
          json['status'] as String? ??
          'PROCESSED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'originalFilename': originalFilename,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'processingStatus': processingStatus,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileExtension {
    final dotIndex = originalFilename.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < originalFilename.length - 1) {
      return originalFilename.substring(dotIndex + 1).toUpperCase();
    }
    return 'FILE';
  }
}
