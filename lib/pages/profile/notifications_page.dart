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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Thông báo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
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
                return const Center(child: CircularProgressIndicator(color: kAccent));
              } else if (state is NotificationError) {
                return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
              } else if (state is NotificationLoaded) {
                final notifications = state.notifications;

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('Bạn không có thông báo nào', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif.isRead;
                    
                    // Determine icon based on type
                    IconData iconData = Icons.notifications_rounded;
                    Color iconColor = kAccent;
                    if (notif.type == 'song_approved') {
                      iconData = Icons.check_circle_rounded;
                      iconColor = Colors.greenAccent;
                    } else if (notif.type == 'song_rejected') {
                      iconData = Icons.cancel_rounded;
                      iconColor = Colors.redAccent;
                    }

                    // Format timestamp using intl
                    final timeString = DateFormat('dd/MM/yyyy HH:mm').format(notif.createdAt);

                    return Material(
                      color: isRead ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
                      child: InkWell(
                        onTap: () {
                          if (!isRead) {
                            context.read<NotificationCubit>().markAsRead(notif.id);
                          }
                          // Thêm logic chuyển hướng dựa trên type nếu cần
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData, color: iconColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.body,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timeString,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        fontSize: 11,
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
