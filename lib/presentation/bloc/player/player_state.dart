import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

enum RepeatMode { none, one, all }

abstract class PlayerState extends Equatable {
  const PlayerState();
  @override List<Object?> get props => [];
}

/// App just launched, no song loaded
class PlayerInitial extends PlayerState {
  const PlayerInitial();
}

/// Buffering / loading audio source
class PlayerLoading extends PlayerState {
  final MediaItem? song;
  const PlayerLoading({this.song});
  @override List<Object?> get props => [song];
}

/// Actively playing
class PlayerPlaying extends PlayerState {
  final MediaItem song;
  final Duration position;
  final Duration duration;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final List<MediaItem> queue;
  final int currentIndex;

  const PlayerPlaying({
    required this.song,
    required this.position,
    required this.duration,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.none,
    required this.queue,
    required this.currentIndex,
  });

  PlayerPlaying copyWith({
    MediaItem? song,
    Duration? position,
    Duration? duration,
    bool? isShuffle,
    RepeatMode? repeatMode,
    List<MediaItem>? queue,
    int? currentIndex,
  }) => PlayerPlaying(
    song:         song         ?? this.song,
    position:     position     ?? this.position,
    duration:     duration     ?? this.duration,
    isShuffle:    isShuffle    ?? this.isShuffle,
    repeatMode:   repeatMode   ?? this.repeatMode,
    queue:        queue        ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
  );

  @override
  List<Object?> get props =>
    [song, position, duration, isShuffle, repeatMode, currentIndex];
}

/// Paused — carries the same payload so UI doesn't blank
class PlayerPaused extends PlayerState {
  final MediaItem song;
  final Duration position;
  final Duration duration;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final List<MediaItem> queue;
  final int currentIndex;

  const PlayerPaused({
    required this.song,
    required this.position,
    required this.duration,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.none,
    required this.queue,
    required this.currentIndex,
  });

  @override
  List<Object?> get props =>
    [song, position, duration, isShuffle, repeatMode, currentIndex];
}

/// Fatal error
class PlayerError extends PlayerState {
  final String message;
  const PlayerError(this.message);
  @override List<Object?> get props => [message];
}