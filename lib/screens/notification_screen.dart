import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> notifications = [];
  bool isSelectionMode = false;
  List<int> selectedIndices = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      notifications = NotificationService().notifications;
    });
  }

  String _formatDate(DateTime date) {
    final month = _getMonthName(date.month);
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour:$minute $amPm';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await NotificationService().clearAllNotifications();
              setState(() {
                notifications = [];
                selectedIndices.clear();
                isSelectionMode = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedNotifications() {
    if (selectedIndices.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete ${selectedIndices.length} Notification(s)'),
        content: const Text(
          'Are you sure you want to delete these notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              setState(() {
                final sortedIndices = selectedIndices.toList()
                  ..sort((a, b) => b.compareTo(a));
                for (var index in sortedIndices) {
                  NotificationService().removeNotificationSync(index);
                  notifications.removeAt(index);
                }
                selectedIndices.clear();
                isSelectionMode = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected notifications deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
      if (selectedIndices.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode() {
    setState(() {
      isSelectionMode = true;
      selectedIndices.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedIndices.clear();
    });
  }

  void _markAllAsRead() async {
    await NotificationService().markAllAsRead();
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAsRead(int index) async {
    await NotificationService().markAsRead(index);
    setState(() {
      notifications[index].isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 30).toDouble();
    final hasNotifications = notifications.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, scale, hasNotifications),
            Expanded(
              child: hasNotifications
                  ? ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isSelected = selectedIndices.contains(index);
                        return _buildNotificationTile(
                          scale: scale,
                          notification: notification,
                          index: index,
                          isSelected: isSelected,
                        );
                      },
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(child: _buildEmptyState(scale)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  Widget _buildTopBar(
    BuildContext context,
    double scale,
    bool hasNotifications,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 10 * scale,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (isSelectionMode) {
                  _exitSelectionMode();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: Padding(
                padding: EdgeInsets.all(8 * scale),
                child: Icon(
                  isSelectionMode ? Icons.close : Icons.arrow_back_ios_new,
                  size: 18 * scale,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              isSelectionMode
                  ? '${selectedIndices.length} Selected'
                  : 'Notifications',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (!isSelectionMode && hasNotifications)
            Row(
              children: [
                _topActionButton(
                  context,
                  scale,
                  Icons.check_circle_outline,
                  'Mark All Read',
                  _markAllAsRead,
                  enabled: hasNotifications,
                ),
                SizedBox(width: 8 * scale),
                _topActionButton(
                  context,
                  scale,
                  Icons.delete_sweep_outlined,
                  'Clear All',
                  _clearAllNotifications,
                  enabled: hasNotifications,
                ),
              ],
            ),
          if (isSelectionMode)
            Row(
              children: [
                _topActionButton(
                  context,
                  scale,
                  Icons.delete_outline,
                  'Delete',
                  _deleteSelectedNotifications,
                  enabled: selectedIndices.isNotEmpty,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _topActionButton(
    BuildContext context,
    double scale,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16 * scale, color: Colors.grey.shade700),
              SizedBox(width: 4 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required double scale,
    required NotificationItem notification,
    required int index,
    required bool isSelected,
  }) {
    final isRead = notification.isRead;
    final color = _getNotificationColor(notification.type);

    return GestureDetector(
      onLongPress: () {
        if (!isSelectionMode) {
          _enterSelectionMode();
          _toggleSelection(index);
        }
      },
      onTap: () {
        if (isSelectionMode) {
          _toggleSelection(index);
        } else {
          _markAsRead(index);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10 * scale),
        padding: EdgeInsets.all(14 * scale),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelectionMode)
              Padding(
                padding: EdgeInsets.only(right: 10 * scale),
                child: Container(
                  width: 20 * scale,
                  height: 20 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.blue : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.blue : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 14 * scale, color: Colors.white)
                      : null,
                ),
              ),
            Container(
              width: 40 * scale,
              height: 40 * scale,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: color,
                size: 20 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: isRead ? Colors.grey.shade600 : Colors.black,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8 * scale,
                          height: 8 * scale,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12.5 * scale,
                      color: isRead
                          ? Colors.grey.shade500
                          : Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    _formatDate(notification.timestamp),
                    style: TextStyle(
                      fontSize: 10 * scale,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bellIllustration(scale),
          SizedBox(height: 28 * scale),
          Text(
            "No Notifications",
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            "You're all caught up!",
            style: TextStyle(fontSize: 15 * scale, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _bellIllustration(double scale) {
    final size = 190 * scale;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.orange.withOpacity(.14),
                  AppColors.orange.withOpacity(.02),
                ],
              ),
            ),
          ),
          Positioned(
            top: size * 0.14,
            left: size * 0.12,
            child: Icon(
              Icons.add,
              size: 12 * scale,
              color: AppColors.orange.withOpacity(.35),
            ),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.14,
            child: Icon(
              Icons.add,
              size: 10 * scale,
              color: AppColors.orange.withOpacity(.3),
            ),
          ),
          Positioned(
            bottom: size * 0.18,
            left: size * 0.16,
            child: Icon(
              Icons.circle,
              size: 5 * scale,
              color: AppColors.orange.withOpacity(.3),
            ),
          ),
          Positioned(
            bottom: size * 0.20,
            right: size * 0.12,
            child: Icon(
              Icons.circle,
              size: 5 * scale,
              color: AppColors.orange.withOpacity(.3),
            ),
          ),
          Icon(
            Icons.notifications_none_rounded,
            size: size * 0.42,
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return AppColors.blue;
      case NotificationType.warning:
        return AppColors.orange;
      case NotificationType.error:
        return AppColors.red;
      case NotificationType.success:
        return AppColors.green;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
    }
  }
}
