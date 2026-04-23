// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/presentation/bloc/player/player_state.dart';
import 'package:music_app/presentation/bloc/history/history_cubit.dart';
import 'package:music_app/services/audio_handler.dart';

// ─── Mocks ───────────────────────────────────────────────────

class MockHistoryCubit extends Mock implements HistoryCubit {}

class FakeMediaItem extends Fake implements MediaItem {}

// Extends MyAudioHandler so it is a valid AudioHandler subtype.
// Cannot use `implements` because BaseAudioHandler cannot be implemented.
class FakeAudioHandler extends MyAudioHandler {
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

// ─── Helpers ─────────────────────────────────────────────────

MediaItem makeSong({String id = 'song_1', String title = 'Test Song'}) =>
    MediaItem(
        id: id,
        title: title,
        artist: 'Test Artist',
        album: 'Test Album');

// ─────────────────────────────────────────────────────────────

void main() {
  late FakeAudioHandler fakeHandler;
  late MockHistoryCubit mockHistoryCubit;

  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AudioServiceRepeatMode.none);
    registerFallbackValue(AudioServiceShuffleMode.none);
  });

  setUp(() {
    fakeHandler = FakeAudioHandler();
    mockHistoryCubit = MockHistoryCubit();

    // Make playbackState emit a sensible default so InternalUpdateEvent
    // doesn't immediately emit PlayerInitial.
    fakeHandler.playbackState.add(PlaybackState(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    fakeHandler.mediaItem.add(null);
  });

  tearDown(() async {
    await fakeHandler.stop();
  });

  PlayerBloc makeBloc() => PlayerBloc(fakeHandler, mockHistoryCubit);

  // ═══════════════════════════════════════════════════════════
  // GROUP 1: Initial state
  // ═══════════════════════════════════════════════════════════
  group('PlayerBloc — initial state', () {
    test('state is PlayerInitial when no queue is loaded', () {
      expect(makeBloc().state, isA<PlayerInitial>());
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 2: LoadPlaylistEvent
  // ═══════════════════════════════════════════════════════════
  group('LoadPlaylistEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'updateQueue is called with the playlist',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(LoadPlaylistEvent(
        [makeSong()],
        startIndex: 0,
      )),
      expect: () => [],
      verify: (_) {
        verify(() => fakeHandler.updateQueue(any())).called(1);
      },
    );

    blocTest<PlayerBloc, PlayerState>(
      'skipToQueueItem is called with startIndex',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(LoadPlaylistEvent(
        [makeSong(id: 'a'), makeSong(id: 'b'), makeSong(id: 'c')],
        startIndex: 2,
      )),
      expect: () => [],
      verify: (_) {
        verify(() => fakeHandler.skipToQueueItem(2)).called(1);
      },
    );

    blocTest<PlayerBloc, PlayerState>(
      'play is called after loading the playlist',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(LoadPlaylistEvent([makeSong()], startIndex: 0)),
      expect: () => [],
      verify: (_) {
        verify(() => fakeHandler.play()).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 3: PlayEvent / PauseEvent
  // ═══════════════════════════════════════════════════════════
  group('PlayEvent / PauseEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'PlayEvent calls handler.play()',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const PlayEvent()),
      verify: (_) => verify(() => fakeHandler.play()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'PauseEvent calls handler.pause()',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const PauseEvent()),
      verify: (_) => verify(() => fakeHandler.pause()).called(1),
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 4: SeekEvent
  // ═══════════════════════════════════════════════════════════
  group('SeekEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'SeekEvent calls handler.seek() with the given position',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const SeekEvent(Duration(seconds: 45))),
      verify: (_) {
        verify(() => fakeHandler.seek(const Duration(seconds: 45))).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 5: NextEvent / PreviousEvent
  // ═══════════════════════════════════════════════════════════
  group('NextEvent / PreviousEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'NextEvent calls handler.skipToNext()',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const NextEvent()),
      verify: (_) => verify(() => fakeHandler.skipToNext()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'PreviousEvent calls handler.skipToPrevious()',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const PreviousEvent()),
      verify: (_) => verify(() => fakeHandler.skipToPrevious()).called(1),
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 6: ToggleShuffleEvent
  // ═══════════════════════════════════════════════════════════
  group('ToggleShuffleEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'ToggleShuffleEvent calls handler.setShuffleMode()',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const ToggleShuffleEvent()),
      verify: (_) {
        verify(() => fakeHandler.setShuffleMode(any())).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 7: CycleRepeatEvent
  // ═══════════════════════════════════════════════════════════
  group('CycleRepeatEvent — cycles none → one → all → none', () {
    test('handler.setRepeatMode is called once per cycle', () async {
      final bloc = makeBloc();

      bloc.add(const CycleRepeatEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      bloc.add(const CycleRepeatEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      bloc.add(const CycleRepeatEvent());
      await Future.delayed(const Duration(milliseconds: 20));

      verify(() => fakeHandler.setRepeatMode(any())).called(3);

      await bloc.close();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 8: RemoveFromQueueEvent
  // ═══════════════════════════════════════════════════════════
  group('RemoveFromQueueEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'removeQueueItemAt is called with the correct index',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const RemoveFromQueueEvent(1)),
      verify: (_) {
        verify(() => fakeHandler.removeQueueItemAt(1)).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 9: ResetPlayerEvent
  // ═══════════════════════════════════════════════════════════
  group('ResetPlayerEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'handler.stop() and updateQueue([]) are called',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const ResetPlayerEvent()),
      expect: () => [isA<PlayerInitial>()],
      verify: (_) {
        verify(() => fakeHandler.stop()).called(1);
        verify(() => fakeHandler.updateQueue(any())).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 10: SkipToIndexEvent
  // ═══════════════════════════════════════════════════════════
  group('SkipToIndexEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'handler.skipToQueueItem is called with the correct index',
      build: () => makeBloc(),
      act: (bloc) => bloc.add(const SkipToIndexEvent(3)),
      verify: (_) {
        verify(() => fakeHandler.skipToQueueItem(3)).called(1);
      },
    );
  });
}
