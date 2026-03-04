import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/music_player_service.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final MusicPlayerService _service;

  StreamSubscription? _playbackSub;
  StreamSubscription? _mediaSub;
  StreamSubscription? _positionSub;

  // Internal cache
  MediaItem? _currentSong;
  Duration   _position = Duration.zero;
  Duration   _duration = Duration.zero;
  bool       _isShuffle = false;
  RepeatMode _repeat = RepeatMode.none;
  List<MediaItem> _queue = [];
  int _currentIndex = 0;

  PlayerBloc(this._service) : super(const PlayerInitial()) {
    on<LoadPlaylistEvent>(_onLoadPlaylist);
    on<PlayEvent>        (_onPlay);
    on<PauseEvent>       (_onPause);
    on<SeekEvent>        (_onSeek);
    on<NextEvent>        (_onNext);
    on<PreviousEvent>    (_onPrevious);
    on<ToggleShuffleEvent>(_onToggleShuffle);
    on<CycleRepeatEvent> (_onCycleRepeat);
    on<SkipToIndexEvent> (_onSkipToIndex);

    _subscribeToStreams();
  }

  // ─── Stream Subscriptions ────────────────────────────────

  void _subscribeToStreams() {
    // Position updates (throttle to 300ms to avoid excess rebuilds)
    _positionSub = _service.positionStream
        .distinct()
        .listen((pos) {
      _position = pos;
      _emitCurrentState();
    });

    // Duration updates
    _service.durationStream.listen((dur) {
      if (dur != null) _duration = dur;
    });

    // Playback state (playing / paused / buffering)
    _playbackSub = _service.playbackStateStream.listen((ps) {
      if (ps.processingState == AudioProcessingState.loading ||
          ps.processingState == AudioProcessingState.buffering) {
        emit(PlayerLoading(song: _currentSong));
      } else if (ps.playing) {
        _emitPlaying();
      } else if (ps.processingState == AudioProcessingState.ready) {
        _emitPaused();
      }
    });

    // Current song changes
    _mediaSub = _service.currentSongStream.listen((item) {
      _currentSong = item;
    });
  }

  // ─── Event Handlers ──────────────────────────────────────

  Future<void> _onLoadPlaylist(
      LoadPlaylistEvent event, Emitter<PlayerState> emit) async {
    try {
      emit(PlayerLoading(song: event.playlist[event.startIndex]));
      _queue = event.playlist;
      _currentIndex = event.startIndex;
      await _service.playPlaylist(event.playlist, startIndex: event.startIndex);
    } catch (e) {
      emit(PlayerError('Failed to load playlist: $e'));
    }
  }

  Future<void> _onPlay(PlayEvent event, Emitter<PlayerState> emit) async {
    await _service.play();
  }

  Future<void> _onPause(PauseEvent event, Emitter<PlayerState> emit) async {
    await _service.pause();
  }

  Future<void> _onSeek(SeekEvent event, Emitter<PlayerState> emit) async {
    await _service.seek(event.position);
  }

  Future<void> _onNext(NextEvent event, Emitter<PlayerState> emit) async {
    await _service.next();
  }

  Future<void> _onPrevious(PreviousEvent event, Emitter<PlayerState> emit) async {
    // If past 3 seconds, restart; else go to previous
    if (_position.inSeconds > 3) {
      await _service.seek(Duration.zero);
    } else {
      await _service.previous();
    }
  }

  Future<void> _onToggleShuffle(
      ToggleShuffleEvent event, Emitter<PlayerState> emit) async {
    _isShuffle = !_isShuffle;
    await _service.handler.setShuffleMode(
      _isShuffle
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
    _emitCurrentState();
  }

  Future<void> _onCycleRepeat(
      CycleRepeatEvent event, Emitter<PlayerState> emit) async {
    _repeat = RepeatMode.values[(_repeat.index + 1) % RepeatMode.values.length];
    final mode = switch (_repeat) {
      RepeatMode.none => AudioServiceRepeatMode.none,
      RepeatMode.one  => AudioServiceRepeatMode.one,
      RepeatMode.all  => AudioServiceRepeatMode.all,
    };
    await _service.handler.setRepeatMode(mode);
    _emitCurrentState();
  }

  Future<void> _onSkipToIndex(
      SkipToIndexEvent event, Emitter<PlayerState> emit) async {
    _currentIndex = event.index;
    await _service.handler.skipToQueueItem(event.index);
  }

  // ─── Emit Helpers ────────────────────────────────────────

  void _emitCurrentState() {
    final st = state;
    if (st is PlayerPlaying || st is PlayerLoading) {
      _emitPlaying();
    } else {
      _emitPaused();
    }
  }

  void _emitPlaying() {
    if (_currentSong == null) return;
    emit(PlayerPlaying(
      song: _currentSong!,
      position: _position,
      duration: _duration,
      isShuffle: _isShuffle,
      repeatMode: _repeat,
      queue: _queue,
      currentIndex: _currentIndex,
    ));
  }

  void _emitPaused() {
    if (_currentSong == null) return;
    emit(PlayerPaused(
      song: _currentSong!,
      position: _position,
      duration: _duration,
      isShuffle: _isShuffle,
      repeatMode: _repeat,
      queue: _queue,
      currentIndex: _currentIndex,
    ));
  }

  @override
  Future<void> close() {
    _playbackSub?.cancel();
    _mediaSub?.cancel();
    _positionSub?.cancel();
    return super.close();
  }
}