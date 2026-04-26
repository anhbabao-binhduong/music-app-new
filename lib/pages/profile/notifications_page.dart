import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../presentation/bloc/notification/notification_cubit.dart';
import '../../presentation/bloc/notification/notification_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationCubit()..loadNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final muted = scheme.onSurface.withValues(alpha: 0.68);
    final soft = scheme.onSurface.withValues(alpha: 0.45);
    final border = scheme.outline.withValues(alpha: isDark ? 0.35 : 0.5);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Thông báo',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: kAccent),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () {
              context.read<NotificationCubit>().markAllAsRead();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: kAccent),
                );
              } else if (state is NotificationError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              } else if (state is NotificationLoaded) {
                final notifications = state.notifications;

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_off_rounded,
                            size: 64,
                            color: soft,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bạn không có thông báo nào',
                          style: TextStyle(
                            color: muted,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    color: border,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif.isRead;

                    IconData iconData = Icons.notifications_rounded;
                    Color iconColor = kAccent;
                    if (notif.type == 'song_approved') {
                      iconData = Icons.check_circle_rounded;
                      iconColor = Colors.green;
                    } else if (notif.type == 'song_rejected') {
                      iconData = Icons.cancel_rounded;
                      iconColor = Colors.redAccent;
                    }

                    final timeString =
                        DateFormat('dd/MM/yyyy HH:mm').format(notif.createdAt);

                    return Container(
                      decoration: BoxDecoration(
                        color: isRead
                            ? scheme.surface
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: isDark ? 0.42 : 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRead
                              ? border.withValues(alpha: 0.65)
                              : kAccent.withValues(alpha: 0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.18 : 0.05,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (!isRead) {
                              context
                                  .read<NotificationCubit>()
                                  .markAsRead(notif.id);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontSize: 15,
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.body,
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 13,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          color: soft,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: kAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}