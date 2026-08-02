// import 'package:flutter/material.dart';
// import '../widgets/bottom_nav_bar.dart';
// import 'home_screen.dart';
// import 'robots_screen.dart';
// // import 'history_screen.dart';
// // import 'support_screen.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   double _scale(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     return (width / 375).clamp(0.85, 1.25);
//   }

//   void _onNavTap(BuildContext context, int index) {
//     if (index == 4) return; // Already on Profile

//     // Navigate to different screens
//     if (index == 0) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//       );
//     } else if (index == 1) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const RobotsScreen()),
//       );
//     } else if (index == 2) {
//       // Navigator.pushReplacement(
//       //   context,
//       //   MaterialPageRoute(builder: (_) => const HistoryScreen()),
//       // );
//     } else if (index == 3) {
//       // Navigator.pushReplacement(
//       //   context,
//       //   MaterialPageRoute(builder: (_) => const SupportScreen()),
//       // );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scale = _scale(context);
//     final horizontalPadding = (20 * scale).clamp(16, 28).toDouble();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         automaticallyImplyLeading: true,
//         title: Text(
//           "Profile",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//             fontSize: 24 * scale,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.edit_outlined, color: Colors.black87, size: 22 * scale),
//             onPressed: () {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text("Edit profile")));
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.description_outlined, color: Colors.black54, size: 22 * scale),
//             onPressed: () {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text("Reports")));
//             },
//           ),
//           SizedBox(width: 4 * scale),
//         ],
//       ),
//       body: SafeArea(
//         top: false,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.fromLTRB(
//             horizontalPadding,
//             8 * scale,
//             horizontalPadding,
//             0,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildProfileCard(context, scale),
//               SizedBox(height: 18 * scale),
//               _buildStatsRow(scale),
//               SizedBox(height: 18 * scale),
//               _buildInfoCard(context, scale),
//               SizedBox(height: 20 * scale),
//               _buildAccountSettingsButton(context, scale),
//               SizedBox(height: 16 * scale),
//               _buildLogOut(context, scale),
//               SizedBox(height: 24 * scale),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 4, // Profile is index 4
//         onTap: (index) => _onNavTap(context, index),
//       ),
//     );
//   }

