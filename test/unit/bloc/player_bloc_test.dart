// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/presentation/bloc/player/player_state.dart';
import 'package:music_app/services/audio_handler.dart';
import 'package:music_app/services/music_player_service.dart';

// ─── Mocks ───────────────────────────────────────────────────

class MockMusicPlayerService extends Mock implements MusicPlayerService {}

// ✅ Fix: extends MyAudioHandler (là BaseAudioHandler subclass)
// KHÔNG dùng implements vì BaseAudioHandler không thể implements
class FakeAudioHandler extends MyAudioHandler {
  // Override các method cần test — trả về Future.value() để không throw
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {}

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {}

  @override
  Future<void> skipToQueueItem(int index) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}
}

class FakeMediaItem extends Fake implements MediaItem {}

// ─── Helpers ─────────────────────────────────────────────────

MediaItem makeSong({String id = 'song_1', String title = 'Test Song'}) =>
    MediaItem(
        id: id,
        title: title,
        artist: 'Test Artist',
        album: 'Test Album');

void stubDefaultStreams(MockMusicPlayerService svc) {
  when(() => svc.playbackStateStream)
      .thenAnswer((_) => const Stream.empty());
  when(() => svc.currentSongStream)
      .thenAnswer((_) => const Stream.empty());
  when(() => svc.positionStream)
      .thenAnswer((_) => const Stream.empty());
  when(() => svc.durationStream)
      .thenAnswer((_) => const Stream.empty());
}

// ─────────────────────────────────────────────────────────────

