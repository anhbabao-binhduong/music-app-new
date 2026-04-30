import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../data/local_music_data.dart';
import '../../../../widgets/auth_guard.dart';

class BannerData {
  final String imageUrl;
  final List<Color> gradient;
  final String label;
  final String sub;

  const BannerData({
    required this.imageUrl,
    required this.gradient,
    required this.label,
    required this.sub,
  });
}

class HeroBanner extends StatefulWidget {
  final BannerData data;
  const HeroBanner({super.key, required this.data});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth > 750 ? 320.0 : 240.0;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          height: bannerHeight,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image (async shimmer)
                Image.network(
                  widget.data.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildBannerShimmer(isLight);
                  },
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.data.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // Blur overlay
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: cs.scrim.withValues(alpha: isLight ? 0.14 : 0.22),
                  ),
                ),

                // Gradient overlay - stronger at bottom (tokenized scrim)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        cs.scrim.withValues(alpha: 0.28),
                        cs.scrim.withValues(alpha: 0.72),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          'FEATURED',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                       // Title
                       Flexible(
                         child: Text(
                           widget.data.label,
                           style: GoogleFonts.plusJakartaSans(
                             color: Colors.white,
                             fontSize: 32,
                             fontWeight: FontWeight.w800,
                             letterSpacing: -0.6,
                             height: 1.1,
                             shadows: [
                               Shadow(
                                 color: cs.scrim.withValues(alpha: 0.55),
                                 blurRadius: 14,
                                 offset: const Offset(0, 3),
                               ),
                             ],
                           ),
                           maxLines: 2,
                           overflow: TextOverflow.visible,
                           softWrap: true,
                         ),
                       ),
                      const SizedBox(height: 8),

                       // Subtitle
                       Flexible(
                         child: Text(
                           widget.data.sub,
                           style: GoogleFonts.dmSans(
                             color: Colors.white.withValues(alpha: 0.82),
                             fontSize: 14,
                             fontWeight: FontWeight.w500,
                             height: 1.45,
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.visible,
                           softWrap: true,
                         ),
                       ),
                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          _PlayButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerShimmer(bool isLight) {
    return Shimmer.fromColors(
      baseColor: isLight ? const Color(0xFFE8E2FF) : const Color(0xFF1E1E2E),
      highlightColor: isLight ? const Color(0xFFF8F5FF) : const Color(0xFF2B2B40),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: _isHovered ? 0.45 : 0.28),
                  blurRadius: _isHovered ? 22 : 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                if (localPlaylist.isNotEmpty) {
                  playWithAuthGuard(context, playlist: localPlaylist, index: 0);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Chưa có bài hát nào để phát',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                'Phát ngay',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

