import 'package:flutter/material.dart';

class AdminNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int? badge;
  final bool locked;
  final String? lockReason;
  final VoidCallback onTap;

  const AdminNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    this.locked = false,
    this.lockReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: locked
            ? () => _showLockSnack(context)
            : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: locked
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  locked ? Icons.lock_rounded : icon,
                  color: locked ? Colors.white38 : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: locked ? Colors.white38 : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      locked ? (lockReason ?? 'Yêu cầu quyền Admin') : subtitle,
                      style: TextStyle(
                        color: locked ? Colors.white24 : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge or lock/arrow
              if (badge != null && badge! > 0 && !locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge! > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: locked ? Colors.white.withValues(alpha: 0.12) : Colors.white24,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lockReason ?? 'Chức năng này yêu cầu quyền Admin'),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
