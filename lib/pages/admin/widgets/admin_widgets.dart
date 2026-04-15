import 'package:flutter/material.dart';
import 'package:music_app/pages/admin/admin_theme.dart';

// ── AStatCard ─────────────────────────────────────────────────────────────────
class AStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? width;

  const AStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: kACardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: kAWhite)),
          const SizedBox(height: 3),
          Text(label, style: kALabelStyle),
        ],
      ),
    );
  }
}

// ── AStatusBadge ──────────────────────────────────────────────────────────────
class AStatusBadge extends StatelessWidget {
  final String status;
  const AStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final label = statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── ARoleBadge ────────────────────────────────────────────────────────────────
class ARoleBadge extends StatelessWidget {
  final String role;
  const ARoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (role) {
      'admin' => (kAAccent, Icons.admin_panel_settings_rounded),
      'moderator' => (kAWarning, Icons.shield_rounded),
      _ => (kAMuted, Icons.person_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(role[0].toUpperCase() + role.substring(1),
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── AFilterChips ──────────────────────────────────────────────────────────────
class AFilterChips extends StatelessWidget {
  final List<String> labels;
  final List<int?> counts;
  final int selected;
  final ValueChanged<int> onChanged;

  const AFilterChips({
    super.key,
    required this.labels,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == selected;
          final count = counts.length > i ? counts[i] : null;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? kAAccent.withValues(alpha: 0.15)
                    : kACard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? kAAccent.withValues(alpha: 0.5) : kABorder,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(labels[i],
                    style: TextStyle(
                      color: isActive ? kAAccent : kAWhite70,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    )),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isActive ? kAAccent : kAMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// ── ASectionHeader ────────────────────────────────────────────────────────────
class ASectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const ASectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: kATitleStyle),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

// ── AThumb ────────────────────────────────────────────────────────────────────
class AThumb extends StatelessWidget {
  final String? url;
  final double size;
  const AThumb({super.key, this.url, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url != null
          ? Image.network(url!,
              width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: kACardAlt,
        child: const Icon(Icons.music_note_rounded, color: kAMuted, size: 22),
      );
}

// ── AEmptyState ───────────────────────────────────────────────────────────────
class AEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const AEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kACard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kABorder),
              ),
              child: Icon(icon, color: kAMuted, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: kATitleStyle, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  style: kALabelStyle, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

// ── ALoadingPage ──────────────────────────────────────────────────────────────
class ALoadingPage extends StatelessWidget {
  const ALoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: kAAccent, strokeWidth: 2),
    );
  }
}

// ── AErrorPage ────────────────────────────────────────────────────────────────
class AErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AErrorPage({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: kADanger, size: 48),
            const SizedBox(height: 12),
            Text(message, style: kABodyStyle, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── fmt ───────────────────────────────────────────────────────────────────────
String fmtNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String timeAgo(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inDays > 0) return '${d.inDays}d trước';
  if (d.inHours > 0) return '${d.inHours}h trước';
  if (d.inMinutes > 0) return '${d.inMinutes}m trước';
  return 'Vừa xong';
}
