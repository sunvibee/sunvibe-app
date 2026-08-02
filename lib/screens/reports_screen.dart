import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedTimeFilter = "Today";
  String selectedExportFormat = "PDF";

  final double totalEnergy = 0;
  final double totalRuntime = 0;
  final int totalAlerts = 0;
  final double overallEfficiency = 0;

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 30).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18 * scale,
            horizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(scale),
              SizedBox(height: 22 * scale),
              _buildSectionTitleWithLiveBadge(scale),
              SizedBox(height: 14 * scale),
              _buildStatsGrid(scale),
              SizedBox(height: 22 * scale),
              _buildTimeFilterTitle(scale),
              SizedBox(height: 12 * scale),
              _buildTimeFilterRow(scale),
              SizedBox(height: 18 * scale),
              _buildEmptyState(scale),
              SizedBox(height: 22 * scale),
              _buildExportSection(scale),
              SizedBox(height: 20 * scale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reports",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 3 * scale),
              Text(
                "Analytics & Performance Overview",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8 * scale),
        _headerIconButton(
          scale,
          Icons.file_download_outlined,
          onTap: () => _showFeedback("Download reports", AppColors.blue),
        ),
      ],
    );
  }

  Widget _headerIconButton(
    double scale,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10 * scale),
          child: Icon(icon, size: 20 * scale, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildSectionTitleWithLiveBadge(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Report Overview",
          style: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 5 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Live Data",
                style: TextStyle(
                  fontSize: 11.5 * scale,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 5 * scale),
              Container(
                width: 7 * scale,
                height: 7 * scale,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(double scale) {
    final stats = [
      _ReportStatData(
        icon: Icons.bolt,
        iconBg: const Color(0xFFDCEAFB),
        iconColor: const Color(0xFF1D6FF2),
        label: "Total Energy\nGenerated",
        value: "${totalEnergy.toStringAsFixed(0)} kWh",
        valueColor: const Color(0xFF1D6FF2),
        sparkColor: const Color(0xFF1D6FF2),
      ),
      _ReportStatData(
        icon: Icons.access_time,
        iconBg: const Color(0xFFDCF5E4),
        iconColor: AppColors.green,
        label: "Total Runtime",
        value: "${totalRuntime.toStringAsFixed(0)} hr",
        valueColor: AppColors.green,
        sparkColor: AppColors.green,
      ),
      _ReportStatData(
        icon: Icons.notifications_none,
        iconBg: const Color(0xFFFBEACB),
        iconColor: AppColors.orange,
        label: "Total Alerts",
        value: "$totalAlerts",
        valueColor: AppColors.orange,
        sparkColor: AppColors.orange,
      ),
      _ReportStatData(
        icon: Icons.speed,
        iconBg: const Color(0xFFDCEAFB),
        iconColor: const Color(0xFF1D6FF2),
        label: "Overall System\nEfficiency",
        value: "${overallEfficiency.toStringAsFixed(0)}%",
        valueColor: const Color(0xFF1D6FF2),
        sparkColor: const Color(0xFF1D6FF2),
      ),
    ];

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _statCard(scale, stats[0])),
              SizedBox(width: 12 * scale),
              Expanded(child: _statCard(scale, stats[1])),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _statCard(scale, stats[2])),
              SizedBox(width: 12 * scale),
              Expanded(child: _statCard(scale, stats[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(double scale, _ReportStatData data) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16 * scale,
                backgroundColor: data.iconBg,
                child: Icon(data.icon, color: data.iconColor, size: 16 * scale),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5 * scale,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 20 * scale,
              fontWeight: FontWeight.bold,
              color: data.valueColor,
            ),
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 28 * scale,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(color: data.sparkColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterTitle(double scale) {
    return Text(
      "Time Filter",
      style: TextStyle(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTimeFilterRow(double scale) {
    final options = ["Today", "Weekly", "Monthly", "Custom Range"];

    return Container(
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: options.map((option) {
              final isSelected = option == selectedTimeFilter;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTimeFilter = option;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 10 * scale),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 30 * scale,
        horizontal: 20 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _decorativeReportIllustration(scale),
          SizedBox(height: 20 * scale),
          Text(
            "No reports available yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            "Generate your first report to see insights\nand performance data here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13 * scale,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20 * scale),
          _generateReportButton(scale),
        ],
      ),
    );
  }

  Widget _decorativeReportIllustration(double scale) {
    final size = 130 * scale;
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue.withValues(alpha: .08),
            ),
          ),
          Icon(
            Icons.assignment_outlined,
            size: size * 0.5,
            color: AppColors.blue.withValues(alpha: .35),
          ),
          Positioned(
            bottom: size * 0.12,
            right: size * 0.1,
            child: Icon(
              Icons.search,
              size: size * 0.32,
              color: AppColors.blue.withValues(alpha: .6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generateReportButton(double scale) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 15 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: () => _showFeedback("Generating reportâ€¦", AppColors.blue),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 18 * scale),
            SizedBox(width: 8 * scale),
            Text(
              "Generate Report",
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //---------------- Export Section ----------------
  Widget _buildExportSection(double scale) {
    final exportOptions = [
      _ExportData(
        icon: Icons.picture_as_pdf_outlined,
        iconColor: const Color(0xFFE5484D),
        title: "PDF",
        subtitle: "High quality format",
      ),
      _ExportData(
        icon: Icons.grid_on,
        iconColor: const Color(0xFF1D9A4A),
        title: "Excel",
        subtitle: "Microsoft Excel format",
      ),
      _ExportData(
        icon: Icons.insert_drive_file_outlined,
        iconColor: const Color(0xFF1D6FF2),
        title: "CSV",
        subtitle: "Comma separated values",
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Export Report",
          style: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12 * scale),
        Row(
          children: exportOptions.map((option) {
            final isSelected = selectedExportFormat == option.title;
            return Expanded(
              child: _exportCard(
                scale: scale,
                data: option,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    selectedExportFormat = option.title;
                  });
                  _showFeedback("Exporting as ${option.title}", AppColors.blue);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _exportCard({
    required double scale,
    required _ExportData data,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 10 * scale),
        padding: EdgeInsets.symmetric(
          vertical: 12 * scale,
          horizontal: 6 * scale,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.icon,
              color: isSelected ? AppColors.blue : data.iconColor,
              size: 24 * scale,
            ),
            SizedBox(height: 6 * scale),
            Text(
              data.title,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.blue : Colors.black87,
              ),
            ),
            SizedBox(height: 2 * scale),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10 * scale,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = <Offset>[];
    final segmentCount = 8;
    for (int i = 0; i <= segmentCount; i++) {
      final x = size.width * (i / segmentCount);
      final wave = (i.isEven ? 0.35 : 0.65) + (i % 3 == 0 ? 0.1 : 0.0);
      final y = size.height * (1 - wave);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final controlX = (prev.dx + curr.dx) / 2;
      path.cubicTo(controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ReportStatData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final Color sparkColor;

  _ReportStatData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sparkColor,
  });
}

class _ExportData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  _ExportData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}