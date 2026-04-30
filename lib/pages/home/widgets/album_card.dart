import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../domain/entities/album_entity.dart';

class AlbumCard extends StatefulWidget {
  final AlbumEntity album;
  final VoidCallback onTap;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
    this.width,
    this.margin,
  });

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: widget.width ?? double.infinity,
      margin: widget.margin ?? EdgeInsets.zero,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album cover with slightly reduced ratio to fit compact layouts
              AspectRatio(
                aspectRatio: 1.08,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.diagonal3Values(
                    _isHovered ? 1.05 : 1.0,
                    _isHovered ? 1.05 : 1.0,
                    1.0,
                  ),
                  transformAlignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight
                            ? const Color(0xFF6B5EA8)
                                .withValues(alpha: _isHovered ? 0.22 : 0.12)
                            : const Color(0xFF8B8AA8)
                                .withValues(alpha: _isHovered ? 0.22 : 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isLight ? const Color(0xFF6B5EA8) : const Color(0xFF9333EA))
                                  .withValues(alpha: _isHovered ? 0.24 : 0.12),
                          blurRadius: _isHovered ? 24 : 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Album cover image
                          widget.album.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.album.coverUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _buildPlaceholder(),
                                  errorWidget: (_, __, ___) => _buildFallback(),
                                )
                              : _buildFallback(),

                          // Hover overlay with play button
                          AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    cs.scrim.withValues(alpha: 0.18),
                                    cs.scrim.withValues(alpha: 0.58),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF9333EA).withValues(alpha: 0.32),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Album title
              Text(
                widget.album.title,
                style: GoogleFonts.plusJakartaSans(
                  color: cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),

              // Artist name
              Text(
                widget.album.artistName,
                style: GoogleFonts.dmSans(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Shimmer.fromColors(
      baseColor: isLight ? const Color(0xFFE8E2FF) : const Color(0xFF1E1E2E),
      highlightColor: isLight ? const Color(0xFFF8F5FF) : const Color(0xFF2B2B40),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFF4EEFF), Color(0xFFE9E1FF)]
                : const [Color(0xFF1D1B2C), Color(0xFF151523)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFF4EEFF), Color(0xFFE7DFFF)]
              : const [Color(0xFF1D1B2C), Color(0xFF12121E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: 56,
          color: isLight
              ? const Color(0xFF6B5EA8).withValues(alpha: 0.28)
              : theme.colorScheme.onSurface.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}
