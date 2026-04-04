import 'package:audio_service/audio_service.dart';

abstract class PlayerEvent {
  const PlayerEvent();
}

class LoadPlaylistEvent extends PlayerEvent {
  final List<MediaItem> playlist;
  final int startIndex;
  final String? userId;

  // Giữ positional arg thứ nhất để không break các chỗ gọi cũ:
  // LoadPlaylistEvent(songs, startIndex: 0)
  const LoadPlaylistEvent(this.playlist, {required this.startIndex, this.userId});
}

class PlayEvent extends PlayerEvent {
  const PlayEvent();
}

class PauseEvent extends PlayerEvent {
  const PauseEvent();
}

class NextEvent extends PlayerEvent {
  const NextEvent();
}

class PreviousEvent extends PlayerEvent {
  const PreviousEvent();
}

class SeekEvent extends PlayerEvent {
  final Duration position;
  const SeekEvent(this.position);
}

class SkipToIndexEvent extends PlayerEvent {
  final int index;
  const SkipToIndexEvent(this.index);
}

// "Phát tiếp theo" — chen vào ngay sau bài đang phát
class PlayNextEvent extends PlayerEvent {
  final MediaItem item;
  final String? userId;
  const PlayNextEvent(this.item, {this.userId});
}

class InternalUpdateEvent extends PlayerEvent {
  const InternalUpdateEvent();
}

// Queue events
class RemoveFromQueueEvent extends PlayerEvent {
  final int index;
  final String? userId;
  const RemoveFromQueueEvent(this.index, {this.userId});
}

class PrioritizeSongEvent extends PlayerEvent {
  final int index;
  final String? userId;
  const PrioritizeSongEvent(this.index, {this.userId});
}

// Shuffle / Repeat — dùng trong player_page.dart
class ToggleShuffleEvent extends PlayerEvent {
  const ToggleShuffleEvent();
}

class CycleRepeatEvent extends PlayerEvent {
  const CycleRepeatEvent();
}

// Reset toàn bộ khi đăng xuất
class ResetPlayerEvent extends PlayerEvent {
  const ResetPlayerEvent();
}

// Khôi phục queue khi đăng nhập lại
class RestoreQueueEvent extends PlayerEvent {
  final String userId;
  const RestoreQueueEvent(this.userId);
}