import 'dart:convert';
import 'dart:io';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_driver/domain/repositories/repository.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bam_bam_driver/domain/services/socket_connection.dart';

class ProfileController extends GetxController {
  ProfileController(this.profilePresenter);

  final ProfilePresenter profilePresenter;
  // Profile payload from server
  Map<String, dynamic>? profile;

  // Form key & controllers
  GlobalKey<FormState> saveKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();

  // Additional personal fields
  TextEditingController dobController = TextEditingController();
  TextEditingController dlNumberController = TextEditingController();
  TextEditingController dlIssueController = TextEditingController();
  TextEditingController dlExpiryController = TextEditingController();

  // dropdowns / selections
  List<String> cityList = ["Surat", "Ahemdabad", "Bharuch", "Saputara"];
  String selectedCity = "Surat";

  // language and vehicles selections stored as ids (strings)
  List<Map<String, String>> languagesList = []; // {id,name}
  List<Map<String, String>> vehiclesList = []; // {id,name}

  List<String> selectedLanguageIds = [];
  List<String> selectedVehicleIds = [];

  // Local image file paths selected by user (null if not changed)
  String? driverPhotoPath;
  String? dlPhotoPath;

  // Helper preview urls from server
  String driverPhotoUrl = '';
  String dlPhotoUrl = '';

  // state
  bool isLoadingProfile = false;
  bool isUpdating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  String _fullUrl(String? key) {
    if (key == null || key.isEmpty) return '';
    if (key.startsWith('http')) return key;
    return ApiWrapper.imageUrl + key;
  }

/// Fetch profile and populate controllers & selections
Future<void> fetchProfile() async {
  isLoadingProfile = true;
  update();

  final res = await profilePresenter.getProfile();
  isLoadingProfile = false;

  if (res.hasError) {
    try {
      final body = jsonDecode(res.data);
      final msg = body['Message'] ?? body['message'] ?? 'Failed to fetch profile';
      Utility.showMessage(msg.toString(), MessageType.error, null, 'OK');
    } catch (_) {
      Utility.showMessage('Failed to fetch profile', MessageType.error, null, 'OK');
    }
    update();
    return;
  }

  try {
    final body = jsonDecode(res.data);
    if (body is Map && body.containsKey('Data')) {
      profile = Map<String, dynamic>.from(body['Data']);

      // Update SocketConnection channel ID
      String driverId = profile?['_id']?.toString() ?? '';
      if (driverId.isNotEmpty) {
        SocketConnection.updateChannelId(driverId);
      }

      // populate simple fields
      fullNameController.text = profile?['driver_name']?.toString() ?? '';
      emailController.text = profile?['email']?.toString() ?? '';
      phoneNumberController.text = profile?['driver_mobile']?.toString() ?? '';
      pinCodeController.text = profile?['zip_code']?.toString() ?? '';

      // get server city
      final serverCity = profile?['city']?.toString();
      // ensure selectedCity is server value if present, else keep current
      if (serverCity != null && serverCity.isNotEmpty) {
        selectedCity = serverCity;
        // ensure cityList contains serverCity exactly once
        final merged = <String>[];
        // put serverCity first so user sees it
        merged.add(serverCity);
        for (var c in cityList) {
          if (c.trim() != serverCity.trim()) merged.add(c);
        }
        // remove duplicates (keeps first occurrence order)
        cityList = merged.toSet().toList();
      } else {
        // fallback: ensure cityList has unique values
        cityList = cityList.toSet().toList();
      }

      // dob and DL dates (format to yyyy-MM-dd for date picker)
      if (profile?['dob'] != null) {
        try {
          DateTime dt = DateTime.parse(profile!['dob'].toString());
          dobController.text = dt.toIso8601String().split('T').first;
        } catch (_) {
          dobController.text = profile?['dob']?.toString() ?? '';
        }
      }
      if (profile?['DL_issue_date'] != null) {
        try {
          DateTime dt = DateTime.parse(profile!['DL_issue_date'].toString());
          dlIssueController.text = dt.toIso8601String().split('T').first;
        } catch (_) {
          dlIssueController.text = profile?['DL_issue_date']?.toString() ?? '';
        }
      }
      if (profile?['DL_expiry_date'] != null) {
        try {
          DateTime dt = DateTime.parse(profile!['DL_expiry_date'].toString());
          dlExpiryController.text = dt.toIso8601String().split('T').first;
        } catch (_) {
          dlExpiryController.text = profile?['DL_expiry_date']?.toString() ?? '';
        }
      }
      dlNumberController.text = profile?['DL_number']?.toString() ?? '';

      // images
      driverPhotoUrl = _fullUrl(profile?['driver_photo']?.toString());
      dlPhotoUrl = _fullUrl(profile?['DL_photo']?.toString());

      // ✅ Update isOnline and isLeave in HomeController if registered
      if (Get.isRegistered<HomeController>()) {
        final hCtrl = Get.find<HomeController>();
        final onlineStatus = profile?['is_online'];
        final leaveStatus = profile?['leave_status'];
        final leaveRemark = profile?['leave_remark'];
        
        if (onlineStatus is bool) {
          hCtrl.isOnline = onlineStatus;
        }
        if (leaveStatus is bool) {
          hCtrl.isLeave = leaveStatus;
        }
        if (leaveRemark is String) {
          hCtrl.leaveRemark = leaveRemark;
        }
        hCtrl.update();
      }

      // languages and vehicles: server returns objects array, convert to lists
      selectedLanguageIds = [];
      languagesList = [];
      if (profile?['language_known'] is List) {
        for (var item in profile!['language_known']) {
          if (item is Map) {
            final id = item['_id']?.toString() ?? '';
            final name = item['name']?.toString() ?? id;
            languagesList.add({'id': id, 'name': name});
            if (id.isNotEmpty) selectedLanguageIds.add(id);
          } else if (item is String) {
            languagesList.add({'id': item, 'name': item});
            if (item.isNotEmpty) selectedLanguageIds.add(item);
          }
        }
        // dedupe languagesList and selectedLanguageIds
        languagesList = {
          for (var e in languagesList) e['id']!: e
        }.values.toList();
        selectedLanguageIds = selectedLanguageIds.toSet().toList();
      }

      selectedVehicleIds = [];
      vehiclesList = [];
      if (profile?['vehicales_drive'] is List) {
        for (var item in profile!['vehicales_drive']) {
          if (item is Map) {
            final id = item['_id']?.toString() ?? '';
            final name = item['name']?.toString() ?? id;
            vehiclesList.add({'id': id, 'name': name});
            if (id.isNotEmpty) selectedVehicleIds.add(id);
          } else if (item is String) {
            vehiclesList.add({'id': item, 'name': item});
            if (item.isNotEmpty) selectedVehicleIds.add(item);
          }
        }
        // dedupe vehiclesList and selectedVehicleIds
        vehiclesList = {
          for (var e in vehiclesList) e['id']!: e
        }.values.toList();
        selectedVehicleIds = selectedVehicleIds.toSet().toList();
      }

    }
  } catch (e) {
    Utility.showMessage('Failed to parse profile', MessageType.error, null, 'OK');
  }

  update();
}

