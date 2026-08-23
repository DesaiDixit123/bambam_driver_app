import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/usecases/home_usecases.dart';
import 'package:bam_bam_driver/domain/usecases/profile_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';

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
              children: [
                Text("Hello, Welcome 🎉", style: Styles.txtBlackColorW50014),
                Text(displayName, style: Styles.txtBlackColorW70020),
              ],
            ),
            centerTitle: false,
            actions: [
              Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'online') {

                        final bool isBusy = !controller.isOnline && !controller.isLeave;
                        if (isBusy) {
                          _showBusyToAvailableDialog(context, controller);
                        } else {
                          controller.toggleOnlineStatus(true);
                        }
                      } else if (value == 'offline') {
                        controller.toggleOnlineStatus(false);
                      } else if (value == 'leave') {
                        _showLeaveDialog(context, controller);
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final isDriverBusy = controller.ongoingTrip > 0 || controller.assignedTrip > 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: controller.isLeave
                                ? Colors.red.shade100
                                : isDriverBusy
                                    ? Colors.orange.shade100
                                    : controller.isOnline
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 5,
                                backgroundColor: controller.isLeave
                                    ? Colors.red
                                    : isDriverBusy
                                        ? Colors.orange
                                        : controller.isOnline
                                            ? Colors.green
                                            : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                controller.isLeave
                                    ? "Leave"
                                    : isDriverBusy
                                        ? "Busy"
                                        : controller.isOnline
                                            ? "Available"
                                            : "Busy",
                                style: TextStyle(
                                  color: controller.isLeave
                                      ? Colors.red
                                      : isDriverBusy
                                          ? Colors.orange
                                          : controller.isOnline
                                              ? Colors.green
                                              : Colors.orange,
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
                        child: Text("Available"),
                      ),
                      const PopupMenuItem(
                        value: 'leave',
                        child: Text("Leave (Add Remark)"),
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

  void _showBusyToAvailableDialog(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Ride Status", style: Styles.txtBlackColorW70020),
          content: Text(
            "Your ride is successfully complete or not?",
            style: Styles.txtBlackColorW50014,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.toggleOnlineStatus(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsValue.appColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Yes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                    Dimens.boxHeight24,
                    if (controller.isRingtonePlaying) ...[
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: Dimens.twenty),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            controller.stopRingtone();
                          },
                          icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
                          label: const Text("Stop Ringtone", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(vertical: Dimens.fourteen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.twelve)),
                          ),
                        ),
                      ),
                    ],
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
                    if (controller.loginType == 'individual') ...[
                      _overviewCard(
                        onTap: RouteManagement.gotoRejectedRidesScreen,
                        context,
                        title: "Rejected Rides",

                        value: controller.isLoadingDashboard ? '...' : rejectedRides,
                        bgColor: const Color(0xffFFF0F0),
                        trailingIcon: Icons.close_rounded,
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
              SvgPicture.asset(iconPath),
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
      leading: SvgPicture.asset(iconPath),
      title: Text(title, style: Styles.txtBlackColorW50016),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
