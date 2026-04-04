import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist =
      ConcatenatingAudioSource(children: []);

  // ✅ Chỉ dùng 1 stream duy nhất — không merge, không race condition
  late final Stream<Duration> positionStream;

  MyAudioHandler() {
    _init();
  }

  void _init() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    _player.setAudioSource(_playlist);

    // ✅ Dùng thẳng just_audio positionStream — chuẩn nhất
    // Tự update sau seek, không cần inject thêm gì
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
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playlist.length == 0) return;
    await _player.seek(position);
    // ✅ Bỏ _positionController.add(position) — just_audio tự emit sau seek
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
        _playlist.length == 0) return;
    try {
      await _player.seek(Duration.zero, index: index);
    } catch (e) {
      print('Lỗi Seek Audio Web: $e');
    }
  }

  // ─── Queue management ─────────────────────────────────────

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    final audioSources = newQueue.map(_mediaItemToAudioSource).toList();
    if (_player.playing) await _player.pause();
    await _playlist.clear();
    await _playlist.addAll(audioSources);
    queue.add(newQueue);
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
    final url = item.extras?['url'];
    if (url == null || url.toString().isEmpty) {
      print('❌ URL null: ${item.id}');
      return AudioSource.uri(
        Uri.parse(
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
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
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}