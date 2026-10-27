import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/robot_timer_service.dart';
import '../models/cleaning_session_model.dart';

class CleaningHistoryScreen extends StatefulWidget {
  const CleaningHistoryScreen({super.key});

  @override
  State<CleaningHistoryScreen> createState() => _CleaningHistoryScreenState();
}

class _CleaningHistoryScreenState extends State<CleaningHistoryScreen> {
  final RobotTimerService _timerService = RobotTimerService();

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.25);
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all cleaning history records? This cannot be undone.',
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
              await _timerService.clearHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cleaning history cleared'),
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

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 28).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _timerService,
          builder: (context, _) {
            final history = _timerService.history;
            final totalCount = _timerService.totalSessions;
            final totalTimeStr = _timerService.formattedTotalCleanTime;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(scale, totalCount),
                if (history.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _buildSummaryCard(scale, totalCount, totalTimeStr),
                  ),
                  SizedBox(height: 16 * scale),
                ],
                Expanded(
                  child: history.isNotEmpty
                      ? ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            6 * scale,
                            horizontalPadding,
                            24 * scale,
                          ),
                          itemCount: history.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: 12 * scale),
                          itemBuilder: (context, index) {
                            final session = history[index];
                            return _buildSessionCard(scale, session);
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
  Widget _buildTopBar(double scale, int totalCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        12 * scale,
        16 * scale,
        10 * scale,
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
              onTap: () => Navigator.of(context).maybePop(),
              child: Padding(
                padding: EdgeInsets.all(10 * scale),
                child: Icon(
                  Icons.arrow_back_ios_new,
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
                  "Cleaning History",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  totalCount > 0
                      ? "$totalCount recorded ${totalCount == 1 ? 'session' : 'sessions'}"
                      : "No past sessions",
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            IconButton(
              tooltip: "Clear All History",
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: Colors.grey.shade700,
                size: 22 * scale,
              ),
              onPressed: _confirmClearAll,
            ),
        ],
      ),
    );
  }

  //---------------- Summary Stats Card ----------------
  Widget _buildSummaryCard(double scale, int count, String totalTime) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.navy.withValues(alpha: 0.90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: AppColors.orange,
                      size: 18 * scale,
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      "TOTAL RUN TIME",
                      style: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * scale),
                Text(
                  totalTime,
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36 * scale,
            width: 1,
            color: Colors.white.withValues(alpha: 0.2),
            margin: EdgeInsets.symmetric(horizontal: 14 * scale),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SESSIONS",
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w900,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //---------------- Session Item Card ----------------
  Widget _buildSessionCard(double scale, CleaningSession session) {
    return Dismissible(
      key: Key(session.id),
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
        _timerService.deleteSession(session.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted session (${session.formattedDuration})'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(14 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Badge
            Container(
              width: 44 * scale,
              height: 44 * scale,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14 * scale),
              ),
              child: Center(
                child: Icon(
                  Icons.timer_outlined,
                  color: AppColors.orange,
                  size: 24 * scale,
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        session.formattedDuration,
                        style: TextStyle(
                          fontSize: 17 * scale,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: AppColors.navy,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale,
                          vertical: 3 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6 * scale),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          session.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5 * scale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5 * scale),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13 * scale,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(width: 4 * scale),
                      Text(
                        session.formattedTimeRange,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        session.formattedDate,
                        style: TextStyle(
                          fontSize: 11.5 * scale,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
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
    );
  }

  //---------------- Empty State ----------------
  Widget _buildEmptyState(double scale) {
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
              width: 90 * scale,
              height: 90 * scale,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 46 * scale,
                color: AppColors.orange,
              ),
            ),
            SizedBox(height: 18 * scale),
            Text(
              "No Cleaning History Yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              "When you tap 'Start Cleaning' on the home screen and later stop it, the robot's cleaning run time and AM/PM timeline will be recorded here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5 * scale,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
