import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/router/app_routes.dart';
import '../../domain/entities/user_search_result_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../presentation/bloc/user_profile/user_profile_cubit.dart';
import '../../presentation/bloc/user_profile/user_profile_state.dart';

class UserProfileViewPage extends StatelessWidget {
  final String userId;

  const UserProfileViewPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserProfileCubit>(
      create: (_) => getIt<UserProfileCubit>()..loadUserProfile(userId),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<UserProfileCubit, UserProfileState>(
        builder: (context, state) {
          if (state is UserProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: kAccent,
                strokeWidth: 2.5,
              ),
            );
          }
          if (state is UserProfileError) {
            return _ErrorView(message: state.message, scheme: scheme);
          }
          if (state is UserProfileLoaded) {
            return _ProfileContent(user: state.user);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final UserSearchResultEntity user;

  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  late final Future<_ProfileSupplementalData> _supplementalFuture;

  @override
  void initState() {
    super.initState();
    _supplementalFuture = _loadSupplementalData(widget.user.id);
  }

  Future<_ProfileSupplementalData> _loadSupplementalData(String userId) async {
    final supabase = Supabase.instance.client;

    try {
      final results = await Future.wait<dynamic>([
        supabase.from('profiles').select(
          'created_at, favorite_genres, listening_moods, music_level',
        ).eq('id', userId).maybeSingle(),
        supabase.from('favorites').select('song_id').eq('user_id', userId),
        supabase.from('listening_history').select(
          'song_id, song_title, song_artist, song_art_uri, played_at',
        ).eq('user_id', userId).order('played_at', ascending: false),
        supabase.from('user_songs').select(
          'id, title, artist, art_url, status, created_at',
        ).eq('user_id', userId).order('created_at', ascending: false),
      ]);

      final profileMap = Map<String, dynamic>.from(
        (results[0] as Map<String, dynamic>?) ?? const {},
      );
      final favoritesRows = List<Map<String, dynamic>>.from(results[1] as List);
      final historyRows = List<Map<String, dynamic>>.from(results[2] as List);
      final uploadedRows = List<Map<String, dynamic>>.from(results[3] as List);

      final approvedSongs = uploadedRows
          .where((song) => song['status']?.toString() == 'approved')
          .take(5)
          .map(_ProfileSongItem.fromMap)
          .toList();

      return _ProfileSupplementalData(
        createdAt: DateTime.tryParse(profileMap['created_at']?.toString() ?? ''),
        favoriteGenres: _extractStringList(profileMap['favorite_genres']),
        listeningMoods: _extractStringList(profileMap['listening_moods']),
        musicLevel: _normalizedText(profileMap['music_level']?.toString()),
        favoritesCount: favoritesRows.length,
        listeningCount: historyRows.length,
        uploadedSongsCount: uploadedRows.length,
        recentHistory: historyRows.take(5).map(_RecentSongItem.fromMap).toList(),
        approvedSongs: approvedSongs,
      );
    } catch (_) {
      return const _ProfileSupplementalData();
    }
  }

  static List<String> _extractStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }

    if (raw is String) {
      return raw
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static String? _normalizedText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final displayName = (user.name?.trim().isNotEmpty == true)
        ? user.name!.trim()
        : 'Người dùng';

    return FutureBuilder<_ProfileSupplementalData>(
      future: _supplementalFuture,
      builder: (context, snapshot) {
        final supplemental = snapshot.data ?? const _ProfileSupplementalData();
        final infoItems = <_InfoItem>[
          _InfoItem(
            icon: Icons.badge_outlined,
            label: 'ID người dùng',
            value: user.id,
          ),
          if ((user.bio?.trim().isNotEmpty ?? false))
            _InfoItem(
              icon: Icons.notes_rounded,
              label: 'Tiểu sử',
              value: user.bio!.trim(),
              multiline: true,
            ),
          if ((user.location?.trim().isNotEmpty ?? false))
            _InfoItem(
              icon: Icons.location_on_outlined,
              label: 'Địa điểm',
              value: user.location!.trim(),
            ),
          if ((user.website?.trim().isNotEmpty ?? false))
            _InfoItem(
              icon: Icons.language_outlined,
              label: 'Website',
              value: user.website!.trim(),
            ),
          if ((user.email?.trim().isNotEmpty ?? false))
            _InfoItem(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: user.email!.trim(),
            ),
        ];

        final hasTasteSection = supplemental.musicLevel != null ||
            supplemental.favoriteGenres.isNotEmpty ||
            supplemental.listeningMoods.isNotEmpty;
        final hasStatsSection = supplemental.favoritesCount > 0 ||
            supplemental.listeningCount > 0 ||
            supplemental.uploadedSongsCount > 0;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              stretch: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [kAccent, kAccentPink],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.68),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 28),
                            _LargeAvatar(
                              displayName: displayName,
                              avatarUrl: user.avatarUrl,
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(
                                displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (supplemental.createdAt != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  'Tham gia ${_formatDate(supplemental.createdAt!)}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nút Nhắn tin — chỉ hiện khi xem profile người khác
                    if (Supabase.instance.client.auth.currentUser?.id != user.id)
                      _ChatActionButton(user: user),
                    if (hasStatsSection) ...[
                      _SectionTitle(title: 'Tổng quan'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Đã thích',
                              value: supplemental.favoritesCount,
                              icon: Icons.favorite_outline_rounded,
                              scheme: scheme,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Lượt nghe',
                              value: supplemental.listeningCount,
                              icon: Icons.graphic_eq_rounded,
                              scheme: scheme,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Đã đăng',
                              value: supplemental.uploadedSongsCount,
                              icon: Icons.library_music_outlined,
                              scheme: scheme,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (supplemental.recentHistory.isNotEmpty) ...[
                      _SectionTitle(title: 'Nghe gần đây'),
                      const SizedBox(height: 12),
                      _SectionCard(
                        scheme: scheme,
                        isDark: isDark,
                        child: Column(
                          children: [
                            for (var i = 0; i < supplemental.recentHistory.length; i++) ...[
                              _SongListTile(
                                title: supplemental.recentHistory[i].title,
                                subtitle: supplemental.recentHistory[i].subtitle,
                                trailing: supplemental.recentHistory[i].playedAt != null
                                    ? _formatDateTimeShort(
                                        supplemental.recentHistory[i].playedAt!,
                                      )
                                    : null,
                                imageUrl: supplemental.recentHistory[i].imageUrl,
                                fallbackIcon: Icons.history_rounded,
                              ),
                              if (i != supplemental.recentHistory.length - 1)
                                _Divider(scheme: scheme),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (supplemental.approvedSongs.isNotEmpty) ...[
                      _SectionTitle(title: 'Bài hát đã đăng'),
                      const SizedBox(height: 12),
                      _SectionCard(
                        scheme: scheme,
                        isDark: isDark,
                        child: Column(
                          children: [
                            for (var i = 0; i < supplemental.approvedSongs.length; i++) ...[
                              _SongListTile(
                                title: supplemental.approvedSongs[i].title,
                                subtitle: supplemental.approvedSongs[i].artist,
                                trailing: _formatDate(
                                  supplemental.approvedSongs[i].createdAt,
                                ),
                                imageUrl: supplemental.approvedSongs[i].imageUrl,
                                fallbackIcon: Icons.music_note_rounded,
                              ),
                              if (i != supplemental.approvedSongs.length - 1)
                                _Divider(scheme: scheme),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (hasTasteSection) ...[
                      _SectionTitle(title: 'Gu âm nhạc'),
                      const SizedBox(height: 12),
                      _SectionCard(
                        scheme: scheme,
                        isDark: isDark,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (supplemental.musicLevel != null) ...[
                                _TasteLine(
                                  label: 'Trình độ',
                                  value: supplemental.musicLevel!,
                                ),
                              ],
                              if (supplemental.favoriteGenres.isNotEmpty) ...[
                                if (supplemental.musicLevel != null)
                                  const SizedBox(height: 16),
                                _TasteTags(
                                  label: 'Thể loại yêu thích',
                                  values: supplemental.favoriteGenres,
                                  scheme: scheme,
                                  isDark: isDark,
                                ),
                              ],
                              if (supplemental.listeningMoods.isNotEmpty) ...[
                                if (supplemental.musicLevel != null ||
                                    supplemental.favoriteGenres.isNotEmpty)
                                  const SizedBox(height: 16),
                                _TasteTags(
                                  label: 'Mood thường nghe',
                                  values: supplemental.listeningMoods,
                                  scheme: scheme,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (infoItems.isNotEmpty) ...[
                      _SectionTitle(title: 'Thông tin'),
                      const SizedBox(height: 12),
                      _SectionCard(
                        scheme: scheme,
                        isDark: isDark,
                        child: Column(
                          children: [
                            for (var i = 0; i < infoItems.length; i++) ...[
                              _InfoTile(item: infoItems[i]),
                              if (i != infoItems.length - 1) _Divider(scheme: scheme),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  static String _formatDateTimeShort(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute';
  }
}

class _ProfileSupplementalData {
  final DateTime? createdAt;
  final List<String> favoriteGenres;
  final List<String> listeningMoods;
  final String? musicLevel;
  final int favoritesCount;
  final int listeningCount;
  final int uploadedSongsCount;
  final List<_RecentSongItem> recentHistory;
  final List<_ProfileSongItem> approvedSongs;

  const _ProfileSupplementalData({
    this.createdAt,
    this.favoriteGenres = const [],
    this.listeningMoods = const [],
    this.musicLevel,
    this.favoritesCount = 0,
    this.listeningCount = 0,
    this.uploadedSongsCount = 0,
    this.recentHistory = const [],
    this.approvedSongs = const [],
  });
}

class _RecentSongItem {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final DateTime? playedAt;

  const _RecentSongItem({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.playedAt,
  });

  factory _RecentSongItem.fromMap(Map<String, dynamic> map) {
    final title = map['song_title']?.toString().trim();
    final artist = map['song_artist']?.toString().trim();

    return _RecentSongItem(
      title: (title != null && title.isNotEmpty) ? title : 'Bài hát không tên',
      subtitle: (artist != null && artist.isNotEmpty)
          ? artist
          : 'Không rõ nghệ sĩ',
      imageUrl: _cleanImageUrl(map['song_art_uri']?.toString()),
      playedAt: DateTime.tryParse(map['played_at']?.toString() ?? ''),
    );
  }
}

class _ProfileSongItem {
  final String title;
  final String artist;
  final String? imageUrl;
  final DateTime createdAt;

  const _ProfileSongItem({
    required this.title,
    required this.artist,
    required this.createdAt,
    this.imageUrl,
  });

  factory _ProfileSongItem.fromMap(Map<String, dynamic> map) {
    final title = map['title']?.toString().trim();
    final artist = map['artist']?.toString().trim();

    return _ProfileSongItem(
      title: (title != null && title.isNotEmpty) ? title : 'Bài hát không tên',
      artist: (artist != null && artist.isNotEmpty)
          ? artist
          : 'Không rõ nghệ sĩ',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      imageUrl: _cleanImageUrl(map['art_url']?.toString()),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });
}

class _LargeAvatar extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;

  const _LargeAvatar({required this.displayName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: kAccent,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (_, __, ___) =>
                      _AvatarInitial(name: displayName, size: 38),
                )
              : _AvatarInitial(name: displayName, size: 38),
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String name;
  final double size;

  const _AvatarInitial({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.syne(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        height: 1.15,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final ColorScheme scheme;
  final bool isDark;

  const _SectionCard({
    required this.child,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : kAccent.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final ColorScheme scheme;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.34),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  kAccent.withValues(alpha: 0.16),
                  kAccentPink.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: Icon(icon, color: kAccent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final String? imageUrl;
  final IconData fallbackIcon;

  const _SongListTile({
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    this.trailing,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _SongArtwork(
            imageUrl: imageUrl,
            fallbackIcon: fallbackIcon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                trailing!,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: scheme.onSurface.withValues(alpha: 0.46),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SongArtwork extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;

  const _SongArtwork({
    required this.imageUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final validImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        color: scheme.surfaceContainerHighest,
        child: validImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: scheme.surfaceContainerHighest,
                ),
                errorWidget: (_, __, ___) => Icon(
                  fallbackIcon,
                  color: kAccent,
                  size: 22,
                ),
              )
            : Icon(
                fallbackIcon,
                color: kAccent,
                size: 22,
              ),
      ),
    );
  }
}

class _TasteLine extends StatelessWidget {
  final String label;
  final String value;

  const _TasteLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _TasteTags extends StatelessWidget {
  final String label;
  final List<String> values;
  final ColorScheme scheme;
  final bool isDark;

  const _TasteTags({
    required this.label,
    required this.values,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        kAccent.withValues(alpha: isDark ? 0.18 : 0.12),
                        kAccentPink.withValues(alpha: isDark ? 0.14 : 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: kAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    value,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;

  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment:
            item.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: kAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: item.multiline ? 1.5 : 1.4,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme scheme;

  const _Divider({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: scheme.outline.withValues(alpha: 0.1),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final ColorScheme scheme;

  const _ErrorView({required this.message, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatActionButton extends StatefulWidget {
  final UserSearchResultEntity user;

  const _ChatActionButton({required this.user});

  @override
  State<_ChatActionButton> createState() => _ChatActionButtonState();
}

class _ChatActionButtonState extends State<_ChatActionButton> {
  bool _isLoading = false;

  Future<void> _openChat() async {
    setState(() => _isLoading = true);
    final repo = getIt<ChatRepository>();
    final displayName = (widget.user.name?.trim().isNotEmpty == true)
        ? widget.user.name!.trim()
        : 'Người dùng';

    final result = await repo.findOrCreateConversation(widget.user.id);
    if (!mounted) return;

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message,
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (conversationId) {
        Navigator.of(context).pushNamed(
          AppRoutes.chat,
          arguments: {
            'conversationId': conversationId,
            'otherUserName': displayName,
            'otherUserId': widget.user.id,
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _openChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
            label: Text(
              _isLoading ? 'Đang mở...' : 'Nhắn tin',
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _cleanImageUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
