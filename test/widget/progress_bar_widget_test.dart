import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_app/widgets/progress_bar_widget.dart';
import 'package:music_app/services/music_player_service.dart';

// ─── Mock ────────────────────────────────────────────────────

class MockMusicPlayerService extends Mock implements MusicPlayerService {}

// ─── Test Helper ─────────────────────────────────────────────

/// Wrap widget với MaterialApp + Theme để tránh lỗi context
Widget _buildWidget({
  required MusicPlayerService service,
  required ValueChanged<Duration> onSeek,
}) =>
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: ProgressBarWidget(service: service, onSeek: onSeek),
        ),
      ),
    );

// ─────────────────────────────────────────────────────────────

void main() {
  late MockMusicPlayerService mockService;
  late StreamController<Duration>  posCtrl;
  late StreamController<Duration?> durCtrl;

  setUp(() {
    mockService = MockMusicPlayerService();
    posCtrl     = StreamController<Duration>.broadcast();
    durCtrl     = StreamController<Duration?>.broadcast();

    when(() => mockService.positionStream)
        .thenAnswer((_) => posCtrl.stream);
    when(() => mockService.durationStream)
        .thenAnswer((_) => durCtrl.stream);
  });

  tearDown(() async {
    await posCtrl.close();
    await durCtrl.close();
  });

  // ═══════════════════════════════════════════════════════════
  // TEST 1: Render ban đầu
  // ═══════════════════════════════════════════════════════════
  testWidgets('hiển thị "00:00" khi chưa có stream data', (tester) async {
    await tester.pumpWidget(_buildWidget(
      service: mockService,
      onSeek: (_) {},
    ));
    await tester.pump();

    // Cả hai timestamp đều là 00:00
    expect(find.text('00:00'), findsNWidgets(2));
    // Slider render thành công
    expect(find.byType(Slider), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════
  // TEST 2: Hiển thị thời gian đúng khi stream phát data
  // ═══════════════════════════════════════════════════════════
  testWidgets('hiển thị đúng position và duration từ stream', (tester) async {
    await tester.pumpWidget(_buildWidget(
      service: mockService,
      onSeek: (_) {},
    ));

    // Emit position = 1:30, duration = 3:45
    posCtrl.add(const Duration(minutes: 1, seconds: 30));
    durCtrl.add(const Duration(minutes: 3, seconds: 45));

    // Pump để StreamBuilder rebuild
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('03:45'), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════
  // TEST 3: Slider value đúng theo tỷ lệ
  // ═══════════════════════════════════════════════════════════
  testWidgets('Slider value = 0.5 khi position = duration / 2', (tester) async {
    await tester.pumpWidget(_buildWidget(
      service: mockService,
      onSeek: (_) {},
    ));

    posCtrl.add(const Duration(seconds: 60));
    durCtrl.add(const Duration(seconds: 120));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, closeTo(0.5, 0.01));
  });

  // ═══════════════════════════════════════════════════════════
  // TEST 4: ✅ CRITICAL — Kéo Slider → gọi onSeek đúng Duration
  // ═══════════════════════════════════════════════════════════
  testWidgets('kéo Slider đến 75% → onSeek nhận Duration đúng', (tester) async {
    Duration? seekedTo;

    await tester.pumpWidget(_buildWidget(
      service: mockService,
      onSeek: (d) => seekedTo = d,
    ));

    // Set duration = 200s để tính dễ
    posCtrl.add(const Duration(seconds: 50));
    durCtrl.add(const Duration(seconds: 200));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    // Tìm vị trí Slider trên screen
    final sliderFinder = find.byType(Slider);
    final sliderBox    = tester.getRect(sliderFinder);

    // Drag đến 75% chiều rộng của Slider
    final startPoint = sliderBox.centerLeft + Offset(sliderBox.width * 0.25, 0);
    final endPoint   = sliderBox.centerLeft + Offset(sliderBox.width * 0.75, 0);

    await tester.dragFrom(startPoint, endPoint - startPoint);
    await tester.pump();

    // onSeek phải được gọi
    expect(seekedTo, isNotNull);

    // Duration phải gần 75% × 200s = 150s (cho phép sai số ±3s)
    expect(
      seekedTo!.inSeconds,
      closeTo(150, 3),
      reason: 'Kéo đến 75% của 200s phải seek đến ~150s',
    );
  });

  // ═══════════════════════════════════════════════════════════
  // TEST 5: Slider không vượt quá 0.0 → 1.0
  // ═══════════════════════════════════════════════════════════
  testWidgets('Slider value luôn trong khoảng [0.0, 1.0]', (tester) async {
    await tester.pumpWidget(_buildWidget(
      service: mockService,
      onSeek: (_) {},
    ));

    // Edge case: position > duration (xảy ra khi stream lag)
    posCtrl.add(const Duration(seconds: 999));
    durCtrl.add(const Duration(seconds: 100));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, lessThanOrEqualTo(1.0));
    expect(slider.value, greaterThanOrEqualTo(0.0));
  });

  // ═══════════════════════════════════════════════════════════
  // TEST 6: Không rebuild không cần thiết (performance)
  // ═══════════════════════════════════════════════════════════
  testWidgets('chỉ ProgressBarWidget rebuild khi stream emit, không phải parent', (tester) async {
    int parentBuildCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) {
          parentBuildCount++;
          return SizedBox(
            width: 400,
            child: ProgressBarWidget(service: mockService, onSeek: (_) {}),
          );
        }),
      ),
    ));

    final initialCount = parentBuildCount;

    // Emit 5 position updates
    for (var i = 1; i <= 5; i++) {
      posCtrl.add(Duration(seconds: i * 10));
      await tester.pump(const Duration(milliseconds: 30));
    }

    // Parent KHÔNG được rebuild thêm
    expect(parentBuildCount, equals(initialCount),
        reason: 'Parent widget không được rebuild khi chỉ có stream tick');
  });
}