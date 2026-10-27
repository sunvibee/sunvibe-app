import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

enum NotificationFilter { all, unread, read }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  NotificationFilter _selectedFilter = NotificationFilter.all;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _notificationService.init();
  }

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  List<NotificationItem> _getFilteredNotifications(
    List<NotificationItem> allNotifications,
  ) {
    switch (_selectedFilter) {
      case NotificationFilter.all:
        return allNotifications;
      case NotificationFilter.unread:
        return allNotifications.where((n) => !n.isRead).toList();
      case NotificationFilter.read:
        return allNotifications.where((n) => n.isRead).toList();
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 45) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return "$mins ${mins == 1 ? 'min' : 'mins'} ago";
    } else if (difference.inHours < 24 && now.day == dateTime.day) {
      final hours = difference.inHours;
      return "$hours ${hours == 1 ? 'hour' : 'hours'} ago";
    } else if (difference.inDays == 1 || (now.day - dateTime.day == 1 && difference.inHours < 48)) {
      return "Yesterday at ${DateFormat('h:mm a').format(dateTime)}";
    } else if (difference.inDays < 7) {
      return "${DateFormat('EEEE').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}";
    } else {
      return DateFormat('MMM d, y • h:mm a').format(dateTime);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _confirmDeleteSelected() {
    if (_selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${_selectedIds.length} Notification(s)'),
        content: const Text(
          'Are you sure you want to delete the selected notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final idsToDelete = _selectedIds.toList();
              Navigator.pop(dialogCtx);
              await _notificationService.removeMultiple(idsToDelete);
              if (mounted) {
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selected notifications deleted'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _notificationService.clearAllNotifications();
              if (mounted) {
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 28).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _notificationService,
          builder: (context, _) {
            final allNotifications = _notificationService.notifications;
            final unreadCount = _notificationService.unreadCount;
            final readCount = _notificationService.readCount;
            final totalCount = _notificationService.totalCount;

            final filteredList = _getFilteredNotifications(allNotifications);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(scale, totalCount, unreadCount),
                if (!_isSelectionMode)
                  _buildFilterChips(scale, totalCount, unreadCount, readCount),
                SizedBox(height: 8 * scale),
                Expanded(
                  child: filteredList.isNotEmpty
                      ? ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            6 * scale,
                            horizontalPadding,
                            20 * scale,
                          ),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: 10 * scale),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final isSelected = _selectedIds.contains(item.id);

                            return _buildNotificationCard(
                              scale: scale,
                              item: item,
                              isSelected: isSelected,
                            );
                          },
                        )
                      : _buildEmptyState(scale),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  //---------------- Top Navigation Bar ----------------
  Widget _buildTopBar(double scale, int totalCount, int unreadCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        12 * scale,
        16 * scale,
        8 * scale,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (_isSelectionMode) {
                  _exitSelectionMode();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: Padding(
                padding: EdgeInsets.all(10 * scale),
                child: Icon(
                  _isSelectionMode ? Icons.close : Icons.arrow_back_ios_new,
                  size: 18 * scale,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSelectionMode
                      ? "${_selectedIds.length} Selected"
                      : "Notifications",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (!_isSelectionMode)
                  Text(
                    unreadCount > 0
                        ? "$unreadCount unread ${unreadCount == 1 ? 'alert' : 'alerts'}"
                        : "All caught up",
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: unreadCount > 0
                          ? AppColors.orange
                          : Colors.grey.shade600,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          if (!_isSelectionMode) ...[
            if (unreadCount > 0)
              IconButton(
                tooltip: "Mark all as read",
                icon: Icon(
                  Icons.done_all_rounded,
                  color: AppColors.orange,
                  size: 22 * scale,
                ),
                onPressed: _markAllAsRead,
              ),
            if (totalCount > 0)
              IconButton(
                tooltip: "Clear all",
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.grey.shade700,
                  size: 22 * scale,
                ),
                onPressed: _confirmClearAll,
              ),
          ],
          if (_isSelectionMode)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 8 * scale,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedIds.isNotEmpty ? _confirmDeleteSelected : null,
              icon: Icon(Icons.delete_outline, size: 18 * scale),
              label: Text("Delete (${_selectedIds.length})"),
            ),
        ],
      ),
    );
  }

  //---------------- Filter Chips Bar ----------------
  Widget _buildFilterChips(
    double scale,
    int totalCount,
    int unreadCount,
    int readCount,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 8 * scale,
      ),
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _filterTab(
              scale: scale,
              filter: NotificationFilter.all,
              label: "All",
              count: totalCount,
            ),
          ),
          SizedBox(width: 4 * scale),
          Expanded(
            child: _filterTab(
              scale: scale,
              filter: NotificationFilter.unread,
              label: "Unread",
              count: unreadCount,
              highlightBadge: unreadCount > 0,
            ),
          ),
          SizedBox(width: 4 * scale),
          Expanded(
            child: _filterTab(
              scale: scale,
              filter: NotificationFilter.read,
              label: "Read",
              count: readCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab({
    required double scale,
    required NotificationFilter filter,
    required String label,
    required int count,
    bool highlightBadge = false,
  }) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      borderRadius: BorderRadius.circular(12 * scale),
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 8 * scale),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            SizedBox(width: 6 * scale),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6 * scale,
                vertical: 2 * scale,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (highlightBadge
                        ? AppColors.orange.withValues(alpha: 0.15)
                        : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (highlightBadge
                          ? AppColors.orange
                          : Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //---------------- Notification Card ----------------
  Widget _buildNotificationCard({
    required double scale,
    required NotificationItem item,
    required bool isSelected,
  }) {
    final color = _getNotificationColor(item.type, title: item.title);
    final icon = _getNotificationIcon(item.type, item.title);
    final isUnread = !item.isRead;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20 * scale),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(18 * scale),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14 * scale,
              ),
            ),
            SizedBox(width: 8 * scale),
            const Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) {
        _notificationService.removeNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${item.title}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.orange,
              onPressed: () {
                _notificationService.addNotification(
                  title: item.title,
                  message: item.message,
                  type: item.type,
                  robotId: item.robotId,
                  showSystemNotification: false,
                );
              },
            ),
          ),
        );
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * scale),
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode(item.id);
          }
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(item.id);
          } else {
            _notificationService.toggleReadStatus(item.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(14 * scale),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.blue.withValues(alpha: 0.08)
                : (isUnread ? Colors.white : const Color(0xFFFAFAFC)),
            borderRadius: BorderRadius.circular(18 * scale),
            border: Border.all(
              color: isSelected
                  ? AppColors.blue
                  : (isUnread
                      ? AppColors.orange.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.16)),
              width: isSelected ? 2 : (isUnread ? 1.5 : 1),
            ),
            boxShadow: [
              BoxShadow(
                color: isUnread
                    ? color.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isUnread ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: EdgeInsets.only(right: 12 * scale, top: 10 * scale),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.blue : Colors.grey.shade400,
                    size: 22 * scale,
                  ),
                ),
              // Icon Badge
              Container(
                width: 44 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14 * scale),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 24 * scale,
                  ),
                ),
              ),
              SizedBox(width: 12 * scale),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15 * scale,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isUnread
                                  ? Colors.black87
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          SizedBox(width: 6 * scale),
                          Container(
                            width: 8 * scale,
                            height: 8 * scale,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: isUnread
                            ? Colors.black87
                            : Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13 * scale,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(width: 4 * scale),
                        Text(
                          _formatRelativeTime(item.timestamp),
                          style: TextStyle(
                            fontSize: 11 * scale,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * scale,
                            vertical: 3 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? AppColors.orange.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6 * scale),
                          ),
                          child: Text(
                            isUnread ? "UNREAD" : "READ",
                            style: TextStyle(
                              fontSize: 9.5 * scale,
                              fontWeight: FontWeight.bold,
                              color: isUnread
                                  ? AppColors.orange
                                  : Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //---------------- Empty State ----------------
  Widget _buildEmptyState(double scale) {
    String title;
    String subtitle;
    IconData iconData;

    switch (_selectedFilter) {
      case NotificationFilter.all:
        title = "No Notifications Yet";
        subtitle =
            "Real-time notifications for robot start, stop, and status updates will appear here.";
        iconData = Icons.notifications_none_rounded;
        break;
      case NotificationFilter.unread:
        title = "All Caught Up!";
        subtitle = "You have no unread notifications.";
        iconData = Icons.mark_email_read_outlined;
        break;
      case NotificationFilter.read:
        title = "No Read Notifications";
        subtitle = "Notifications you've marked as read will show up here.";
        iconData = Icons.done_all_rounded;
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 32 * scale,
          vertical: 40 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100 * scale,
              height: 100 * scale,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 52 * scale,
                color: AppColors.orange,
              ),
            ),
            SizedBox(height: 20 * scale),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * scale,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            if (_selectedFilter != NotificationFilter.all) ...[
              SizedBox(height: 20 * scale),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orange,
                  side: const BorderSide(color: AppColors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _selectedFilter = NotificationFilter.all;
                  });
                },
                child: const Text("View All Notifications"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type, {String? title}) {
    if (title != null) {
      final lower = title.toLowerCase();
      if (lower.contains('run time') || lower.contains('runtime') || lower.contains('clock')) {
        return const Color(0xFF1E40AF); // Sleek deep royal blue for runtime
      }
    }
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

  IconData _getNotificationIcon(NotificationType type, String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('run time') ||
        lowerTitle.contains('runtime') ||
        lowerTitle.contains('clock') ||
        lowerTitle.contains('stopwatch')) {
      return Icons.timer_outlined;
    } else if (lowerTitle.contains('start') || lowerTitle.contains('run')) {
      return Icons.play_arrow_rounded;
    } else if (lowerTitle.contains('stop') || lowerTitle.contains('halt')) {
      return Icons.stop_rounded;
    } else if (lowerTitle.contains('offline') || lowerTitle.contains('disconnect')) {
      return Icons.wifi_off_rounded;
    }

    switch (type) {
      case NotificationType.info:
        return Icons.smart_toy_outlined;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
    }
  }
}
