import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class UploadState extends Equatable {
  const UploadState();
  @override
  List<Object?> get props => [];
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

class UploadPickingFile extends UploadState {
  const UploadPickingFile();
}

class UploadFilePicked extends UploadState {
  final String fileName;
  final int fileSizeBytes;
  final String filePath;

  const UploadFilePicked({
    required this.fileName,
    required this.fileSizeBytes,
    required this.filePath,
  });

  // Cảnh báo nếu > 50 MB
  bool get isLargeFile => fileSizeBytes > 50 * 1024 * 1024;

  String get fileSizeMB => '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  List<Object?> get props => [filePath, fileSizeBytes];
}

class UploadPickingCover extends UploadState {
  final String filePath;
  final int fileSizeBytes;

  const UploadPickingCover({required this.filePath, required this.fileSizeBytes});

  @override
  List<Object?> get props => [filePath];
}

class UploadCoverPicked extends UploadState {
  final String audioPath;
  final int audioSizeBytes;
  final String coverName;        // tên file (chỉ để hiển thị)
  final Uint8List? coverBytes;   // bytes để preview Image.memory

  const UploadCoverPicked({
    required this.audioPath,
    required this.audioSizeBytes,
    required this.coverName,
    this.coverBytes,
  });

  @override
  List<Object?> get props => [audioPath, coverName];
}

class UploadInProgress extends UploadState {
  final double progress;       // 0.0 – 1.0
  final int bytesSent;
  final int totalBytes;
  final String phase;          // 'cover' | 'audio'

  const UploadInProgress({
    required this.progress,
    required this.bytesSent,
    required this.totalBytes,
    required this.phase,
  });

  String get sentMB => '${(bytesSent / (1024 * 1024)).toStringAsFixed(1)} MB';
  String get totalMB => '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  List<Object?> get props => [progress, phase];
}

class UploadSuccess extends UploadState {
  final String songTitle;
  const UploadSuccess({required this.songTitle});
  @override
  List<Object?> get props => [songTitle];
}

class UploadError extends UploadState {
  final String message;
  const UploadError(this.message);
  @override
  List<Object?> get props => [message];
}
