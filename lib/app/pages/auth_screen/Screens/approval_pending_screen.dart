import 'dart:convert';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ApprovalPendingScreen extends StatefulWidget {
  const ApprovalPendingScreen({super.key});

  @override
  State<ApprovalPendingScreen> createState() => _ApprovalPendingScreenState();
}

class _ApprovalPendingScreenState extends State<ApprovalPendingScreen> {
  bool _isRefreshing = false;
  String _approvalStatus = 'pending';
  String _rejectedReason = '';
  String _rejectedDescription = '';

  @override
  void initState() {
    super.initState();
    _loadStoredStatus();
    _checkStatusSilently();
  }

  void _loadStoredStatus() {
    final repo = Get.find<Repository>();
    setState(() {
      _approvalStatus = (repo.getStringValue(LocalKeys.driverApprovalStatus)).toLowerCase().trim();
      if (_approvalStatus.isEmpty) {
        // Fallback to userDetails if driverApprovalStatus is not set
        final udStr = repo.getStringValue(LocalKeys.userDetails);
        if (udStr.isNotEmpty) {
          try {
            final ud = jsonDecode(udStr);
            if (ud is Map && ud['approval_status'] != null) {
              _approvalStatus = ud['approval_status'].toString().toLowerCase().trim();
            }
          } catch (_) {}
        }
      }
      if (_approvalStatus.isEmpty) _approvalStatus = 'pending';

      _rejectedReason = repo.getStringValue(LocalKeys.driverRejectedReason);
      _rejectedDescription = repo.getStringValue(LocalKeys.driverRejectedDescription);
    });
  }

  Future<void> _checkStatusSilently() async {
    try {
      final controller = Get.find<AuthController>();
      final res = await controller.authPresenter.fetchDriverProfile(showLoader: false);
      if (!res.hasError) {
        final decoded = jsonDecode(res.data);
        if (decoded != null && (decoded['data'] != null || decoded['Data'] != null)) {
          final data = decoded['data'] ?? decoded['Data'];
          final bool isProfileCompleted = data['is_profile_completed'] == true;
          final status = (data['approval_status'] ?? '').toString().toLowerCase().trim();
          final reason = (data['rejected_reason'] ?? '').toString();
          final desc = (data['rejected_reason_description'] ?? '').toString();

          final repo = Get.find<Repository>();
          repo.saveValue(LocalKeys.isProfileCompleted, isProfileCompleted);
          repo.saveValue(LocalKeys.driverApprovalStatus, status);
          repo.saveValue(LocalKeys.driverRejectedReason, reason);
          repo.saveValue(LocalKeys.driverRejectedDescription, desc);

          // Update cached userDetails as well
          final udStr = repo.getStringValue(LocalKeys.userDetails);
          if (udStr.isNotEmpty) {
            try {
              final ud = jsonDecode(udStr);
              if (ud is Map) {
                ud['is_profile_completed'] = isProfileCompleted;
                ud['approval_status'] = status;
                ud['rejected_reason'] = reason;
                ud['rejected_reason_description'] = desc;
                repo.saveValue(LocalKeys.userDetails, jsonEncode(ud));
              }
            } catch (_) {}
          }

          if (!isProfileCompleted) {
            RouteManagement.gotoHomeScreen();
            return;
          }

          if (mounted) {
            setState(() {
              _approvalStatus = status.isNotEmpty ? status : 'pending';
              _rejectedReason = reason;
              _rejectedDescription = desc;
            });
          }

          if (status == 'approved') {
            Utility.showMessage(
              "Your driver profile has been approved! Welcome to BamBam Cabs.",
              MessageType.success,
              null,
              'ok',
            );
            RouteManagement.gotoHomeScreen();
          }
        }
      }
    } catch (e) {
      debugPrint("Silent driver profile check error: $e");
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _isRefreshing = true);
    await _checkStatusSilently();
    setState(() => _isRefreshing = false);
    if (_approvalStatus != 'approved') {
      Utility.showMessage(
        "Status checked: currently ${_approvalStatus.toUpperCase()}",
        MessageType.information,
        null,
        'ok',
      );
    }
  }

