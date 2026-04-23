import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// ignore: deprecated_member_use
class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  // ignore: deprecated_member_use
  late final ConcatenatingAudioSource _playlist =
      // ignore: deprecated_member_use
      ConcatenatingAudioSource(children: []);

  late final Stream<Duration> positionStream;

  MyAudioHandler() {
    _init();
  }

  void _init() {
    _player.playbackEventStream.listen((event) {
      final state = _transformEvent(event);
      playbackState.add(state);
    });

    _player.shuffleModeEnabledStream.listen((enabled) {
      playbackState.add(playbackState.value.copyWith(
        shuffleMode: enabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ));
    });

    _player.loopModeStream.listen((loopMode) {
      playbackState.add(playbackState.value.copyWith(
        repeatMode: loopMode == LoopMode.one
            ? AudioServiceRepeatMode.one
            : loopMode == LoopMode.all
                ? AudioServiceRepeatMode.all
                : AudioServiceRepeatMode.none,
      ));
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    _player.setAudioSource(_playlist);

    positionStream = _player.positionStream.asBroadcastStream();
  }

  // ─── Playback controls ────────────────────────────────────

  @override
  Future<void> play() async {
    if (_playlist.length == 0) return;
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playlist.length == 0) return;
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.length == 0) return;
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.length == 0) return;
    await _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 ||
        index >= queue.value.length ||
        _playlist.length == 0) {
      return;
    }
    try {
      await _player.seek(Duration.zero, index: index);
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi Seek Audio Web: $e');
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  // ─── Queue management ─────────────────────────────────────

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> updateQueue(List<MediaItem> queue) async {
    final audioSources = queue.map(_mediaItemToAudioSource).toList();
    if (_player.playing) await _player.pause();
    await _playlist.clear();
    await _playlist.addAll(audioSources);
    this.queue.add(queue);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSources = mediaItems.map(_mediaItemToAudioSource).toList();
    await _playlist.addAll(audioSources);
    queue.add([...queue.value, ...mediaItems]);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await _playlist.add(_mediaItemToAudioSource(mediaItem));
    queue.add(List<MediaItem>.from(queue.value)..add(mediaItem));
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    await _playlist.insert(index, _mediaItemToAudioSource(mediaItem));
    queue.add(List<MediaItem>.from(queue.value)..insert(index, mediaItem));
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
    queue.add(List<MediaItem>.from(queue.value)..removeAt(index));
  }

  // ─── Streams ──────────────────────────────────────────────

  Stream<Duration?> get durationStream => _player.durationStream;

  // ─── Helpers ──────────────────────────────────────────────

  AudioSource _mediaItemToAudioSource(MediaItem item) {
    // ✅ Đọc extras['url'] — đúng format từ cả localPlaylist lẫn category songs
    final url = item.extras?['url']?.toString() ?? '';

    if (url.isEmpty || !url.startsWith('http')) {
      // ignore: avoid_print
      print('❌ URL null: ${item.id}');
      return AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
        tag: item,
      );
    }

    return AudioSource.uri(Uri.parse(url), tag: item);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: switch (_player.processingState) {
        ProcessingState.idle      => AudioProcessingState.idle,
        ProcessingState.loading   => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready     => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      shuffleMode: _player.shuffleModeEnabled 
          ? AudioServiceShuffleMode.all 
          : AudioServiceShuffleMode.none,
      repeatMode: _player.loopMode == LoopMode.one
          ? AudioServiceRepeatMode.one
          : _player.loopMode == LoopMode.all
              ? AudioServiceRepeatMode.all
              : AudioServiceRepeatMode.none,
    );
  }
}