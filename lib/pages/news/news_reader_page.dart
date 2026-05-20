import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../widgets/mini_player_bar.dart';

class NewsReaderPage extends StatefulWidget {
  final String url;
  final String title;
  final String source;

  const NewsReaderPage({
    super.key,
    required this.url,
    required this.title,
    required this.source,
  });

  @override
  State<NewsReaderPage> createState() => _NewsReaderPageState();
}

class _NewsReaderPageState extends State<NewsReaderPage> {
  bool _loading = true;
  String _error = '';
  String _resolvedTitle = '';
  String _description = '';
  String _imageUrl = '';
  List<String> _content = const [];

  static String get _backendBaseUrl {
    // Backend Flask (app.py) chạy port 5000.
    // - Web/Windows/macOS/Linux: dùng localhost
    // - Android emulator: localhost của emulator != localhost máy => dùng 10.0.2.2
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  @override
  void initState() {
    super.initState();
    _resolvedTitle = widget.title;
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      final uri = Uri.parse('$_backendBaseUrl/api/news/article').replace(
        queryParameters: {'url': widget.url},
      );

      debugPrint('🔍 Đang tải bài báo từ: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      
      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final jsonMap =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      debugPrint('✅ Đã parse JSON: ${jsonMap.keys}');

      if (!mounted) return;

      setState(() {
        _resolvedTitle =
            (jsonMap['title'] as String?)?.trim().isNotEmpty == true
                ? (jsonMap['title'] as String).trim()
                : widget.title;
        _description = (jsonMap['description'] as String?)?.trim() ?? '';
        _imageUrl = (jsonMap['imageUrl'] as String?)?.trim() ?? '';
        _content = (jsonMap['content'] as List?)
                ?.whereType<String>()
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [];
        _loading = false;
      });
      
      debugPrint('✅ Đã load ${_content.length} đoạn nội dung');
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi khi tải bài báo: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được nội dung bài báo.\n\nLỗi: $e\n\nVui lòng kiểm tra:\n1. Backend Flask đang chạy (python app.py)\n2. URL backend: $_backendBaseUrl';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        titleSpacing: 0,
        title: Text(
          'Đọc báo',
          style: GoogleFonts.syne(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
      bottomSheet: const MiniPlayerBar(),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 74),
          child: _loading
              ? _buildLoading(theme, isLight)
              : _error.isNotEmpty
                  ? _buildError(theme)
                  : _buildContent(theme, isLight),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme, bool isLight) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _skeletonLine(widthFactor: 0.9, theme: theme, isLight: isLight),
        const SizedBox(height: 10),
        _skeletonLine(widthFactor: 0.65, theme: theme, isLight: isLight),
        const SizedBox(height: 14),
        _skeletonBox(height: 180, theme: theme, isLight: isLight),
        const SizedBox(height: 16),
        ...List.generate(
          8,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _skeletonLine(
              widthFactor: i.isEven ? 0.95 : 0.8,
              theme: theme,
              isLight: isLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: kSubText, size: 48),
            const SizedBox(height: 12),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: kSubText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kAccent, kAccentPink]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isLight) {
    final onSurface = theme.colorScheme.onSurface;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kAccent, kAccentPink]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.source,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _resolvedTitle,
          style: GoogleFonts.plusJakartaSans(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        if (_description.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _description.trim(),
            style: GoogleFonts.dmSans(
              color: onSurface.withValues(alpha: 0.78),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
        if (_imageUrl.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isLight
                      ? theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6)
                      : kCard,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (_content.isEmpty)
          Text(
            'Bài này không trích xuất được nội dung. Bạn có thể mở link gốc để xem đầy đủ.',
            style: GoogleFonts.dmSans(
              color: onSurface.withValues(alpha: 0.72),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          )
        else
          ..._content.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                p,
                style: GoogleFonts.dmSans(
                  color: onSurface.withValues(alpha: 0.86),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        _buildSourceLink(theme, isLight),
      ],
    );
  }

  Widget _buildSourceLink(ThemeData theme, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nguồn',
            style: GoogleFonts.dmSans(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine({
    required double widthFactor,
    required ThemeData theme,
    required bool isLight,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: _skeletonBox(height: 14, theme: theme, isLight: isLight),
    );
  }

  Widget _skeletonBox({
    required double height,
    required ThemeData theme,
    required bool isLight,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isLight
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : kCard,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}