//   //---------------- Top Profile Card ----------------
//   Widget _buildProfileCard(BuildContext context, double scale) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(vertical: 28 * scale, horizontal: 20 * scale),
//       decoration: BoxDecoration(
//         color: AppColors.card,
//         borderRadius: BorderRadius.circular(28),
//       ),
//       child: Column(
//         children: [
//           // Avatar with gradient ring + verified badge
//           SizedBox(
//             width: 108 * scale,
//             height: 108 * scale,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   width: 108 * scale,
//                   height: 108 * scale,
//                   padding: EdgeInsets.all(4 * scale),
//                   decoration: const BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: SweepGradient(
//                       colors: [
//                         Color(0xFFFFC947),
//                         Color(0xFFFF7A00),
//                         Color(0xFF4A90D9),
//                         Color(0xFFFFC947),
//                       ],
//                     ),
//                   ),
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                     ),
//                     padding: EdgeInsets.all(3 * scale),
//                     child: CircleAvatar(
//                       backgroundColor: Colors.grey.shade200,
//                       child: Icon(
//                         Icons.person,
//                         size: 46 * scale,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   right: -2 * scale,
//                   bottom: -2 * scale,
//                   child: Container(
//                     padding: EdgeInsets.all(4 * scale),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                     child: CircleAvatar(
//                       radius: 13 * scale,
//                       backgroundColor: const Color(0xFF1565C0),
//                       child: Icon(Icons.verified, color: Colors.white, size: 16 * scale),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 16 * scale),
//           Text(
//             "Rahul Sharma",
//             style: TextStyle(
//               fontSize: 22 * scale,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 10 * scale),
//           _contactRow(Icons.email_outlined, "rahul@email.com", scale),
//           SizedBox(height: 6 * scale),
//           _contactRow(Icons.phone_outlined, "+91 98765 43210", scale),
//           SizedBox(height: 18 * scale),
//           Wrap(
//             alignment: WrapAlignment.center,
//             spacing: 10 * scale,
//             runSpacing: 8 * scale,
//             children: [
//               _badgeChip(
//                 icon: Icons.star,
//                 iconColor: const Color(0xFFB8860B),
//                 label: "Verified User",
//                 bgColor: const Color(0xFFFCE9C4),
//                 textColor: const Color(0xFF7A5A00),
//                 scale: scale,
//               ),
//               _badgeChip(
//                 label: "Member Since: March 2026",
//                 bgColor: Colors.grey.shade200,
//                 textColor: Colors.black87,
//                 scale: scale,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _contactRow(IconData icon, String text, double scale) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 16 * scale, color: Colors.grey.shade600),
//         SizedBox(width: 6 * scale),
//         Flexible(
//           child: Text(
//             text,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(color: Colors.grey.shade700, fontSize: 14 * scale),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _badgeChip({
//     IconData? icon,
//     Color? iconColor,
//     required String label,
//     required Color bgColor,
//     required Color textColor,
//     required double scale,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (icon != null) ...[
//             Icon(icon, size: 14 * scale, color: iconColor),
//             SizedBox(width: 5 * scale),
//           ],
//           Text(
//             label,
//             style: TextStyle(
//               color: textColor,
//               fontSize: 12.5 * scale,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   //---------------- Stats Row ----------------
//   Widget _buildStatsRow(double scale) {
//     return Row(
//       children: [
//         Expanded(
//           child: _statBox(
//             value: "12",
//             valueColor: const Color(0xFF1565C0),
//             label: "ACTIVE ROBOTS",
//             scale: scale,
//           ),
//         ),
//         SizedBox(width: 14 * scale),
//         Expanded(
//           child: _statBox(
//             value: "98%",
//             valueColor: const Color(0xFFB8860B),
//             label: "EFFICIENCY",
//             scale: scale,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _statBox({
//     required String value,
//     required Color valueColor,
//     required String label,
//     required double scale,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(18 * scale),
//       decoration: BoxDecoration(
//         color: AppColors.card,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           FittedBox(
//             fit: BoxFit.scaleDown,
//             alignment: Alignment.centerLeft,
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 26 * scale,
//                 fontWeight: FontWeight.bold,
//                 color: valueColor,
//               ),
//             ),
//           ),
//           SizedBox(height: 6 * scale),
//           Text(
//             label,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 11.5 * scale,
//               letterSpacing: 0.5,
//               color: Colors.black54,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   //---------------- Info List Card ----------------
//   Widget _buildInfoCard(BuildContext context, double scale) {
//     final items = [
//       {
//         "icon": Icons.location_on_outlined,
//         "iconBg": const Color(0xFFDCEAFB),
//         "iconColor": const Color(0xFF1565C0),
//         "label": "My Sites",
//       },
//       {
//         "icon": Icons.precision_manufacturing_outlined,
//         "iconBg": const Color(0xFFFBEACB),
//         "iconColor": const Color(0xFF8A5A00),
//         "label": "Connected Robots",
//       },
//       {
//         "icon": Icons.confirmation_number_outlined,
//         "iconBg": const Color(0xFFFBDCDC),
//         "iconColor": const Color(0xFFC0392B),
//         "label": "Support Tickets",
//       },
//       {
//         "icon": Icons.description_outlined,
//         "iconBg": const Color(0xFFE3E3E6),
//         "iconColor": const Color(0xFF444444),
//         "label": "Cleaning Reports",
//       },
//     ];

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: AppColors.card,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         children: List.generate(items.length, (index) {
//           final item = items[index];
//           final isLast = index == items.length - 1;
//           return Column(
//             children: [
//               _infoTile(
//                 context: context,
//                 icon: item["icon"] as IconData,
//                 iconBg: item["iconBg"] as Color,
//                 iconColor: item["iconColor"] as Color,
//                 label: item["label"] as String,
//                 scale: scale,
//               ),
//               if (!isLast)
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 18 * scale),
//                   child: Divider(height: 1, color: Colors.grey.shade200),
//                 ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _infoTile({
//     required BuildContext context,
//     required IconData icon,
//     required Color iconBg,
//     required Color iconColor,
//     required String label,
//     required double scale,
//   }) {
//     return InkWell(
//       onTap: () {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
//       },
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 18 * scale),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 20 * scale,
//               backgroundColor: iconBg,
//               child: Icon(icon, color: iconColor, size: 20 * scale),
//             ),
//             SizedBox(width: 16 * scale),
//             Expanded(
//               child: Text(
//                 label,
//                 style: TextStyle(fontSize: 16 * scale, color: Colors.black87),
//               ),
//             ),
//             Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22 * scale),
//           ],
//         ),
//       ),
//     );
//   }

//   //---------------- Account Settings Button ----------------
//   Widget _buildAccountSettingsButton(BuildContext context, double scale) {
//     return SizedBox(
//       width: double.infinity,
//       child: OutlinedButton(
//         style: OutlinedButton.styleFrom(
//           side: BorderSide(color: Colors.grey.shade300),
//           padding: EdgeInsets.symmetric(vertical: 16 * scale),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(28),
//           ),
//         ),
//         onPressed: () {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("Account Settings")));
//         },
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.settings_outlined, size: 20 * scale, color: Colors.black87),
//             SizedBox(width: 8 * scale),
//             Text(
//               "Account Settings",
//               style: TextStyle(
//                 fontSize: 16 * scale,
//                 color: Colors.black87,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   //---------------- Log Out ----------------
//   Widget _buildLogOut(BuildContext context, double scale) {
//     return Center(
//       child: InkWell(
//         onTap: () {
//           // Navigate back to home and show logout message
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const HomeScreen()),
//           );
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("Logged out")));
//         },
//         child: Padding(
//           padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 12 * scale),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.logout, size: 18 * scale, color: Colors.red),
//               SizedBox(width: 8 * scale),
//               Text(
//                 "Log Out",
//                 style: TextStyle(
//                   color: Colors.red,
//                   fontSize: 15 * scale,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
