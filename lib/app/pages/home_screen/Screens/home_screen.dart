import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/usecases/home_usecases.dart';
import 'package:bam_bam_driver/domain/usecases/profile_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/app/pages/home_screen/Screens/new_ride_popup.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_controller.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_binding.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileController? pCtrl;
  HomeController? hCtrl;

  @override
  void initState() {
    super.initState();

    // Ensure ProfileController is registered (your existing code)
    if (Get.isRegistered<ProfileController>()) {
      pCtrl = Get.find<ProfileController>();
    } else {
      pCtrl = Get.put(
        ProfileController(ProfilePresenter(ProfileUsecases(Get.find()))),
      );
    }

    // Ensure HomeController is registered
    if (Get.isRegistered<HomeController>()) {
      hCtrl = Get.find<HomeController>();
    } else {
      // This should normally be wired by HomeBinding; fallback here
      hCtrl = Get.put(HomeController(HomePresenter(HomeUsecases(Get.find()))));
    }

    // Fetch profile & dashboard as early as possible
    Future.microtask(() async {
      await pCtrl?.fetchProfile();
      if (pCtrl?.profile != null) {
        final prof = pCtrl!.profile!;
        final bool isIndividual = (hCtrl?.loginType == 'individual' || hCtrl?.isIndividual == true);
        final bool isCompleted = prof['is_profile_completed'] == true;
        final String appStatus = (prof['approval_status'] ?? '').toString().toLowerCase();

        if (isIndividual && (!isCompleted || appStatus != 'approved')) {
          hCtrl?.isOnline = false;
        } else if (prof['is_online'] != null) {
          hCtrl?.isOnline = prof['is_online'] == true;
        }

        if (prof['leave_status'] != null) {
          hCtrl?.isLeave = prof['leave_status'] == true;
        }

        // Auto-show popup for individual drivers if profile incomplete or rejected
        if (isIndividual) {
          if (!isCompleted) {
            hCtrl?.showCompleteProfileDialog();
          } else if (appStatus == 'rejected') {
            final reason = (prof['rejected_reason'] ?? 'Documents rejected by Admin').toString();
            hCtrl?.showRejectedProfileDialog(reason);
          }
        }
      } else {
        hCtrl?.isOnline = false;
      }
      await hCtrl?.fetchDashboardSafe(showLoader: false);
      if (mounted) setState(() {});

    });
  }

  /// Helper to build avatar widget
  Widget _buildAvatar(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final fullUrl = imageUrl.startsWith('http')
          ? imageUrl
          : ApiWrapper.imageUrl + imageUrl;
      return CircleAvatar(backgroundImage: NetworkImage(fullUrl));
    } else {
      return const CircleAvatar(
        backgroundImage: AssetImage(AssetConstants.person),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        // prefer live controller values (controller comes from GetBuilder)
        final profile = pCtrl?.profile;
        final displayName =
            (profile != null &&
                (profile['driver_name'] ??
                        profile['full_name'] ??
                        profile['name']) !=
                    null)
            ? (profile['driver_name'] ??
                      profile['full_name'] ??
                      profile['name'])
                  .toString()
            : 'Johnson Doe';
        final profileImageKey =
            (profile != null &&
                (profile['driver_photo'] ??
                        profile['profile_image'] ??
                        profile['avatar']) !=
                    null)
            ? (profile['driver_photo'] ??
                      profile['profile_image'] ??
                      profile['avatar'])
                  .toString()
            : null;

        // Use the controller values fetched earlier
        final ongoing = controller.ongoingTrip.toString();
        final assigned = controller.assignedTrip.toString();
        final history = controller.tripHistory.toString();
        final newRequests = controller.newRequests.toString();
        final rejectedRides = controller.rejectedRides.toString();

        return Scaffold(
          key: controller.scaffoldKey,
          backgroundColor: ColorsValue.appBg,
          appBar: AppBar(
            backgroundColor: ColorsValue.appBg,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.only(left: 20),
              padding: Dimens.edgeInsets3,
              child: InkWell(
                borderRadius: BorderRadius.circular(Dimens.fifty),
                onTap: () {
                  controller.scaffoldKey.currentState?.openDrawer();
                },
                child: _buildAvatar(profileImageKey),
              ),
            ),
            leadingWidth: Dimens.seventy,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: Styles.txtBlackColorW70018,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () {
                    controller.checkAndFetchCurrentLocation(forcePrompt: true);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: controller.isLocationDisabled
                            ? Colors.red
                            : ColorsValue.appColor,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          controller.isFetchingLocation
                              ? "Detecting location..."
                              : controller.isLocationDisabled
                                  ? "Location Disabled"
                                  : controller.currentLocationDisplay.isNotEmpty
                                      ? controller.currentLocationDisplay
                                      : "Current Location",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: controller.isLocationDisabled
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              Row(
                children: [
                  if (controller.loginType == 'individual' || controller.isIndividual)
                    InkWell(
                      onTap: controller.isTogglingStatus
                          ? null
                          : () {
                              controller.toggleOnlineStatus(!controller.isOnline);
                            },
                      borderRadius: BorderRadius.circular(30),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: controller.isOnline
                              ? const Color(0xFF12724A)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.isOnline) ...[
                              const Padding(
                                padding: EdgeInsets.only(left: 8, right: 6),
                                child: Text(
                                  "Online",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: controller.isTogglingStatus
                                    ? const Padding(
                                        padding: EdgeInsets.all(5),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF12724A),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.circle,
                                        color: Color(0xFF12724A),
                                        size: 14,
                                      ),
                              ),
                            ] else ...[
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: controller.isTogglingStatus
                                    ? const Padding(
                                        padding: EdgeInsets.all(5),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Icon(
                                        Icons.circle,
                                        color: Colors.grey.shade400,
                                        size: 14,
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 6, right: 8),
                                child: Text(
                                  "Offline",
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'online') {
                          await controller.toggleOnlineStatus(true);
                        } else if (value == 'offline') {
                          await controller.toggleOnlineStatus(false);
                        } else if (value == 'leave') {
                          _showLeaveDialog(context, controller);
                        }
                      },
                      child: Builder(
                        builder: (context) {
                          final bool hasOngoing = controller.ongoingTrip > 0;
                          final bool isLeave = controller.isLeave;
                          final bool isAvailable = controller.isOnline && !isLeave && !hasOngoing;

                          final String statusText = isLeave
                              ? "Leave"
                              : hasOngoing
                                  ? "Busy"
                                  : isAvailable
                                      ? "Available"
                                      : "Busy";

                          final Color statusColor = isLeave
                              ? Colors.red
                              : hasOngoing
                                  ? Colors.orange
                                  : isAvailable
                                      ? Colors.green
                                      : Colors.orange;

                          final Color bgStatusColor = isLeave
                              ? Colors.red.shade100
                              : hasOngoing
                                  ? Colors.orange.shade100
                                  : isAvailable
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: bgStatusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 5,
                                  backgroundColor: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'online',
                          child: Row(
                            children: [
                              CircleAvatar(radius: 5, backgroundColor: Colors.green),
                              SizedBox(width: 8),
                              Text("Available"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'offline',
                          child: Row(
                            children: [
                              CircleAvatar(radius: 5, backgroundColor: Colors.orange),
                              SizedBox(width: 8),
                              Text("Busy / Offline"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'leave',
                          child: Row(
                            children: [
                              CircleAvatar(radius: 5, backgroundColor: Colors.red),
                              SizedBox(width: 8),
                              Text("Leave (Add Remark)"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  IconButton(
                    icon: Image.asset(
                      AssetConstants.ic_fill_notification,
                      height: Dimens.twentyFour,
                    ),
                    onPressed: () {
                      RouteManagement.gotoNotificationScreen();
                    },
                  ),
                  Dimens.boxWidth8,
                ],
              ),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: Padding(
                padding: Dimens.edgeInsets20_00_20_00,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: Get.back,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: ColorsValue.txtBlackColor,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Real name and profile image in drawer
                    ListTile(
                      title: Text(
                        "Hello, Welcome 🎉",
                        style: Styles.txtBlackColorW50014,
                      ),
                      subtitle: Text(
                        displayName,
                        style: Styles.txtBlackColorW70020,
                      ),
                      leading: _buildAvatar(profileImageKey),
                    ),
                    const Divider(color: Color(0xffD8E2EF)),
                    Dimens.boxHeight10,
                    _drawerItem(
                      AssetConstants.User,
                      "personal_information".tr,
                      RouteManagement.gotoPersonalDetilesScreen,
                    ),
                    if (controller.loginType == 'individual' || controller.isIndividual) ...[
                      _drawerItem(
                        AssetConstants.ic_wallet,
                        "Earnings Vault",
                        RouteManagement.gotoEarningsVaultScreen,
                      ),
                    ],
                    _drawerItem(
                      AssetConstants.ic_finIc,
                      "Issue Fine".tr,
                      RouteManagement.gotoIssuedFinesScreen,
                    ),
                    _drawerItem(
                      AssetConstants.ic_privacy,
                      "privacy_policy".tr,
                      RouteManagement.gotoPrivcyPolicyScreen,
                    ),
                    _drawerItem(
                      AssetConstants.ic_terms,
                      "terms_condition".tr,
                      RouteManagement.gotoTermsConditionsScreen,
                    ),
                    _drawerItem(
                      AssetConstants.ic_Headphones,
                      "submit_support_ticket".tr,
                      RouteManagement.gotoMyTicketlistScreen,
                    ),
                    // const Divider(color: Color(0xffD8E2EF)),
                    // _drawerItem(
                    //   AssetConstants.ic_sets,
                    //   "Delete Account".tr,
                    //   () {
                    //      pCtrl?.showDeleteAccountDialog(context);
                    //   },
                    // ),
                    const Spacer(),
                    Padding(
                      padding: Dimens.edgeInsets16,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Dimens.twelve,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text("Logout"),
                          onPressed: () {
                            controller.showLogoutDelog(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Refresh both profile and dashboard data
              await Future.wait([
                pCtrl?.fetchProfile() ?? Future.value(),
                hCtrl?.fetchDashboardSafe(showLoader: false) ?? Future.value(),
              ]);
              if (mounted) setState(() {});
            },
            child: _buildHomeBody(
              context,
              controller,
              ongoing,
              assigned,
              history,
              newRequests,
              rejectedRides,
            ),
          ),
        );
      },
    );
  }

  void _showLeaveDialog(BuildContext context, HomeController controller) {
    final TextEditingController remarkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Take a Leave", style: Styles.txtBlackColorW70020),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Please provide a remark for your leave:", style: Styles.txtBlackColorW50014),
              const SizedBox(height: 10),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "E.g., Sick leave, family emergency...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorsValue.appColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final remark = remarkController.text.trim();
                if (remark.isEmpty) {
                  Utility.showMessage("Remark cannot be empty", MessageType.error, null, "OK");
                  return;
                }
                Navigator.pop(context);
                controller.toggleLeaveStatus(true, remark: remark);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsValue.appColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Submit Leave", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }


  Widget _buildHomeBody(
    BuildContext context,
    HomeController controller,
    String ongoing,
    String assigned,
    String history,
    String newRequests,
    String rejectedRides,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: Dimens.edgeInsets20_00_20_00,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: ColorsValue.borderColors),
                    Dimens.boxHeight10,

                    // ─── Individual Driver Profile Verification Banner ───
                    if (controller.loginType == 'individual' || controller.isIndividual) ...[
                      Builder(builder: (context) {
                        final prof = pCtrl?.profile;
                        final bool isCompleted = prof?['is_profile_completed'] == true;
                        final String appStatus = (prof?['approval_status'] ?? '').toString().toLowerCase();

                        if (!isCompleted) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.assignment_late_rounded, color: Colors.orange.shade800, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Profile Incomplete",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "Complete your 6-step profile to get verified and start receiving rides.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.brown.shade800,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () => RouteManagement.gotoPersonalDetilesScreen(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: ColorsValue.appColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            "Complete Profile Now",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (appStatus == 'pending' || appStatus == 'draft' || appStatus.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.pending_actions_rounded, color: Colors.blue.shade800, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Profile Under Verification",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "Your documents are under review by BamBam Cabs Admin. You can go online once approved.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade800,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (appStatus == 'rejected') {
                          final reason = (prof?['rejected_reason'] ?? 'Documents rejected by Admin').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.cancel_outlined, color: Colors.red.shade800, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Verification Rejected",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "Reason: $reason",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade800,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () => RouteManagement.gotoPersonalDetilesScreen(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade700,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            "Edit Profile & Resubmit",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],

                    if (controller.isLocationDisabled) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: InkWell(
                          onTap: () => controller.checkAndFetchCurrentLocation(forcePrompt: true),
                          child: Row(
                            children: [
                              Icon(Icons.location_off_rounded, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Location is turned off. Tap here to enable GPS & choose current location.",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade800),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("Enable", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Dimens.boxHeight14,
                    Text("Quick Overview", style: Styles.txtBlackColorW70018),
                    Dimens.boxHeight16,
                    _overviewCard(
                      context,
                      title: "Ongoing Trip",
                      value: controller.isLoadingDashboard ? '...' : ongoing,
                      onTap: () => RouteManagement.gotoTriptrackingScreen(
                        isStartTrip: false,
                      ),
                      bgColor: const Color(0xffFFF4E3),
                      trailingIcon: Icons.arrow_forward_ios_rounded,
                    ),
                    Dimens.boxHeight20,
                    _overviewCard(
                      onTap: RouteManagement.gotoCompletedtripsScreen,
                      context,
                      title: "Completed Trips",
                      value: controller.isLoadingDashboard ? '...' : history,
                      bgColor: const Color(0xffEDF2F9),
                      iconPath: AssetConstants.ic_complect_Trip,
                    ),
                    Dimens.boxHeight20,
                    _overviewCard(
                      onTap: () => RouteManagement.gotoAssignedTripScreen(showOnlyAssigned: true),
                      context,
                      title: "Assigned Trip",
                      value: controller.isLoadingDashboard ? '...' : assigned,
                      bgColor: const Color(0xffEDF2F9),
                      iconPath: AssetConstants.ic_assignedTrip,
                    ),
                    Dimens.boxHeight20,
                    _overviewCard(
                      onTap: () => RouteManagement.gotoAssignedTripScreen(showOnlyRequests: true),
                      context,
                      title: "New Ride Requests",
                      value: controller.isLoadingDashboard ? '...' : newRequests,
                      bgColor: const Color(0xffEDF2F9),
                      iconPath: AssetConstants.ic_notification,
                    ),
                    Dimens.boxHeight20,
                    if (controller.loginType == 'individual' || controller.isIndividual) ...[
                      _overviewCard(
                        onTap: RouteManagement.gotoEarningsVaultScreen,
                        context,
                        title: "Earnings Vault",
                        value: controller.isLoadingDashboard
                            ? '...'
                            : "₹${controller.walletBalance.toStringAsFixed(0)}",
                        bgColor: const Color(0xffEDF2F9),
                        iconPath: AssetConstants.ic_wallet,
                      ),
                      Dimens.boxHeight20,
                    ],
                    Dimens.boxHeight50,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _actionButton(
                          title: "Rules",
                          icon: Icons.warning_rounded,
                          onTap: RouteManagement.gotoRulesScreen,
                        ),
                        Dimens.boxWidth16,
                        _actionButton(
                          title: "Support",
                          icon: Icons.headset_mic_rounded,
                          onTap: RouteManagement.gotoSupportScreen,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "Let’s Ride!",
                      style: Styles.txtBlackColorW70020.copyWith(
                        color: const Color(0xffD9DBE9),
                        fontSize: Dimens.sixty,
                      ),
                    ),
                    Text(
                      "Crafted with ❤️ in Surat, India",
                      style: Styles.txtG5ColorsW40012,
                    ),
                    Dimens.boxHeight40,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _overviewCard(
    BuildContext context, {
    required String title,
    required String value,
    Color? bgColor,
    IconData? trailingIcon,
    String? iconPath,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimens.twelve),
      onTap: onTap,
      child: Container(
        padding: Dimens.edgeInsets20,
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(Dimens.twelve),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Styles.txtG7Colors50016.copyWith(
                    color: ColorsValue.txtG5Colors,
                  ),
                ),
                Dimens.boxHeight8,
                Text(value, style: Styles.txtBlackColorW70018),
              ],
            ),
            if (trailingIcon != null)
              Container(
                decoration: BoxDecoration(
                  color: ColorsValue.whiteColor,
                  borderRadius: BorderRadius.circular(Dimens.fifty),
                ),
                child: Padding(
                  padding: Dimens.edgeInsets8,
                  child: Icon(trailingIcon),
                ),
              )
            else if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 32,
                height: 32,
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.twelve),
        onTap: onTap,
        child: Container(
          padding: Dimens.edgeInsets10,
          decoration: BoxDecoration(
            color: ColorsValue.appColor,
            borderRadius: BorderRadius.circular(Dimens.twelve),
          ),
          child: Column(
            children: [
              Icon(icon, color: ColorsValue.blackColor),
              Dimens.boxHeight8,
              Text(title, style: Styles.txtBlackColorW50016),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(String iconPath, String title, VoidCallback onTap) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
      ),
      title: Text(title, style: Styles.txtBlackColorW50016),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
