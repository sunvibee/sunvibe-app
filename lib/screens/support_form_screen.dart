import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class SupportFormScreen extends StatefulWidget {
  final String? initialCategory;

  const SupportFormScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<SupportFormScreen> createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends State<SupportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _otherDetailsController = TextEditingController();

  static const String _supportEmail = 'support@sunvibe.com';

  static const List<String> _problemCategories = [
    "Robot won't connect (Bluetooth / WiFi)",
    "Cleaning stopped unexpectedly during session",
    "Battery problem / Charging dock issue",
    "Brushes jammed or not rotating properly",
    "Robot stuck on solar panel / obstacle sensor error",
    "Water spray / pump nozzle leakage or blockage",
    "MQTT server / App telemetry sync issue",
    "Scheduled cleaning not triggering",
    "Panel safety or edge detection error",
    "Routine maintenance / Parts replacement inquiry",
    "Other issue (specify in details below)",
  ];

  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory != null &&
            _problemCategories.contains(widget.initialCategory)
        ? widget.initialCategory
        : _problemCategories.first;

    // Pre-fill user information from AuthProvider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userName != null && auth.userName!.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = auth.userName!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _otherDetailsController.dispose();
    super.dispose();
  }

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  bool get _isOtherCategorySelected =>
      _selectedCategory == "Other issue (specify in details below)";

  String _generateTicketId() {
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = millis.length >= 6 ? millis.substring(millis.length - 6) : millis;
    return "SVB-$suffix";
  }

  String _buildEmailBody({
    required String ticketId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String category,
    required String otherDetails,
  }) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    return '''
======================================================
SUNVIBEE PRODUCT SUPPORT TICKET: #$ticketId
======================================================

1. CUSTOMER & CONTACT INFORMATION:
------------------------------------------------------
• Full Name:      $name
• Contact Number: $phone
• Email Address:  $email
• Installation / Site Address:
  $address

2. PRODUCT PROBLEM / ISSUE DETAILS:
------------------------------------------------------
• Category:       $category
• Additional Details / Observations:
  ${otherDetails.trim().isNotEmpty ? otherDetails.trim() : 'None provided'}

3. SYSTEM & METADATA:
------------------------------------------------------
• Submission Time: $timestamp
• App:             SunVibee Solar Panel Cleaning App (v1.0.0)
• Destination:     $_supportEmail
======================================================
''';
  }

  Future<void> _submitForm() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted errors before submitting.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ticketId = _generateTicketId();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final category = _selectedCategory ?? _problemCategories.first;
    final otherDetails = _otherDetailsController.text.trim();

    final emailSubject = 'SunVibee Support Ticket #$ticketId - $category';
    final emailBody = _buildEmailBody(
      ticketId: ticketId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      category: category,
      otherDetails: otherDetails,
    );

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent(emailSubject)}&body=${Uri.encodeComponent(emailBody)}',
    );

    // Add local notification record
    await NotificationService().addNotification(
      title: 'Support Ticket #$ticketId Created',
      message: 'Support request for "$category" prepared for $_supportEmail.',
      type: NotificationType.info,
      showSystemNotification: false,
    );

      bool launched = false;
      try {
        if (await canLaunchUrl(emailUri).timeout(const Duration(seconds: 2))) {
          launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication)
              .timeout(const Duration(seconds: 2));
        } else {
          launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication)
              .timeout(const Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint('Error launching mail client: $e');
        launched = false;
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(
          ticketId: ticketId,
          emailBody: emailBody,
          launchedEmailApp: launched,
        );
      }
  }

  void _showSuccessDialog({
    required String ticketId,
    required String emailBody,
    required bool launchedEmailApp,
  }) {
    final scale = _scale(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(22 * scale),
          constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top animated success badge
                Container(
                  width: 64 * scale,
                  height: 64 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      size: 38 * scale,
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),
                Text(
                  "Support Ticket Prepared",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8 * scale),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 6 * scale),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Ticket ID: $ticketId",
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 14 * scale),
                Text(
                  launchedEmailApp
                      ? "Your email application has been opened with your support ticket pre-filled. Please tap Send in your email app to route it to $_supportEmail."
                      : "Could not open email app directly. We've copied your ticket details so you can send them directly to $_supportEmail.",
                  style: TextStyle(
                    fontSize: 13.5 * scale,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 18 * scale),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.navy.withValues(alpha: 0.3)),
                          padding: EdgeInsets.symmetric(vertical: 12 * scale),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: emailBody));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ticket details copied to clipboard!'),
                              backgroundColor: AppColors.navy,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(Icons.copy_rounded, size: 16 * scale, color: AppColors.navy),
                        label: Text(
                          "Copy Ticket",
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12 * scale),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext); // close dialog
                          Navigator.pop(context); // return to Support screen
                        },
                        child: Text(
                          "Done",
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 28).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20 * scale, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Support Form",
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16 * scale,
              horizontalPadding,
              28 * scale,
            ),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntroBanner(scale),
                SizedBox(height: 18 * scale),
                _buildPersonalDetailsCard(scale),
                SizedBox(height: 18 * scale),
                _buildProblemDetailsCard(scale),
                SizedBox(height: 22 * scale),
                _buildSubmitButton(scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //---------------- Top Intro Banner ----------------
  Widget _buildIntroBanner(double scale) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10 * scale),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.blue,
              size: 26 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Product Issue & Breakdown Assistance",
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  "Facing a malfunction, hardware error, or network fault? Submit this form and our technical team at $_supportEmail will assist you immediately.",
                  style: TextStyle(
                    fontSize: 12.5 * scale,
                    color: Colors.grey.shade700,
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

  //---------------- Personal Details Card ----------------
  Widget _buildPersonalDetailsCard(double scale) {
    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_outline_rounded, color: AppColors.orange, size: 20 * scale),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Text(
                  "Personal & Contact Details",
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),

          // 1. Full Name
          _buildTextFormField(
            controller: _nameController,
            label: "Full Name",
            hint: "Enter your full name",
            icon: Icons.person_rounded,
            scale: scale,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 14 * scale),

          // 2. Contact Number
          _buildTextFormField(
            controller: _phoneController,
            label: "Contact Number",
            hint: "e.g. +91 98765 43210",
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            scale: scale,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Contact number is required';
              }
              final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
              if (digitsOnly.length < 7 || digitsOnly.length > 15) {
                return 'Enter a valid phone number (7-15 digits)';
              }
              return null;
            },
          ),
          SizedBox(height: 14 * scale),

          // 3. Email
          _buildTextFormField(
            controller: _emailController,
            label: "Email Address",
            hint: "name@example.com",
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            scale: scale,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email address is required';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 14 * scale),

          // 4. Address
          _buildTextFormField(
            controller: _addressController,
            label: "Installation / Site Address",
            hint: "Enter complete solar panel site or delivery address",
            icon: Icons.location_on_outlined,
            maxLines: 2,
            scale: scale,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Address is required for product on-site inspection';
              }
              if (value.trim().length < 5) {
                return 'Please provide a more detailed address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  //---------------- Problem Details Card ----------------
  Widget _buildProblemDetailsCard(double scale) {
    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.report_problem_outlined, color: AppColors.red, size: 20 * scale),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Text(
                  "Product Issue & Problem Category",
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Text(
            "Select the problem you are experiencing from the FAQs / troubleshooting options:",
            style: TextStyle(
              fontSize: 12.5 * scale,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14 * scale),

          // Dropdown Input
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 4 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCategory,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.orange, size: 28),
                borderRadius: BorderRadius.circular(14),
                items: _problemCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 18 * scale,
                          color: AppColors.navy,
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13.5 * scale,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 16 * scale),

          // Extra "Any other" / Detailed Description Box
          _buildTextFormField(
            controller: _otherDetailsController,
            label: _isOtherCategorySelected ? "Describe Problem (Required)*" : "Any Other / Additional Details",
            hint: _isOtherCategorySelected
                ? "Please specify the problem, symptoms, or error details..."
                : "Additional notes, LED indicator colors, or what happened before the fault (optional)",
            icon: Icons.edit_note_rounded,
            maxLines: 4,
            scale: scale,
            validator: (value) {
              if (_isOtherCategorySelected && (value == null || value.trim().isEmpty)) {
                return 'Please describe the problem since "Other issue" was selected';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  //---------------- Submit Button ----------------
  Widget _buildSubmitButton(double scale) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52 * scale,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.orange.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 22 * scale,
                    height: 22 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, size: 20 * scale),
                      SizedBox(width: 10 * scale),
                      Flexible(
                        child: Text(
                          "Submit Support Request",
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 12 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 14 * scale, color: Colors.grey.shade600),
            SizedBox(width: 6 * scale),
            Flexible(
              child: Text(
                "Routes directly to SunVibee Support ($_supportEmail)",
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required double scale,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (label.contains('*') || !label.contains('optional')) ...[
              Text(
                " *",
                style: TextStyle(
                  fontSize: 13.5 * scale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 6 * scale),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(fontSize: 14 * scale, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13 * scale, color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF9FAFD),
            prefixIcon: maxLines > 1
                ? Padding(
                    padding: EdgeInsets.only(bottom: 28 * scale),
                    child: Icon(icon, color: AppColors.navy.withValues(alpha: 0.6), size: 20 * scale),
                  )
                : Icon(icon, color: AppColors.navy.withValues(alpha: 0.6), size: 20 * scale),
            contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('connect') || lower.contains('wifi') || lower.contains('bluetooth')) {
      return Icons.wifi_off_rounded;
    } else if (lower.contains('stopped') || lower.contains('cleaning')) {
      return Icons.pause_circle_outline_rounded;
    } else if (lower.contains('battery') || lower.contains('dock')) {
      return Icons.battery_alert_rounded;
    } else if (lower.contains('brush')) {
      return Icons.cleaning_services_rounded;
    } else if (lower.contains('stuck') || lower.contains('obstacle') || lower.contains('sensor')) {
      return Icons.warning_amber_rounded;
    } else if (lower.contains('water') || lower.contains('spray') || lower.contains('nozzle')) {
      return Icons.water_drop_outlined;
    } else if (lower.contains('mqtt') || lower.contains('sync')) {
      return Icons.cloud_off_rounded;
    } else if (lower.contains('schedule')) {
      return Icons.event_busy_rounded;
    } else if (lower.contains('maintenance') || lower.contains('parts')) {
      return Icons.build_circle_outlined;
    }
    return Icons.help_outline_rounded;
  }
}
