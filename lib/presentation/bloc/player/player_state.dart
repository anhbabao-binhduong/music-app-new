import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

enum RepeatMode { none, one, all }

abstract class PlayerState extends Equatable {
  final MediaItem? song;
  final Duration position;
  final Duration duration;
  final List<MediaItem> queue;
  final int currentIndex;

  const PlayerState({
    this.song,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = 0,
  });

  PlayerState copyWith({
    MediaItem? song,
    Duration? position,
    Duration? duration,
    List<MediaItem>? queue,
    int? currentIndex,
  });

  @override
  List<Object?> get props => [song, position, duration, queue, currentIndex];
}

class PlayerInitial extends PlayerState {
  const PlayerInitial() : super();
  @override
  PlayerState copyWith({MediaItem? song, Duration? position, Duration? duration, List<MediaItem>? queue, int? currentIndex}) => this;
}

class PlayerLoading extends PlayerState {
  const PlayerLoading({super.song}) : super();
  @override
  PlayerState copyWith({MediaItem? song, Duration? position, Duration? duration, List<MediaItem>? queue, int? currentIndex}) => this;
}

class PlayerPlaying extends PlayerState {
  final bool isShuffle;
  final RepeatMode repeatMode;

  const PlayerPlaying({
    required MediaItem super.song,
    required super.position,
    required super.duration,
    required super.queue,
    required super.currentIndex,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.none,
  });

  @override
  PlayerPlaying copyWith({
    MediaItem? song,
    Duration? position,
    Duration? duration,
    List<MediaItem>? queue,
    int? currentIndex,
    bool? isShuffle,
    RepeatMode? repeatMode,
  }) => PlayerPlaying(
    song: song ?? this.song!,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    isShuffle: isShuffle ?? this.isShuffle,
    repeatMode: repeatMode ?? this.repeatMode,
  );

  @override
  List<Object?> get props => [super.song, super.position, super.duration, super.queue, super.currentIndex, isShuffle, repeatMode];
}

class PlayerPaused extends PlayerState {
  final bool isShuffle; // Thêm vào để đồng bộ với PlayerPage
  final RepeatMode repeatMode;

  const PlayerPaused({
    required MediaItem super.song,
    required super.position,
    required super.duration,
    required super.queue,
    required super.currentIndex,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.none,
  });

  @override
  PlayerPaused copyWith({
    MediaItem? song,
    Duration? position,
    Duration? duration,
    List<MediaItem>? queue,
    int? currentIndex,
    bool? isShuffle,
    RepeatMode? repeatMode,
  }) => PlayerPaused(
    song: song ?? this.song!,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    isShuffle: isShuffle ?? this.isShuffle,
    repeatMode: repeatMode ?? this.repeatMode,
  );
}

class PlayerError extends PlayerState {
  final String message;
  const PlayerError(this.message) : super();
  @override
  PlayerState copyWith({MediaItem? song, Duration? position, Duration? duration, List<MediaItem>? queue, int? currentIndex}) => this;
  @override
  List<Object?> get props => [message];
}