  Future<void> _launchCall() async {
    final Uri uri = Uri(scheme: 'tel', path: '+918980131929');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Utility.showMessage("Could not open dialer", MessageType.error, null, 'ok');
    }
  }

  Future<void> _launchEmail() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: 'support@bambamcabs.com',
      queryParameters: {'subject': 'Driver Account Verification Support'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Utility.showMessage("Could not open email client", MessageType.error, null, 'ok');
    }
  }

  void _navigateToEditProfile() {
    Get.toNamed(Routes.personalDetilesScreen)?.then((_) {
      _manualRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isRejected = _approvalStatus == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isRejected ? "Application Rejected" : "Application Status",
          style: Styles.txtBlackColorW70020,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isRefreshing ? null : _manualRefresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRejected
                      ? [const Color(0xFFDC2626), const Color(0xFFEA580C)]
                      : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isRejected ? Colors.red : Colors.orange).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRejected ? "ACTION REQUIRED" : "APPLICATION UNDER REVIEW",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isRejected
                        ? "Your Application Was Rejected by Admin"
                        : "Your Profile Verification is Under Review",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRejected
                        ? "Your profile was reviewed and rejected. Please check the reason below, re-upload documents, and resubmit for approval."
                        : "Your application has been submitted successfully and is currently under verification by the BamBam Cabs Admin team. You will be able to take rides once approved.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRefreshing ? null : _manualRefresh,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, size: 16),
                          label: Text(
                            _isRefreshing ? "Checking..." : "Refresh Status",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      if (isRejected) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _navigateToEditProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.edit_document, size: 16),
                            label: const Text(
                              "Edit Details",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Rejected Reason Card (Only if rejected)
            if (isRejected) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Reason for Rejection",
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rejectedReason.isNotEmpty
                                ? _rejectedReason
                                : "Documents incomplete or invalid.",
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_rejectedDescription.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _rejectedDescription,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _navigateToEditProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(42),
                      ),
                      child: const Text(
                        "📄 Edit Profile & Re-upload Documents",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Step Progress Timeline
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Verification Progress",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressStep(
                    number: "1",
                    title: "Registration Completed",
                    subtitle: "Driver application submitted",
                    isDone: true,
                    isActive: false,
                  ),
                  _buildProgressStep(
                    number: "2",
                    title: isRejected ? "Action Required" : "Admin Review & Verification",
                    subtitle: isRejected
                        ? "Please update the rejected documents"
                        : "Verification in progress by Admin team",
                    isDone: false,
                    isActive: true,
                    isError: isRejected,
                  ),
                  _buildProgressStep(
                    number: "3",
                    title: "Driver Portal Activation",
                    subtitle: "Trips, earnings & online mode will unlock",
                    isDone: false,
                    isActive: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Admin Support & Contact Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorsValue.appColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "ADMIN HELP DESK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Need Help With Verification?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "If you have any questions or need assistance with your driver profile verification, please contact our help desk.",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone contact
                  InkWell(
                    onTap: _launchCall,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.phone_outlined, color: Color(0xFF34D399), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "CALL SUPPORT",
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "+91 89801 31929",
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Email contact
                  InkWell(
                    onTap: _launchEmail,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.email_outlined, color: Color(0xFF60A5FA), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "EMAIL SUPPORT",
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "support@bambamcabs.com",
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Timing
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.access_time_outlined, color: Color(0xFFFBBF24), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "WORKING HOURS",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "10:00 AM - 6:00 PM (Monday - Saturday)",
                              style: TextStyle(color: Color(0xFFFDE68A), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Option
            TextButton.icon(
              onPressed: () {
                final repo = Get.find<Repository>();
                repo.deleteAllSecuredValues();
                repo.clearData(LocalKeys.authToken);
                repo.clearData(LocalKeys.userDetails);
                repo.clearData(LocalKeys.isProfileCompleted);
                repo.clearData(LocalKeys.driverApprovalStatus);
                repo.clearData(LocalKeys.driverRejectedReason);
                repo.clearData(LocalKeys.driverRejectedDescription);
                RouteManagement.gotoLoginScreen();
              },
              icon: const Icon(Icons.logout, size: 18, color: Colors.red),
              label: const Text(
                "Logout from Account",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep({
    required String number,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isError = false,
  }) {
    Color circleColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF64748B);
    Widget icon = Text(number, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white));

    if (isDone) {
      circleColor = const Color(0xFF10B981);
      icon = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isError) {
      circleColor = const Color(0xFFDC2626);
      icon = const Icon(Icons.close, color: Colors.white, size: 16);
    } else if (isActive) {
      circleColor = const Color(0xFFF59E0B);
      textColor = const Color(0xFF1E293B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isActive || isDone ? const Color(0xFF1E293B) : textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
