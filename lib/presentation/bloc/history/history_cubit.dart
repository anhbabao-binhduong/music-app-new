import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_app/core/constants/hive_constants.dart';

/// Lưu tối đa 50 bài nghe gần nhất, không trùng lặp.
/// Mỗi user có Hive key riêng, tránh chồng chéo dữ liệu khi đổi tài khoản.
class HistoryCubit extends Cubit<List<MediaItem>> {
  static const _maxHistory = 50;

  // Tránh ghi đè state khi đang thực hiện thao tác xóa bài
  bool _isModifying = false;

  // Debounce: tránh gọi addSong liên tục mỗi tick
  String? _lastAddedSongId;
  DateTime? _lastAddedAt;

  HistoryCubit() : super([]) {
    _loadHiveThenSync();
  }

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);
  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  String _hiveKey(String userId) => 'listening_history_$userId';

  void _loadHiveThenSync() {
    final userId = _userId;
    if (userId != null) {
      _loadFromHive(userId);
    }
    _syncFromSupabase();
    // Giảm bớt retry delay hoặc bỏ hẳn nếu không cần thiết
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isModifying) _syncFromSupabase();
    });
  }

  void _loadFromHive(String userId) {
    try {
      final raw = _box.get(_hiveKey(userId));
      if (raw == null) return;
      final List decoded = jsonDecode(raw as String);
      final items = decoded
          .map((e) => _mapToMediaItem(Map<String, dynamic>.from(e as Map)))
          .toList();
      emit(items.cast<MediaItem>());
    } catch (e) {
      if (kDebugMode) print('[HistoryCubit] load hive error: $e');
    }
  }

  Future<void> _syncFromSupabase() async {
    if (_isModifying) return; // Không sync đè khi đang xóa/thêm
    
    try {
      final userId = _userId;
      if (userId == null) return;

      final res = await _supabase
          .from('listening_history')
          .select()
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(_maxHistory);

      if (_isModifying) return; // Check lại lần nữa sau khi await

      final remoteItems = (res as List).map((row) {
        final Map<String, dynamic> extras = _parseExtras(row['song_extras']);
        return MediaItem(
          id: row['song_id'] as String,
          title: row['song_title'] as String? ?? '',
          artist: _nonEmpty(row['song_artist'] as String?),
          artUri: _parseUri(row['song_art_uri'] as String?),
          duration:
              Duration(milliseconds: (row['song_duration_ms'] as num? ?? 0).toInt()),
          extras: extras,
        );
      }).toList();

      if (remoteItems.isNotEmpty) {
        emit(remoteItems);
        await _saveToHive(userId, remoteItems);
      } else if (state.isNotEmpty) {
        // Chỉ xóa state nếu server thực sự rỗng (và không đang modify)
        emit([]);
        await _saveToHive(userId, []);
      }
    } catch (e) {
      if (kDebugMode) print('[HistoryCubit] sync supabase error: $e');
    }
  }

  Future<void> _saveToHive(String userId, List<MediaItem> items) async {
    try {
      final json = items.map(_mediaItemToMap).toList();
      await _box.put(_hiveKey(userId), jsonEncode(json));
    } catch (e) {
      if (kDebugMode) print('[HistoryCubit] save hive error: $e');
    }
  }

  Future<void> _saveToSupabase(MediaItem item) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      await _supabase.from('listening_history').upsert({
        'user_id': userId,
        'song_id': item.id,
        'song_title': item.title,
        'song_artist': item.artist ?? '',
        'song_art_uri': item.artUri?.toString() ?? '',
        'song_duration_ms': item.duration?.inMilliseconds ?? 0,
        'song_extras': jsonEncode(item.extras ?? {}),
        'played_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,song_id');
    } catch (e) {
      if (kDebugMode) print('[HistoryCubit] save supabase error: $e');
    }
  }

  void clearLocalData() {
    _isModifying = false;
    _lastAddedSongId = null;
    _lastAddedAt = null;
    emit([]);
    if (kDebugMode) print('[HistoryCubit] local data cleared (logout)');
  }

  Future<void> reloadForUser() async {
    _isModifying = false;
    final userId = _userId;
    if (userId == null) {
       emit([]);
       return;
    }
    emit([]);
    _loadFromHive(userId);
    await _syncFromSupabase();
  }

  Future<void> addSong(MediaItem item) async {
    final userId = _userId;
    if (userId == null) return;

    final now = DateTime.now();
    if (_lastAddedSongId == item.id &&
        _lastAddedAt != null &&
        now.difference(_lastAddedAt!).inSeconds < 30) {
      return;
    }
    _lastAddedSongId = item.id;
    _lastAddedAt = now;

    _isModifying = true;
    final current = List<MediaItem>.from(state);
    current.removeWhere((s) => s.id == item.id);
    current.insert(0, item);
    if (current.length > _maxHistory) current.removeLast();

    emit(current);
    try {
      await _saveToHive(userId, current);
      await _saveToSupabase(item);
    } finally {
      _isModifying = false;
    }
  }

  Future<void> clearHistory() async {
    try {
      final userId = _userId;
      if (userId == null) return;

      _isModifying = true;
      emit([]);
      await _saveToHive(userId, []);

      await _supabase
          .from('listening_history')
          .delete()
          .eq('user_id', userId);
    } finally {
      _isModifying = false;
    }
  }

  Future<void> removeItem(String songId) async {
    try {
      final userId = _userId;
      if (kDebugMode) print('[HistoryCubit] Attempting to remove songId: $songId for userId: $userId');

      _isModifying = true;
      
      // 1. Cập nhật UI ngay lập tức
      final updated = state.where((s) => s.id != songId).toList();
      emit(updated);

      // 2. Lưu local (Hive)
      if (userId != null) {
        await _saveToHive(userId, updated);

        // 3. Xóa trên Supabase
        final response = await _supabase
            .from('listening_history')
            .delete()
            .eq('user_id', userId)
            .eq('song_id', songId)
            .select();

        if (kDebugMode) {
          if (response != null && (response as List).isNotEmpty) {
            print('[HistoryCubit] successfully removed from Supabase');
          } else {
            print('[HistoryCubit] no rows deleted in Supabase (check RLS or IDs)');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[HistoryCubit] removeItem global error: $e');
    } finally {
      // Đợi một chút rồi mới cho phép sync lại để tránh race condition với server
      Future.delayed(const Duration(milliseconds: 500), () => _isModifying = false);
    }
  }

  Map<String, dynamic> _parseExtras(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  String? _nonEmpty(String? value) =>
      (value != null && value.isNotEmpty) ? value : null;

  Uri? _parseUri(String? value) =>
      (value != null && value.isNotEmpty) ? Uri.tryParse(value) : null;

  MediaItem _mapToMediaItem(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      artist: _nonEmpty(map['artist'] as String?),
      artUri: _parseUri(map['artUri'] as String?),
      duration:
          Duration(milliseconds: (map['duration'] as num? ?? 0).toInt()),
      extras: Map<String, dynamic>.from(map['extras'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> _mediaItemToMap(MediaItem item) => {
        'id': item.id,
        'title': item.title,
        'artist': item.artist ?? '',
        'artUri': item.artUri?.toString() ?? '',
        'duration': item.duration?.inMilliseconds ?? 0,
        'extras': item.extras ?? {},
      };
}
