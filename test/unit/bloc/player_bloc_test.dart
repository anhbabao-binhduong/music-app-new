import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_app/presentation/bloc/player/player_bloc.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';
import 'package:music_app/presentation/bloc/player/player_state.dart';
import 'package:music_app/services/music_player_service.dart';

// ─── Mocks ───────────────────────────────────────────────────

class MockMusicPlayerService extends Mock implements MusicPlayerService {}
class MockMyAudioHandler      extends Mock implements MyAudioHandler {}

// Fake MediaItem để dùng trong registerFallbackValue
class FakeMediaItem extends Fake implements MediaItem {}

// ─── Helpers ─────────────────────────────────────────────────

/// Tạo MediaItem mẫu nhanh
MediaItem _makeSong({String id = 'song_1', String title = 'Test Song'}) =>
    MediaItem(id: id, title: title, artist: 'Test Artist', album: 'Test Album');

/// Stub tất cả streams cần thiết để PlayerBloc không throw
void _stubDefaultStreams(MockMusicPlayerService svc) {
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

  setUpAll(() {
    // Đăng ký fallback values cho mocktail
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AudioServiceRepeatMode.none);
    registerFallbackValue(AudioServiceShuffleMode.none);
  });

  setUp(() {
    mockService = MockMusicPlayerService();
    _stubDefaultStreams(mockService);
  });

  // ── Helper: tạo Bloc mới với mock đã stub ─────────────────
  PlayerBloc _makeBloc() => PlayerBloc(mockService);

  // ═══════════════════════════════════════════════════════════
  // GROUP 1: Initial state
  // ═══════════════════════════════════════════════════════════
  group('PlayerBloc — initial state', () {
    test('state là PlayerInitial khi khởi tạo', () {
      expect(_makeBloc().state, isA<PlayerInitial>());
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 2: LoadPlaylistEvent
  // ═══════════════════════════════════════════════════════════
  group('LoadPlaylistEvent', () {
    final song     = _makeSong();
    final playlist = [song];

    blocTest<PlayerBloc, PlayerState>(
      'emit PlayerLoading khi bắt đầu load playlist',
      build: () {
        when(() => mockService.playPlaylist(any(), startIndex: any(named: 'startIndex')))
            .thenAnswer((_) async {});
        return _makeBloc();
      },
      act: (bloc) => bloc.add(LoadPlaylistEvent(playlist)),
      expect: () => [
        isA<PlayerLoading>().having((s) => s.song?.id, 'song id', song.id),
      ],
    );

    blocTest<PlayerBloc, PlayerState>(
      '✅ CRITICAL: emit PlayerError khi playPlaylist ném exception',
      build: () {
        // Simulate service failure
        when(() => mockService.playPlaylist(any(), startIndex: any(named: 'startIndex')))
            .thenThrow(Exception('Network error: unable to stream audio'));
        return _makeBloc();
      },
      act: (bloc) => bloc.add(LoadPlaylistEvent(playlist)),
      expect: () => [
        // 1. Trước tiên phải emit Loading
        isA<PlayerLoading>(),
        // 2. Sau đó emit Error với message
        isA<PlayerError>().having(
          (s) => s.message,
          'error message',
          contains('Failed to load playlist'),
        ),
      ],
      verify: (_) {
        // Đảm bảo service được gọi đúng 1 lần
        verify(() => mockService.playPlaylist(any(),
            startIndex: any(named: 'startIndex'))).called(1);
      },
    );

    blocTest<PlayerBloc, PlayerState>(
      'emit PlayerLoading với đúng bài hát ở startIndex',
      build: () {
        final songs = [_makeSong(id: 'a'), _makeSong(id: 'b'), _makeSong(id: 'c')];
        when(() => mockService.playPlaylist(any(), startIndex: 2))
            .thenAnswer((_) async {});
        return _makeBloc();
      },
      act: (bloc) => bloc.add(
        LoadPlaylistEvent(
          [_makeSong(id: 'a'), _makeSong(id: 'b'), _makeSong(id: 'c')],
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
        return _makeBloc();
      },
      act: (bloc) => bloc.add(const PlayEvent()),
      verify: (_) {
        verify(() => mockService.play()).called(1);
      },
    );

    blocTest<PlayerBloc, PlayerState>(
      'PauseEvent gọi service.pause()',
      build: () {
        when(() => mockService.pause()).thenAnswer((_) async {});
        return _makeBloc();
      },
      act: (bloc) => bloc.add(const PauseEvent()),
      verify: (_) {
        verify(() => mockService.pause()).called(1);
      },
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
        return _makeBloc();
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
        return _makeBloc();
      },
      act: (bloc) => bloc.add(const NextEvent()),
      verify: (_) => verify(() => mockService.next()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'PreviousEvent gọi service.previous() khi position < 3s',
      build: () {
        when(() => mockService.previous()).thenAnswer((_) async {});
        return _makeBloc();
      },
      act: (bloc) => bloc.add(const PreviousEvent()),
      verify: (_) => verify(() => mockService.previous()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'PreviousEvent gọi service.seek(0) khi position > 3s',
      build: () {
        when(() => mockService.seek(any())).thenAnswer((_) async {});
        // Giả lập position > 3s bằng cách set _position trực tiếp
        // (dùng StreamController để push position trước)
        final posCtrl = StreamController<Duration>.broadcast();
        when(() => mockService.positionStream)
            .thenAnswer((_) => posCtrl.stream);
        final bloc = PlayerBloc(mockService);
        posCtrl.add(const Duration(seconds: 10)); // set position > 3s
        return bloc;
      },
      act: (bloc) async {
        await Future.delayed(const Duration(milliseconds: 50)); // let stream emit
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
      'lần đầu toggle → bật shuffle (AudioServiceShuffleMode.all)',
      build: () {
        final mockHandler = MockMyAudioHandler();
        when(() => mockService.handler).thenReturn(mockHandler);
        when(() => mockHandler.setShuffleMode(any()))
            .thenAnswer((_) async {});
        return _makeBloc();
      },
      act: (bloc) => bloc.add(const ToggleShuffleEvent()),
      verify: (bloc) {
        verify(() => mockService.handler
            .setShuffleMode(AudioServiceShuffleMode.all)).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 7: CycleRepeatEvent
  // ═══════════════════════════════════════════════════════════
  group('CycleRepeatEvent — chu kỳ none → one → all → none', () {
    test('chu kỳ RepeatMode đúng thứ tự', () async {
      final mockHandler = MockMyAudioHandler();
      when(() => mockService.handler).thenReturn(mockHandler);
      when(() => mockHandler.setRepeatMode(any())).thenAnswer((_) async {});

      final bloc = _makeBloc();

      // none → one
      bloc.add(const CycleRepeatEvent());
      await Future.delayed(const Duration(milliseconds: 10));
      verify(() => mockHandler.setRepeatMode(AudioServiceRepeatMode.one))
          .called(1);

      // one → all
      bloc.add(const CycleRepeatEvent());
      await Future.delayed(const Duration(milliseconds: 10));
      verify(() => mockHandler.setRepeatMode(AudioServiceRepeatMode.all))
          .called(1);

      // all → none
      bloc.add(const CycleRepeatEvent());
      await Future.delayed(const Duration(milliseconds: 10));
      verify(() => mockHandler.setRepeatMode(AudioServiceRepeatMode.none))
          .called(1);

      await bloc.close();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GROUP 8: Stream → State mapping
  // ═══════════════════════════════════════════════════════════
  group('Playback stream → State mapping', () {
    test('playbackStateStream playing=true → emit PlayerPlaying', () async {
      final song     = _makeSong();
      final pbCtrl   = StreamController<PlaybackState>.broadcast();
      final mediaCtrl = StreamController<MediaItem?>.broadcast();
      final posCtrl  = StreamController<Duration>.broadcast();

      when(() => mockService.playbackStateStream)
          .thenAnswer((_) => pbCtrl.stream);
      when(() => mockService.currentSongStream)
          .thenAnswer((_) => mediaCtrl.stream);
      when(() => mockService.positionStream)
          .thenAnswer((_) => posCtrl.stream);

      final bloc = PlayerBloc(mockService);

      // Push current song first
      mediaCtrl.add(song);
      await Future.delayed(const Duration(milliseconds: 10));

      // Push playing state
      pbCtrl.add(PlaybackState(playing: true,
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