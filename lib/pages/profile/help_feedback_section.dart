import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import 'help_detail_page.dart';

/// Self-contained "Trợ giúp & phản hồi" section for the profile page.
class HelpFeedbackSection extends StatelessWidget {
  const HelpFeedbackSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HelpSectionLabel(scheme: scheme),
        const SizedBox(height: 14),
        _HelpBannerCard(isDark: isDark),
        const SizedBox(height: 14),
        _HelpItemsCard(scheme: scheme),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _HelpSectionLabel extends StatelessWidget {
  final ColorScheme scheme;

  const _HelpSectionLabel({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trợ giúp & phản hồi',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Câu hỏi, đóng góp và các chính sách',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.66),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glassmorphism banner card ─────────────────────────────────────────────────

class _HelpBannerCard extends StatelessWidget {
  final bool isDark;

  const _HelpBannerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kAccentPink.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background orbs
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAccentPink.withValues(alpha: 0.3),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAccent.withValues(alpha: 0.3),
                ),
              ),
            ),

            // Glassmorphism foreground
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HelpPages.feedback()),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.03),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.3),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Gradient icon container
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kAccent, kAccentPink],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kAccentPink.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Text block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cần hỗ trợ trực tiếp?',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đội ngũ của chúng tôi luôn sẵn sàng giúp đỡ bạn 24/7',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Arrow button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: isDark ? Colors.white : kAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Items card ────────────────────────────────────────────────────────────────

class _HelpItemsCard extends StatelessWidget {
  final ColorScheme scheme;

  const _HelpItemsCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = scheme.outline.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.42)),
          ),
          child: Column(
            children: [
              _HelpActionRow(
                icon: Icons.help_outline_rounded,
                label: 'Câu hỏi thường gặp',
                subtitle: 'Giải đáp các thắc mắc phổ biến',
                iconColor: kAccent,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HelpPages.faq()),
                ),
              ),
              _HelpDivider(color: dividerColor),
              _HelpActionRow(
                icon: Icons.rate_review_outlined,
                label: 'Gửi phản hồi',
                subtitle: 'Chia sẻ ý kiến và trải nghiệm của bạn',
                iconColor: const Color(0xFF06B6D4),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HelpPages.feedback()),
                ),
              ),
              _HelpDivider(color: dividerColor),
              _HelpActionRow(
                icon: Icons.bug_report_outlined,
                label: 'Báo cáo sự cố',
                subtitle: 'Thông báo lỗi bạn gặp phải trên ứng dụng',
                iconColor: const Color(0xFFF59E0B),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HelpPages.bugReport()),
                ),
              ),
              _HelpDivider(color: dividerColor),
              _HelpActionRow(
                icon: Icons.shield_outlined,
                label: 'Chính sách & Quyền riêng tư',
                subtitle: 'Quy định và chính sách sử dụng dịch vụ',
                iconColor: const Color(0xFF10B981),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HelpPages.privacyPolicy()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single action row ─────────────────────────────────────────────────────────

class _HelpActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _HelpActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _HelpDivider extends StatelessWidget {
  final Color color;

  const _HelpDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, indent: 74, color: color);
  }
}