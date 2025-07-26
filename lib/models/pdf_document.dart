class PDFDocument {
  final String path;
  final String name;
  final int totalPages;
  final int currentPage;
  final DateTime lastOpened;
  final int fileSize;

  PDFDocument({
    required this.path,
    required this.name,
    required this.totalPages,
    this.currentPage = 1,
    required this.lastOpened,
    required this.fileSize,
  });

  PDFDocument copyWith({
    String? path,
    String? name,
    int? totalPages,
    int? currentPage,
    DateTime? lastOpened,
    int? fileSize,
  }) {
    return PDFDocument(
      path: path ?? this.path,
      name: name ?? this.name,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      lastOpened: lastOpened ?? this.lastOpened,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'lastOpened': lastOpened.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  factory PDFDocument.fromJson(Map<String, dynamic> json) {
    return PDFDocument(
      path: json['path'] as String,
      name: json['name'] as String,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int? ?? 1,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
      fileSize: json['fileSize'] as int,
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize} B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  double get readingProgress {
    if (totalPages == 0) return 0.0;
    return currentPage / totalPages;
  }
}
