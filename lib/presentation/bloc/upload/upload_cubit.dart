import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'upload_state.dart';

class UploadCubit extends Cubit<UploadState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  PlatformFile? _audioFile;
  PlatformFile? _coverFile;

  UploadCubit() : super(const UploadIdle());

  String? get _uid => _supabase.auth.currentUser?.id;

  // ── Bước 1: Chọn file âm thanh ───────────────────────────────────────────
  Future<void> pickAudioFile() async {
    emit(const UploadPickingFile());
    try {
      // file_picker 11.x: FilePicker.pickFiles() là static method trực tiếp
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        emit(const UploadIdle());
        return;
      }

      _audioFile = result.files.first;
      emit(UploadFilePicked(
        fileName: _audioFile!.name,
        fileSizeBytes: _audioFile!.size,
        filePath: _audioFile!.path ?? _audioFile!.name,
      ));
    } catch (e) {
      emit(UploadError('Không thể chọn file: $e'));
    }
  }

  // ── Bước 2 (tùy chọn): Chọn ảnh bìa ─────────────────────────────────────
  Future<void> pickCoverImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      _coverFile = result.files.first;

      final currentState = state;
      if (currentState is UploadFilePicked) {
        emit(UploadCoverPicked(
          audioPath: currentState.filePath,
          audioSizeBytes: currentState.fileSizeBytes,
          coverName: _coverFile!.name,
          coverBytes: _coverFile!.bytes, // bytes để preview trên web
        ));
      }
    } catch (_) {}
  }

  // ── Bước 3: Upload lên Supabase ───────────────────────────────────────────
  Future<void> upload({
    required String title,
    required String artist,
    String? album,
  }) async {
    final uid = _uid;
    if (uid == null) {
      emit(const UploadError('Bạn cần đăng nhập để upload nhạc'));
      return;
    }

    final audioFile = _audioFile;
    if (audioFile == null) {
      emit(const UploadError('Chưa chọn file nhạc'));
      return;
    }

    final audioBytes = audioFile.bytes;
    if (audioBytes == null) {
      emit(const UploadError('Không đọc được dữ liệu file nhạc'));
      return;
    }

    try {
      String? coverPublicUrl;

      // 1. Upload ảnh bìa (nếu có)
      final coverFile = _coverFile;
      if (coverFile != null && coverFile.bytes != null) {
        emit(UploadInProgress(
          progress: 0,
          bytesSent: 0,
          totalBytes: coverFile.size,
          phase: 'cover',
        ));
        final coverExt = coverFile.extension ?? 'jpg';
        final coverPath = '$uid/${_uuid.v4()}.$coverExt';
        await _supabase.storage.from('user-covers').uploadBinary(
          coverPath,
          coverFile.bytes!,
          fileOptions: FileOptions(contentType: _mimeType(coverExt, isAudio: false), upsert: false),
        );
        coverPublicUrl = _supabase.storage.from('user-covers').getPublicUrl(coverPath);
      }

      // 2. Upload audio
      final audioExt = audioFile.extension ?? 'mp3';
      final audioPath = '$uid/${_uuid.v4()}.$audioExt';

      emit(UploadInProgress(
        progress: 0.0,
        bytesSent: 0,
        totalBytes: audioFile.size,
        phase: 'audio',
      ));

      await _supabase.storage.from('user-audio').uploadBinary(
        audioPath,
        audioBytes,
        fileOptions: FileOptions(contentType: _mimeType(audioExt, isAudio: true), upsert: false),
      );

      emit(UploadInProgress(
        progress: 1.0,
        bytesSent: audioFile.size,
        totalBytes: audioFile.size,
        phase: 'audio',
      ));

      final audioPublicUrl = _supabase.storage.from('user-audio').getPublicUrl(audioPath);

      // 3. Insert metadata (status = 'pending', chờ admin duyệt)
      await _supabase.from('user_songs').insert({
        'user_id': uid,
        'title': title.trim(),
        'artist': artist.trim().isEmpty ? 'Unknown' : artist.trim(),
        'album': (album?.trim().isEmpty ?? true) ? null : album?.trim(),
        'audio_url': audioPublicUrl,
        'art_url': coverPublicUrl,
        'file_size': audioFile.size,
        'status': 'pending',
      });

      _audioFile = null;
      _coverFile = null;

      emit(UploadSuccess(songTitle: title));
    } on StorageException catch (e) {
      emit(UploadError('Lỗi upload: ${e.message}'));
    } catch (e) {
      emit(UploadError('Lỗi không xác định: $e'));
    }
  }

  void reset() {
    _audioFile = null;
    _coverFile = null;
    emit(const UploadIdle());
  }

  /// Map file extension sang MIME type chuẩn
  String _mimeType(String ext, {required bool isAudio}) {
    if (isAudio) {
      return const {
        'mp3': 'audio/mpeg',
        'mpeg': 'audio/mpeg',
        'm4a': 'audio/mp4',
        'mp4': 'audio/mp4',
        'wav': 'audio/wav',
        'ogg': 'audio/ogg',
        'flac': 'audio/flac',
        'aac': 'audio/aac',
        'webm': 'audio/webm',
      }[ext.toLowerCase()] ?? 'audio/mpeg';
    } else {
      return const {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
        'gif': 'image/gif',
        'heic': 'image/heic',
      }[ext.toLowerCase()] ?? 'image/jpeg';
    }
  }
}
