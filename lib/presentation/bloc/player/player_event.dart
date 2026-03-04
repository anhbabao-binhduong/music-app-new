import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();
  @override List<Object?> get props => [];
}

/// Load a playlist and optionally start at [startIndex]
class LoadPlaylistEvent extends PlayerEvent {
  final List<MediaItem> playlist;
  final int startIndex;
  const LoadPlaylistEvent(this.playlist, {this.startIndex = 0});
  @override List<Object?> get props => [playlist, startIndex];
}

/// Play or resume
class PlayEvent extends PlayerEvent {
  const PlayEvent();
}

/// Pause playback
class PauseEvent extends PlayerEvent {
  const PauseEvent();
}

/// Seek to an absolute position
class SeekEvent extends PlayerEvent {
  final Duration position;
  const SeekEvent(this.position);
  @override List<Object?> get props => [position];
}

/// Skip to next track
class NextEvent extends PlayerEvent {
  const NextEvent();
}

/// Skip to previous track
class PreviousEvent extends PlayerEvent {
  const PreviousEvent();
}

/// Toggle shuffle mode
class ToggleShuffleEvent extends PlayerEvent {
  const ToggleShuffleEvent();
}

/// Cycle repeat: none → one → all
class CycleRepeatEvent extends PlayerEvent {
  const CycleRepeatEvent();
}

/// Jump to a specific index in the current queue
class SkipToIndexEvent extends PlayerEvent {
  final int index;
  const SkipToIndexEvent(this.index);
  @override List<Object?> get props => [index];
}