  /// Image pick helpers
  Future<void> pickDriverPhoto() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      driverPhotoPath = picked.path;
      driverPhotoUrl = ''; // clear preview url to show local file
      update();
    }
  }

  Future<void> pickDlPhoto() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      dlPhotoPath = picked.path;
      dlPhotoUrl = '';
      update();
    }
  }

  /// Update profile: prepare form fields and files and call presenter
  Future<void> updateProfile() async {
    if (!saveKey.currentState!.validate()) return;

    isUpdating = true;
    update();

    Map<String, String> fields = {};

    fields['driver_name'] = fullNameController.text.trim();
    fields['driver_mobile'] = phoneNumberController.text.trim();
    fields['email'] = emailController.text.trim();
    fields['city'] = selectedCity;
    if (pinCodeController.text.isNotEmpty) fields['zip_code'] = pinCodeController.text.trim();

    if (dobController.text.isNotEmpty) fields['dob'] = dobController.text.trim();
    if (dlNumberController.text.isNotEmpty) fields['DL_number'] = dlNumberController.text.trim();
    if (dlIssueController.text.isNotEmpty) fields['DL_issue_date'] = dlIssueController.text.trim();
    if (dlExpiryController.text.isNotEmpty) fields['DL_expiry_date'] = dlExpiryController.text.trim();

    // driverId required by update
    if (profile != null && profile!['_id'] != null) {
      fields['driverId'] = profile!['_id'].toString();
    }

    // arrays as JSON strings (server received like this in screenshot)
    if (selectedLanguageIds.isNotEmpty) {
      fields['language_known'] = jsonEncode(selectedLanguageIds);
    }
    if (selectedVehicleIds.isNotEmpty) {
      fields['vehicales_drive'] = jsonEncode(selectedVehicleIds);
    }

    // files map (paths or null)
    final filePaths = <String, String?>{
      'driver_photo': driverPhotoPath,
      'DL_photo': dlPhotoPath,
    };

    final res = await profilePresenter.updateProfile(fields: fields, filePaths: filePaths);
print(res.data);
    isUpdating = false;

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        final msg = body['Message'] ?? body['message'] ?? 'Failed to update';
        Utility.showMessage(msg.toString(), MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to update', MessageType.error, null, 'OK');
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      final msg = body['Message'] ?? body['message'] ?? 'Profile updated';
      Utility.showMessage(msg.toString(), MessageType.success, null, 'OK');

      // refresh profile to get server-saved values & urls
      await fetchProfile();
    } catch (_) {
      Utility.showMessage('Profile updated', MessageType.success, null, 'OK');
      await fetchProfile();
    }

    update();
  }

  /// Helpers for multi-select toggles (languages/vehicle)
  void toggleLanguage(String id) {
    if (selectedLanguageIds.contains(id)) selectedLanguageIds.remove(id);
    else selectedLanguageIds.add(id);
    update();
  }

  void toggleVehicle(String id) {
    if (selectedVehicleIds.contains(id)) selectedVehicleIds.remove(id);
    else selectedVehicleIds.add(id);
    update();
  }

  void clearController() {
    fullNameController.clear();
    emailController.clear();
    phoneNumberController.clear();
    pinCodeController.clear();
    dobController.clear();
    dlNumberController.clear();
    dlIssueController.clear();
    dlExpiryController.clear();
    selectedLanguageIds = [];
    selectedVehicleIds = [];
    driverPhotoPath = null;
    dlPhotoPath = null;
    update();
  }
  /// ----------------------------------------------Personal Detiles Screen--------------------------------------------------------



  /// --------------------------------------------------Logout page------------------------------------------------------------------
 
  /// --------------------------------------------------Support page------------------------------------------------------------------

  TextEditingController ticketsDateController = TextEditingController();
  TextEditingController bookingIDController = TextEditingController();
  TextEditingController ticketDepController = TextEditingController();

  List<String> issueList = [
    "Booking Issue",
    "Payment Issue",
    "Driver Behavior",
    "Vehicle Condition",
    "Cancellation/Refund",
    "App Technical Problem",
    "General Inquiry",
  ];

  String selectedIssue = "Booking Issue";




 


  File? ticketAttachment; // file selected by user

  // tickets list & pagination state
  List<dynamic> tickets = [];
  int currentPage = 1;
  int perPage = 10;
  bool isLoadingMore = false;
  bool hasMore = true;

  // ticket detail
  Map<String, dynamic>? ticketDetail;

  /// Pick attachment (use image_picker in UI code)
  void setAttachment(File file) {
    ticketAttachment = file;
    update();
  }

  /// Create ticket API
  Future<void> createTicket() async {
    // validate basic fields
    if (bookingIDController.text.trim().isEmpty) {
      Utility.showMessage('Enter Booking ID', MessageType.error, null, 'ok');
      return;
    }
    if (ticketsDateController.text.trim().isEmpty) {
      Utility.showMessage('Select date', MessageType.error, null, 'ok');
      return;
    }
    if (ticketDepController.text.trim().isEmpty) {
      Utility.showMessage('Enter description', MessageType.error, null, 'ok');
      return;
    }

    final response = await profilePresenter.createTicket(
      issueType: selectedIssue,
      description: ticketDepController.text.trim(),
      bookingId: bookingIDController.text.trim(),
      attachment: ticketAttachment,
      showLoader: true,
    );
fetchTicketsWithoutPagination();
    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('message')) ? body['message'].toString() : response.data;
        Utility.showMessage(msg, MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage('Failed to create ticket', MessageType.error, null, 'ok');
      }
      return;
    }

    try {
      final body = jsonDecode(response.data);
      final msg = (body is Map && body.containsKey('Message')) ? body['Message'] : 'Ticket created';
      Utility.showMessage(msg.toString(), MessageType.success, null, 'ok');

      // optional: retrieve ticket id from response to navigate to detail
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'];
        final ticketId = data is Map && data.containsKey('ticket_id') ? data['ticket_id'].toString() : null;
        if (ticketId != null) {
          // navigate to ticket details page, or refresh list
          RouteManagement.gotoTicketDetilesScreen(); // or pass id if your route accepts it
        } else {
          // just pop
          Get.back();
        }
      } else {
        Get.back();
      }

      // clear form
      bookingIDController.clear();
      ticketsDateController.clear();
      ticketDepController.clear();
      ticketAttachment = null;
      update();
    } catch (e) {
      Get.back();
      Utility.showMessage('Ticket created', MessageType.success, null, 'ok');
    }
  }

  /// Fetch tickets (without pagination)
  Future<void> fetchTicketsWithoutPagination({String search = '', String status = ''}) async {
    final response = await profilePresenter.listTicketsWithoutPagination(search: search, status: status, showLoader: true);
    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('message')) ? body['message'] : response.data;
        Utility.showMessage(msg.toString(), MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage('Failed to fetch tickets', MessageType.error, null, 'ok');
      }
      return;
    }

    try {
      final body = jsonDecode(response.data);
      if (body is Map && body.containsKey('Data')) {
        tickets = List.from(body['Data']);
        update();
      }
    } catch (_) {}
  }

  /// Fetch tickets with pagination (append)
  Future<void> fetchTicketsWithPagination({int page = 1, int limit = 10, String search = '', String status = ''}) async {
    if (!hasMore && page != 1) return;

    if (page == 1) {
      tickets = [];
      currentPage = 1;
      hasMore = true;
    } else {
      isLoadingMore = true;
      update();
    }

    final response = await profilePresenter.listTicketsWithPagination(page: page, limit: limit, search: search, status: status, showLoader: true);

    if (response.hasError) {
      isLoadingMore = false;
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('message')) ? body['message'] : response.data;
        Utility.showMessage(msg.toString(), MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage('Failed to fetch tickets', MessageType.error, null, 'ok');
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(response.data);
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'];
        final items = data is List ? data : (data is Map && data.containsKey('tickets') ? List.from(data['tickets']) : []);
        if (page == 1) {
          tickets = List.from(items);
        } else {
          tickets.addAll(List.from(items));
        }

        // Simple hasMore calculation: if returned less than limit then no more
        if (items.length < limit) {
          hasMore = false;
        } else {
          hasMore = true;
          currentPage = page;
        }
      }
    } catch (_) {
      // ignore
    } finally {
      isLoadingMore = false;
      update();
    }
  }

  /// View ticket details
  Future<void> fetchTicketDetails(String ticketId) async {
    final response = await profilePresenter.viewTicket(ticketId: ticketId, showLoader: true);

    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('message')) ? body['message'] : response.data;
        Utility.showMessage(msg.toString(), MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage('Failed to load ticket details', MessageType.error, null, 'ok');
      }
      return;
    }

    try {
      final body = jsonDecode(response.data);
      if (body is Map && body.containsKey('Data')) {
        ticketDetail = body['Data'] is Map ? Map<String, dynamic>.from(body['Data']) : null;
        update();
      }
    } catch (_) {}
  }

  /// Delete Account Logic
  Future<void> deleteAccount() async {
    final res = await profilePresenter.deleteAccount(showLoader: true);

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        final msg = body['Message'] ?? body['message'] ?? 'Failed to delete account';
        Utility.showMessage(msg.toString(), MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to delete account', MessageType.error, null, 'OK');
      }
      return;
    }

    try {
      final body = jsonDecode(res.data);
      final msg = body['Message'] ?? body['message'] ?? 'Account deleted successfully';
      Utility.showMessage(msg.toString(), MessageType.success, null, 'OK');

      // Clear all data and logout
      final repo = Get.find<Repository>();
      repo.deleteAllSecuredValues();
      repo.clearData(LocalKeys.authToken);
      repo.clearData(LocalKeys.userDetails);

      RouteManagement.gotoLoginScreen();
    } catch (e) {
      Utility.showMessage('Account deleted successfully', MessageType.success, null, 'OK');
      RouteManagement.gotoLoginScreen();
    }
  }

  void showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.twenty),
          ),
          child: Padding(
            padding: Dimens.edgeInsets20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      child: SvgPicture.asset(
                        AssetConstants.ic_cancel,
                        height: Dimens.twentyFour,
                      ),
                    ),
                  ],
                ),
                Dimens.boxHeight10,
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
                Dimens.boxHeight20,
                Text(
                  "Delete Account",
                  style: Styles.txtBlackColorW70020,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight12,
                Text(
                  "Are you sure you want to delete your account? This action cannot be undone.",
                  style: Styles.txtG5ColorsW40014,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight30,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimens.twelve),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    Dimens.boxWidth12,
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await deleteAccount();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimens.twelve),
                          ),
                        ),
                        child: const Text("Delete"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
