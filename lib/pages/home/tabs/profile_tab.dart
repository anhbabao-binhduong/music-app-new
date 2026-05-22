import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/user_song_model.dart';
import '../../../presentation/bloc/admin/admin_cubit.dart';
import '../../../presentation/bloc/admin/admin_state.dart';
import '../../../presentation/bloc/player/player_bloc.dart';
import '../../../presentation/bloc/player/player_event.dart';
import '../../../presentation/bloc/player/player_state.dart';
import '../../../presentation/bloc/user_songs/user_songs_cubit.dart';
import '../../admin/admin_dashboard_page.dart';
import '../../auth/login_page.dart';
import '../../auth/register_page.dart';
import '../../profile/comment_history_page.dart';
import '../../profile/edit_profile_page.dart';
import '../../profile/help_detail_page.dart';
import '../../profile/notifications_page.dart';
import '../../profile/settings_page.dart';
import '../../upload/upload_music_sheet.dart';
import '../../user_search/user_search_page.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/chat_notification_service.dart';
import '../../../core/router/app_routes.dart';

class ProfileTab extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final String userEmail;
  final String? userId;
  final String? userAvatarUrl;
  final Future<void> Function() onLogout;
  final int favoriteCount;
  final int playlistCount;
  final int downloadCount;
  final VoidCallback? onProfileUpdated;

  const ProfileTab({
    super.key,
    required this.isLoggedIn,
    required this.userName,
    required this.userEmail,
    this.userId,
    this.userAvatarUrl,
    required this.onLogout,
    this.favoriteCount = 0,
    this.playlistCount = 0,
    this.downloadCount = 0,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return isLoggedIn
        ? _LoggedInProfile(
            userName: userName,
            userEmail: userEmail,
            userId: userId,
            userAvatarUrl: userAvatarUrl,
            onLogout: onLogout,
            favoriteCount: favoriteCount,
            playlistCount: playlistCount,
            downloadCount: downloadCount,
            onProfileUpdated: onProfileUpdated,
          )
        : const _GuestProfile();
  }
}

class _ProfilePalette {
  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color text;
  final Color muted;
  final Color softText;
  final Color accent;
  final Color accentSecondary;
  final Color shadow;
  final Color destructive;

  const _ProfilePalette({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.text,
    required this.muted,
    required this.softText,
    required this.accent,
    required this.accentSecondary,
    required this.shadow,
    required this.destructive,
  });

  factory _ProfilePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return _ProfilePalette(
      background: theme.scaffoldBackgroundColor,
      surface: scheme.surface,
      elevated: scheme.surfaceContainerHighest,
      border: scheme.outline.withValues(alpha: isDark ? 0.55 : 0.75),
      text: scheme.onSurface,
      muted: scheme.onSurface.withValues(alpha: 0.68),
      softText: scheme.onSurface.withValues(alpha: 0.48),
      accent: scheme.primary,
      accentSecondary: scheme.secondary,
      shadow: isDark
          ? Colors.black.withValues(alpha: 0.30)
          : const Color(0xFF2D1457).withValues(alpha: 0.08),
      destructive: scheme.error,
    );
  }

  LinearGradient get accentGradient => const LinearGradient(
        colors: [kAccent, kAccentPink],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient heroGradient(bool isDark) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF19132F),
                accent.withValues(alpha: 0.82),
                accentSecondary.withValues(alpha: 0.74),
              ]
            : [
                accent.withValues(alpha: 0.92),
                accentSecondary.withValues(alpha: 0.86),
                const Color(0xFFFFF3FB),
              ],
      );
}

