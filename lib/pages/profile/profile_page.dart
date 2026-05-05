import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/colors.dart';
import 'edit_profile_page.dart';
import 'help_feedback_section.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> _profileData = {};
  User? _user;

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  Future<void> _reloadProfile() async {
    final auth = Supabase.instance.client.auth;
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _profileData = {};
      });
      return;
    }

    Map<String, dynamic> metadata = {
      ...?currentUser.userMetadata,
    };

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (profile is Map<String, dynamic>) {
        metadata = {
          ...metadata,
          ...profile,
        };
      }
    } catch (_) {}

    final refreshedUser = auth.currentUser;

    if (!mounted) return;
    setState(() {
      _user = refreshedUser ?? currentUser;
      _profileData = metadata;
    });
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(profileData: _profileData),
      ),
    );

    await _reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final user = _user ?? Supabase.instance.client.auth.currentUser;

    final userName = (_profileData['name'] as String?)?.trim().isNotEmpty == true
        ? _profileData['name'] as String
        : (user?.email?.split('@').first ?? 'Người dùng');
    final userEmail = user?.email ?? 'Chưa có email';
    final avatarUrl = _profileData['avatar_url'] as String?;
    final bio = _profileData['bio'] as String?;
    final location = _profileData['location'] as String?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(
                    isDark: isDark,
                    userName: userName,
                    userEmail: userEmail,
                    avatarUrl: avatarUrl,
                    bio: bio,
                    location: location,
                    onEdit: _openEditProfile,
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(
                    title: 'Thông tin tài khoản',
                    subtitle: 'Tóm tắt hồ sơ cơ bản của bạn',
                    color: scheme.onSurface,
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Tên hiển thị',
                        value: userName,
                      ),
                      _CardDivider(color: scheme.outline.withValues(alpha: 0.35)),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: userEmail,
                      ),
                      if (bio != null && bio.trim().isNotEmpty) ...[
                        _CardDivider(color: scheme.outline.withValues(alpha: 0.35)),
                        _InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Giới thiệu',
                          value: bio,
                        ),
                      ],
                      if (location != null && location.trim().isNotEmpty) ...[
                        _CardDivider(color: scheme.outline.withValues(alpha: 0.35)),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Địa điểm',
                          value: location,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(
                    title: 'Hành động',
                    subtitle: 'Quản lý hồ sơ và tùy chỉnh thông tin cá nhân',
                    color: scheme.onSurface,
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    children: [
                      _ActionRow(
                        icon: Icons.edit_outlined,
                        label: 'Chỉnh sửa hồ sơ',
                        onTap: _openEditProfile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const HelpFeedbackSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isDark;
  final String userName;
  final String userEmail;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final VoidCallback onEdit;

  const _HeaderCard({
    required this.isDark,
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
    required this.bio,
    required this.location,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF19132F),
                  kAccent.withValues(alpha: 0.82),
                  kAccentPink.withValues(alpha: 0.74),
                ]
              : [
                  kAccent.withValues(alpha: 0.92),
                  kAccentPink.withValues(alpha: 0.82),
                  const Color(0xFFFFF3FB),
                ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROFILE',
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
                _Avatar(userName: userName, avatarUrl: avatarUrl),
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
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 13,
                        ),
                      ),
                      if (bio != null && bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          bio!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (location != null && location!.trim().isNotEmpty) ...[
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
                                location!,
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
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Chỉnh sửa hồ sơ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const _Avatar({
    required this.userName,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [kAccent, kAccentPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _AvatarFallback(userName: userName),
            )
          : _AvatarFallback(userName: userName),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String userName;

  const _AvatarFallback({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withValues(alpha: 0.66),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.24 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  final Color color;

  const _CardDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      color: color,
    );
  }
}