import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/hive_constants.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Box<dynamic> _settingsBox;
  bool _notificationsEnabled = true;
  bool _resumePlayback = true;
  bool _downloadOnWifiOnly = true;
  String _streamQuality = 'Tự động';

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    _notificationsEnabled = _settingsBox.get(
      HiveSettingsKeys.notificationsEnabled,
      defaultValue: true,
    ) as bool;
    _resumePlayback = _settingsBox.get(
      HiveSettingsKeys.resumePlayback,
      defaultValue: true,
    ) as bool;
    _downloadOnWifiOnly = _settingsBox.get(
      HiveSettingsKeys.downloadOnWifiOnly,
      defaultValue: true,
    ) as bool;
    _streamQuality = _settingsBox.get(
      HiveSettingsKeys.streamQuality,
      defaultValue: 'Tự động',
    ) as String;
  }

  Future<void> _saveBool(String key, bool value) async {
    await _settingsBox.put(key, value);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveString(String key, String value) async {
    await _settingsBox.put(key, value);
    if (!mounted) return;
    setState(() {});
  }

  String _themeModeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => 'Sáng',
      AppThemeMode.dark => 'Tối',
      AppThemeMode.system => 'Theo hệ thống',
    };
  }

  IconData _themeModeIcon(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => Icons.light_mode_rounded,
      AppThemeMode.dark => Icons.dark_mode_rounded,
      AppThemeMode.system => Icons.phone_android_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            title: Text(
              'Cài đặt',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsHeroCard(
                        themeModeLabel: _themeModeLabel(themeState.mode),
                        notificationsEnabled: _notificationsEnabled,
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Giao diện',
                        icon: Icons.palette_outlined,
                        iconColor: kAccent,
                        children: [
                          _ThemeModeTile(
                            currentMode: themeState.mode,
                            currentLabel: _themeModeLabel(themeState.mode),
                            currentIcon: _themeModeIcon(themeState.mode),
                            onSelected: (mode) {
                              context.read<ThemeBloc>().add(SetThemeModeEvent(mode));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Trải nghiệm nghe',
                        icon: Icons.graphic_eq_rounded,
                        iconColor: Colors.orangeAccent,
                        children: [
                          _SettingsSwitchTile(
                            icon: Icons.play_circle_outline_rounded,
                            title: 'Tiếp tục bài đang nghe',
                            subtitle: 'Tự khôi phục bài hát và vị trí nghe gần nhất khi mở lại ứng dụng.',
                            value: _resumePlayback,
                            onChanged: (value) async {
                              setState(() => _resumePlayback = value);
                              await _saveBool(HiveSettingsKeys.resumePlayback, value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _SettingsSelectionTile(
                            icon: Icons.high_quality_rounded,
                            title: 'Chất lượng phát nhạc',
                            subtitle: 'Áp dụng làm cấu hình mặc định cho các phiên nghe mới.',
                            value: _streamQuality,
                            onTap: () async {
                              final selected = await showModalBottomSheet<String>(
                                context: context,
                                backgroundColor: const Color(0xFF1B1B1F),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (context) => _QualitySheet(currentValue: _streamQuality),
                              );

                              if (selected != null) {
                                setState(() => _streamQuality = selected);
                                await _saveString(HiveSettingsKeys.streamQuality, selected);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Thông báo & tải xuống',
                        icon: Icons.tune_rounded,
                        iconColor: Colors.cyanAccent,
                        children: [
                          _SettingsSwitchTile(
                            icon: Icons.notifications_outlined,
                            title: 'Nhận thông báo',
                            subtitle: 'Thông báo về bài mới, playlist nổi bật và hoạt động quan trọng.',
                            value: _notificationsEnabled,
                            onChanged: (value) async {
                              setState(() => _notificationsEnabled = value);
                              await _saveBool(HiveSettingsKeys.notificationsEnabled, value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _SettingsSwitchTile(
                            icon: Icons.wifi_rounded,
                            title: 'Chỉ tải xuống bằng Wi‑Fi',
                            subtitle: 'Giảm tiêu tốn dữ liệu di động khi tải bài hát hoặc ảnh bìa.',
                            value: _downloadOnWifiOnly,
                            onChanged: (value) async {
                              setState(() => _downloadOnWifiOnly = value);
                              await _saveBool(HiveSettingsKeys.downloadOnWifiOnly, value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _SectionCard(
                        title: 'Về ứng dụng',
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.white70,
                        children: [
                          _StaticInfoTile(
                            icon: Icons.shield_moon_outlined,
                            title: 'Quyền riêng tư',
                            subtitle: 'Các tuỳ chọn được lưu cục bộ trên thiết bị của bạn.',
                          ),
                          SizedBox(height: 12),
                          _StaticInfoTile(
                            icon: Icons.rocket_launch_outlined,
                            title: 'Trạng thái',
                            subtitle: 'Thiết lập đã sẵn sàng cho trải nghiệm nghe nhạc cá nhân hoá hơn.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  final String themeModeLabel;
  final bool notificationsEnabled;

  const _SettingsHeroCard({
    required this.themeModeLabel,
    required this.notificationsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            kAccent.withValues(alpha: 0.25),
            kAccentPink.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.settings_suggest_rounded, color: onSurface, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết lập cá nhân',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tuỳ chỉnh giao diện và trải nghiệm nghe nhạc theo thói quen của bạn.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onSurface.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                icon: Icons.dark_mode_rounded,
                label: 'Giao diện: $themeModeLabel',
              ),
              _HeroChip(
                icon: notificationsEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                label: notificationsEnabled ? 'Thông báo đang bật' : 'Thông báo đang tắt',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onSurface, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final AppThemeMode currentMode;
  final String currentLabel;
  final IconData currentIcon;
  final ValueChanged<AppThemeMode> onSelected;

  const _ThemeModeTile({
    required this.currentMode,
    required this.currentLabel,
    required this.currentIcon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsSelectionTile(
      icon: currentIcon,
      title: 'Chế độ giao diện',
      subtitle: 'Chuyển nhanh giữa sáng, tối hoặc theo hệ thống.',
      value: currentLabel,
      onTap: () async {
        final selected = await showModalBottomSheet<AppThemeMode>(
          context: context,
          backgroundColor: const Color(0xFF1B1B1F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => _ThemeModeSheet(currentMode: currentMode),
        );

        if (selected != null) {
          onSelected(selected);
        }
      },
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: kAccent,
        inactiveThumbColor: Colors.white70,
        inactiveTrackColor: onSurface.withValues(alpha: 0.24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: onSurface.withValues(alpha: 0.7), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.6),
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSelectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  const _SettingsSelectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: onSurface.withValues(alpha: 0.7), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.6),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StaticInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    height: 1.45,
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

class _ThemeModeSheet extends StatelessWidget {
  final AppThemeMode currentMode;

  const _ThemeModeSheet({
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final options = <(AppThemeMode, String, IconData)>[
      (AppThemeMode.system, 'Theo hệ thống', Icons.phone_android_rounded),
      (AppThemeMode.dark, 'Tối', Icons.dark_mode_rounded),
      (AppThemeMode.light, 'Sáng', Icons.light_mode_rounded),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chọn giao diện',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BottomSheetOptionTile(
                  icon: option.$3,
                  title: option.$2,
                  selected: currentMode == option.$1,
                  onTap: () => Navigator.pop(context, option.$1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualitySheet extends StatelessWidget {
  final String currentValue;

  const _QualitySheet({
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    const options = ['Tự động', 'Tiết kiệm dữ liệu', 'Cân bằng', 'Chất lượng cao'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chất lượng phát nhạc',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BottomSheetOptionTile(
                  icon: Icons.graphic_eq_rounded,
                  title: option,
                  selected: currentValue == option,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _BottomSheetOptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? kAccent.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? kAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? kAccent : Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: kAccent),
            ],
          ),
        ),
      ),
    );
  }
}