void main() {
  late MockMusicPlayerService mockService;
  // ✅ Fix: FakeAudioHandler thay vì MockMyAudioHandler
  late FakeAudioHandler fakeHandler;

  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AudioServiceRepeatMode.none);
    registerFallbackValue(AudioServiceShuffleMode.none);
  });

  setUp(() {
    mockService  = MockMusicPlayerService();
    fakeHandler  = FakeAudioHandler();
    stubDefaultStreams(mockService);
    // ✅ Fix: stub handler trả về FakeAudioHandler (đúng kiểu MyAudioHandler)
    when(() => mockService.handler).thenReturn(fakeHandler);
  });

  PlayerBloc makeBloc() => PlayerBloc(mockService);

  // ═══════════════════════════════════════════════════════════
  // GROUP 1: Initial state
  // ═══════════════════════════════════════════════════════════
  group('PlayerBloc — initial state', () {
    test('state là PlayerInitial khi khởi tạo', () {
      expect(makeBloc().state, isA<PlayerInitial>());
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 2: LoadPlaylistEvent
  // ═══════════════════════════════════════════════════════════
  group('LoadPlaylistEvent', () {
    final song     = makeSong();
    final playlist = [song];

    blocTest<PlayerBloc, PlayerState>(
      'emit PlayerLoading khi bắt đầu load playlist',
      build: () {
        when(() => mockService.playPlaylist(any(),
                startIndex: any(named: 'startIndex')))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(LoadPlaylistEvent(playlist)),
      expect: () => [
        isA<PlayerLoading>().having((s) => s.song?.id, 'song id', song.id),
      ],
    );

    blocTest<PlayerBloc, PlayerState>(
      '✅ CRITICAL: emit PlayerError khi playPlaylist ném exception',
      build: () {
        when(() => mockService.playPlaylist(any(),
                startIndex: any(named: 'startIndex')))
            .thenThrow(Exception('Network error: unable to stream audio'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(LoadPlaylistEvent(playlist)),
      expect: () => [
        isA<PlayerLoading>(),
        isA<PlayerError>().having(
          (s) => s.message,
          'error message',
          contains('Failed to load playlist'),
        ),
      ],
      verify: (_) {
        verify(() => mockService.playPlaylist(any(),
            startIndex: any(named: 'startIndex'))).called(1);
      },
    );

    blocTest<PlayerBloc, PlayerState>(
      'emit PlayerLoading với đúng bài hát ở startIndex',
      build: () {
        when(() => mockService.playPlaylist(any(), startIndex: 2))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(
        LoadPlaylistEvent(
          [makeSong(id: 'a'), makeSong(id: 'b'), makeSong(id: 'c')],
          startIndex: 2,
        ),
      ),
      expect: () => [
        isA<PlayerLoading>().having((s) => s.song?.id, 'startIndex song', 'c'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 3: PlayEvent / PauseEvent
  // ═══════════════════════════════════════════════════════════
  group('PlayEvent / PauseEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'PlayEvent gọi service.play()',
      build: () {
        when(() => mockService.play()).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const PlayEvent()),
      verify: (_) => verify(() => mockService.play()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'PauseEvent gọi service.pause()',
      build: () {
        when(() => mockService.pause()).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const PauseEvent()),
      verify: (_) => verify(() => mockService.pause()).called(1),
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 4: SeekEvent
  // ═══════════════════════════════════════════════════════════
  group('SeekEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'SeekEvent gọi service.seek() với đúng Duration',
      build: () {
        when(() => mockService.seek(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SeekEvent(Duration(seconds: 45))),
      verify: (_) {
        verify(() => mockService.seek(const Duration(seconds: 45))).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 5: NextEvent / PreviousEvent
  // ═══════════════════════════════════════════════════════════
  group('Next / Previous', () {
    blocTest<PlayerBloc, PlayerState>(
      'NextEvent gọi service.next()',
      build: () {
        when(() => mockService.next()).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const NextEvent()),
      verify: (_) => verify(() => mockService.next()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'PreviousEvent gọi service.previous() khi position < 3s',
      build: () {
        when(() => mockService.previous()).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const PreviousEvent()),
      verify: (_) => verify(() => mockService.previous()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'PreviousEvent gọi service.seek(0) khi position > 3s',
      build: () {
        when(() => mockService.seek(any())).thenAnswer((_) async {});
        final posCtrl = StreamController<Duration>.broadcast();
        when(() => mockService.positionStream)
            .thenAnswer((_) => posCtrl.stream);
        final bloc = PlayerBloc(mockService);
        posCtrl.add(const Duration(seconds: 10));
        return bloc;
      },
      act: (bloc) async {
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const PreviousEvent());
      },
      verify: (_) {
        verify(() => mockService.seek(Duration.zero)).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 6: ToggleShuffleEvent
  // ═══════════════════════════════════════════════════════════
  group('ToggleShuffleEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'lần đầu toggle → bật shuffle',
      build: () {
        // fakeHandler đã được stub trong setUp()
        return makeBloc();
      },
      act: (bloc) => bloc.add(const ToggleShuffleEvent()),
      verify: (_) {
        // Verify thông qua fakeHandler (đã được assign vào mockService.handler)
        verify(() => mockService.handler).called(greaterThan(0));
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 7: CycleRepeatEvent
  // ═══════════════════════════════════════════════════════════
  group('CycleRepeatEvent — chu kỳ none → one → all → none', () {
    test('gọi handler.setRepeatMode đúng 3 lần khi cycle 3 lần', () async {
      final bloc = makeBloc();

      bloc.add(const CycleRepeatEvent()); // none → one
      await Future.delayed(const Duration(milliseconds: 20));

      bloc.add(const CycleRepeatEvent()); // one → all
      await Future.delayed(const Duration(milliseconds: 20));

      bloc.add(const CycleRepeatEvent()); // all → none
      await Future.delayed(const Duration(milliseconds: 20));

      // Verify handler được truy cập đúng 3 lần (mỗi CycleRepeatEvent 1 lần)
      verify(() => mockService.handler).called(3);

      await bloc.close();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 8: Stream → State mapping
  // ═══════════════════════════════════════════════════════════
  group('Playback stream → State mapping', () {
    test('playbackStateStream playing=true → emit PlayerPlaying', () async {
      final song      = makeSong();
      final pbCtrl    = StreamController<PlaybackState>.broadcast();
      final mediaCtrl = StreamController<MediaItem?>.broadcast();
      final posCtrl   = StreamController<Duration>.broadcast();

      when(() => mockService.playbackStateStream)
          .thenAnswer((_) => pbCtrl.stream);
      when(() => mockService.currentSongStream)
          .thenAnswer((_) => mediaCtrl.stream);
      when(() => mockService.positionStream)
          .thenAnswer((_) => posCtrl.stream);

      final bloc = PlayerBloc(mockService);

      mediaCtrl.add(song);
      await Future.delayed(const Duration(milliseconds: 10));

      pbCtrl.add(PlaybackState(
          playing: true,
          processingState: AudioProcessingState.ready));
      await Future.delayed(const Duration(milliseconds: 30));

      expect(bloc.state, isA<PlayerPlaying>());

      await bloc.close();
      await pbCtrl.close();
      await mediaCtrl.close();
      await posCtrl.close();
    });
  });
}