// ── Guest ─────────────────────────────────────────────────────────────────────

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ProfilePalette.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final hasPlayer = playerState is PlayerPlaying || 
                          playerState is PlayerPaused;
        final bottomPad = hasPlayer ? 74.0 : 16.0;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroGuestCard(palette: palette, isDark: isDark),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Quyền lợi khi đăng nhập',
                    subtitle: 'Cá nhân hóa trải nghiệm âm nhạc như Spotify',
                  ),
                  const SizedBox(height: 14),
                  ..._kFeatures.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeatureRow(
                        icon: f.$1,
                        label: f.$2,
                        sub: f.$3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroGuestCard extends StatelessWidget {
  final _ProfilePalette palette;
  final bool isDark;

  const _HeroGuestCard({
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: palette.heroGradient(isDark),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hồ sơ âm nhạc của bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Đăng nhập để đồng bộ playlist, theo dõi lịch sử nghe, tải lên bài hát và quản lý trải nghiệm cá nhân trên mọi thiết bị.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 24),
              _AuthButton(
                label: 'Đăng nhập',
                isPrimary: true,
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, anim, __) => const LoginPage(),
                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AuthButton(
                label: 'Tạo tài khoản mới',
                isPrimary: false,
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, anim, __) => const RegisterPage(),
                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                      position: Tween(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _kFeatures = [
  (Icons.favorite_rounded, 'Yêu thích bài hát', 'Lưu những bài hát bạn thích'),
  (Icons.queue_music_rounded, 'Tạo playlist', 'Sắp xếp nhạc theo ý muốn'),
  (Icons.download_rounded, 'Tải nhạc offline', 'Nghe không cần mạng'),
  (Icons.history_rounded, 'Lịch sử nghe', 'Xem lại những gì đã nghe'),
];

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: palette.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13,
                    height: 1.5,
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

// ── Logged In ─────────────────────────────────────────────────────────────────

class _LoggedInProfile extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userId;
  final String? userAvatarUrl;
  final Future<void> Function() onLogout;
  final int favoriteCount;
  final int playlistCount;
  final int downloadCount;
  final VoidCallback? onProfileUpdated;

  const _LoggedInProfile({
    required this.userName,
    required this.userEmail,
    this.userId,
    this.userAvatarUrl,
    required this.onLogout,
    required this.favoriteCount,
    required this.playlistCount,
    required this.downloadCount,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ProfilePalette.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final hasPlayer =
            playerState is PlayerPlaying || playerState is PlayerPaused;

        final playerHeight = hasPlayer ? 74.0 : 0.0;
        final bottomPad = kBottomNavigationBarHeight + playerHeight + 16.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    userName: userName,
                    userEmail: userEmail,
                    userAvatarUrl: userAvatarUrl,
                    favoriteCount: favoriteCount,
                    playlistCount: playlistCount,
                    downloadCount: downloadCount,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Tài khoản',
                    subtitle: 'Quản lý hồ sơ, hoạt động và cài đặt cá nhân',
                  ),
                  const SizedBox(height: 14),
                  _SurfaceCard(
                    child: Column(
                      children: _kMenuItems
                          .map(
                            (item) => _MenuItem(
                              icon: item.$1,
                              label: item.$2,
                              trailing: item.$2 == 'Tin nhắn'
                                  ? ValueListenableBuilder<int>(
                                      valueListenable:
                                          getIt<ChatNotificationService>()
                                              .unreadCount,
                                      builder: (context, count, _) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (count > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  count > 99
                                                      ? '99+'
                                                      : count.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: palette.softText,
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  : null,
                              onTap: () async {
                                if (item.$2 == 'Chỉnh sửa hồ sơ' &&
                                    userId != null) {
                                  final user =
                                      Supabase.instance.client.auth.currentUser;
                                  final profileData = {
                                    'name': user?.userMetadata?['name'],
                                    'avatar_url':
                                        user?.userMetadata?['avatar_url'],
                                    'bio': user?.userMetadata?['bio'],
                                    'location':
                                        user?.userMetadata?['location'],
                                    'website':
                                        user?.userMetadata?['website'],
                                  };
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfilePage(
                                        profileData: profileData,
                                      ),
                                    ),
                                  );
                                  if (context.mounted) {
                                    onProfileUpdated?.call();
                                  }
                                } else if (item.$2 == 'Tìm người dùng') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UserSearchPage(),
                                    ),
                                  );
                                } else if (item.$2 == 'Tin nhắn') {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.conversations,
                                  );
                                } else if (item.$2 == 'Lịch sử bình luận' &&
                                    userId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CommentHistoryPage(
                                        userId: userId!,
                                      ),
                                    ),
                                  );
                                } else if (item.$2 == 'Thông báo' &&
                                    userId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsPage(),
                                    ),
                                  );
                                } else if (item.$2 == 'Cài đặt') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsPage(),
                                    ),
                                  );
                                } else if (item.$2 == 'Trợ giúp & Phản hồi') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HelpPages.faq(),
                                    ),
                                  );
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MyMusicSection(userId: userId),
                  const SizedBox(height: 18),
                  const _AdminSection(),
                  const SizedBox(height: 18),
                  _LogoutButton(onLogout: onLogout),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: palette.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: () => showUploadMusicSheet(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.upload_rounded, size: 20),
                        label: const Text(
                          'Upload nhạc',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: kBottomNavigationBarHeight + 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final int favoriteCount;
  final int playlistCount;
  final int downloadCount;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
    required this.favoriteCount,
    required this.playlistCount,
    required this.downloadCount,
  });

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final bio = user?.userMetadata?['bio'] as String?;
    final location = user?.userMetadata?['location'] as String?;
    final theme = Theme.of(context);
    final palette = _ProfilePalette.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: palette.heroGradient(isDark),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HỒ SƠ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarView(
                    userName: userName,
                    userAvatarUrl: userAvatarUrl,
                    size: 96,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                          ),
                        ),
                        if (bio != null && bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            bio,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ],
                        if (location != null && location.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 540;
                  final children = [
                    _StatChip(
                      icon: Icons.download_rounded,
                      label: 'Đã tải',
                      value: downloadCount.toString(),
                      inverse: true,
                    ),
                    _StatChip(
                      icon: Icons.queue_music_rounded,
                      label: 'Playlist',
                      value: playlistCount.toString(),
                      inverse: true,
                    ),
                    _StatChip(
                      icon: Icons.favorite_rounded,
                      label: 'Yêu thích',
                      value: favoriteCount.toString(),
                      inverse: true,
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          children[i],
                          if (i != children.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        Expanded(child: children[i]),
                        if (i != children.length - 1)
                          const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarView extends StatelessWidget {
  final String userName;
  final String? userAvatarUrl;
  final double size;

  const _AvatarView({
    required this.userName,
    required this.userAvatarUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [kAccent, kAccentPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: userAvatarUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              placeholder: (context, url) => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
              errorWidget: (context, url, error) => Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool inverse;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.inverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    final bgColor = inverse
        ? Colors.white.withValues(alpha: 0.14)
        : palette.elevated.withValues(alpha: 0.7);
    final textColor = inverse ? Colors.white : palette.text;
    final mutedColor = inverse
        ? Colors.white.withValues(alpha: 0.76)
        : palette.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: inverse
              ? Colors.white.withValues(alpha: 0.16)
              : palette.border.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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

const _kMenuItems = [
  (Icons.manage_accounts_outlined, 'Chỉnh sửa hồ sơ'),
  (Icons.person_search_rounded, 'Tìm người dùng'),
  (Icons.chat_bubble_outline_rounded, 'Tin nhắn'),
  (Icons.comment_rounded, 'Lịch sử bình luận'),
  (Icons.notifications_outlined, 'Thông báo'),
  (Icons.settings_outlined, 'Cài đặt'),
  (Icons.help_outline_rounded, 'Trợ giúp & Phản hồi'),
];

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: palette.accent.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: palette.elevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: palette.text.withValues(alpha: 0.82)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.softText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBar extends StatelessWidget {
  final _ProfilePalette palette;
  final bool isDark;
  final VoidCallback onUploadTap;

  const _QuickActionBar({
    required this.palette,
    required this.isDark,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: palette.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Không gian sáng tạo',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload bài hát và xây dựng thư viện của riêng bạn',
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onUploadTap,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Tải lên',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return _SurfaceCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final dialogPalette = _ProfilePalette.of(ctx);

                return AlertDialog(
                  backgroundColor: dialogPalette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: dialogPalette.border.withValues(alpha: 0.45),
                    ),
                  ),
                  title: Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: dialogPalette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  content: Text(
                    'Bạn có chắc muốn đăng xuất khỏi tài khoản hiện tại?',
                    style: TextStyle(
                      color: dialogPalette.muted,
                      height: 1.5,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Hủy',
                        style: TextStyle(color: dialogPalette.muted),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: dialogPalette.destructive,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              await onLogout();
            }
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: palette.destructive.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: palette.destructive,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: palette.destructive,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Auth Button ───────────────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: isPrimary
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? palette.accent : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── My Music Section ──────────────────────────────────────────────────────────

class _MyMusicSection extends StatefulWidget {
  final String? userId;

  const _MyMusicSection({this.userId});

  @override
  State<_MyMusicSection> createState() => _MyMusicSectionState();
}

class _MyMusicSectionState extends State<_MyMusicSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userId != null) {
        context.read<UserSongsCubit>().loadMySongs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) return const SizedBox.shrink();

    final palette = _ProfilePalette.of(context);

    return BlocBuilder<UserSongsCubit, List<UserSongModel>>(
      builder: (context, songs) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Nhạc của tôi',
              subtitle: 'Các bài hát bạn đã tải lên và trạng thái kiểm duyệt',
            ),
            const SizedBox(height: 14),
            _SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: palette.accentGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.library_music_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bộ sưu tập đã upload',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${songs.length} bài hát trong thư viện cá nhân',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: palette.muted,
                          size: 20,
                        ),
                        onPressed: () =>
                            context.read<UserSongsCubit>().loadMySongs(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (songs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: palette.elevated.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: palette.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_off_rounded,
                            color: palette.softText,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn chưa upload bài nào',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...songs.map((song) => _UserSongTile(song: song)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserSongTile extends StatelessWidget {
  final UserSongModel song;

  const _UserSongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.elevated.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: song.artUrl != null
              ? Image.network(
                  song.artUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          song.title,
          style: TextStyle(
            color: palette.text,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                song.artist,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              _StatusBadge(status: song.status),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.isApproved)
              IconButton(
                icon: const Icon(
                  Icons.play_circle_rounded,
                  color: kAccent,
                  size: 30,
                ),
                onPressed: () => _playUserSong(context, song),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: palette.softText,
                size: 20,
              ),
              color: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: palette.border.withValues(alpha: 0.4),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: palette.destructive,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Xóa bài',
                        style: TextStyle(
                          color: palette.destructive,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final dialogPalette = _ProfilePalette.of(ctx);

                      return AlertDialog(
                        backgroundColor: dialogPalette.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color:
                                dialogPalette.border.withValues(alpha: 0.45),
                          ),
                        ),
                        title: Text(
                          'Xóa bài hát',
                          style: TextStyle(
                            color: dialogPalette.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        content: Text(
                          'Xóa "${song.title}" khỏi danh sách của bạn?',
                          style: TextStyle(
                            color: dialogPalette.muted,
                            height: 1.5,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              'Hủy',
                              style: TextStyle(color: dialogPalette.muted),
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: dialogPalette.destructive,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Xóa'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      await context.read<UserSongsCubit>().deleteSong(song);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã xóa "${song.title}"'),
                            backgroundColor: palette.destructive,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Xóa thất bại, thử lại sau'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kAccent, kAccentPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.music_note_rounded,
          color: Colors.white70,
          size: 22,
        ),
      );

  void _playUserSong(BuildContext context, UserSongModel song) {
    final item = song.toMediaItem();
    context.read<PlayerBloc>().add(
          LoadPlaylistEvent(
            [item],
            startIndex: 0,
          ),
        );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('✓ Đã duyệt', Colors.green),
      'rejected' => ('✗ Từ chối', Colors.redAccent),
      _ => ('⏳ Chờ duyệt', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Admin Section Widget ──────────────────────────────────────────────────────

class _AdminSection extends StatelessWidget {
  const _AdminSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final supabase = Supabase.instance.client;
        final uid = supabase.auth.currentUser?.id;
        if (uid == null) return const SizedBox.shrink();

        return FutureBuilder<String>(
          future: _getRole(uid),
          builder: (context, snap) {
            final role = snap.data ?? '';
            if (role != 'admin' && role != 'moderator') {
              return const SizedBox.shrink();
            }

            final palette = _ProfilePalette.of(context);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  title: 'Quản trị',
                  subtitle: 'Truy cập công cụ quản lý nội dung và hệ thống',
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AdminCubit>(),
                        child: const AdminDashboardPage(),
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          palette.accent.withValues(alpha: 0.16),
                          palette.accentSecondary.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.shadow.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kAccent, kAccentPink],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trang quản trị',
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role == 'admin'
                                    ? 'Admin • Toàn quyền'
                                    : 'Moderator • Kiểm duyệt nội dung',
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: palette.softText,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _getRole(String uid) async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      return res['role'] as String? ?? 'user';
    } catch (_) {
      return 'user';
    }
  }
}