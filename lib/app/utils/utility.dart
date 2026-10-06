import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/data.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';

abstract class Utility {
  //Internet Connection Checker
  static Future<bool> isNetworkAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    try {
      // Try a DNS lookup to confirm internet access
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Android google playstor live app version check
  static InStoreAppVersionChecker checker = InStoreAppVersionChecker(
    //Add Your package name
    appId: 'com.bambam.driver',
  );

  /// Open Google Maps for navigation/directions to the given address
  static Future<void> openMap(String address) async {
    final cleanAddr = address.trim();
    if (cleanAddr.isEmpty || cleanAddr == '—' || cleanAddr == 'null') {
      Utility.showMessage("Address not available", MessageType.error, null, "OK");
      return;
    }
    final query = Uri.encodeComponent(cleanAddr);
    final navUri = Uri.parse("google.navigation:q=$query&mode=d");
    final dirUri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving");

    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(dirUri)) {
        await launchUrl(dirUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(dirUri, mode: LaunchMode.platformDefault);
    } catch (e) {
      Utility.showMessage("Could not open map: $e", MessageType.error, null, "OK");
    }
  }

  //ApiHeader
  static Map<String, String> commonHeader({
    Map<String, String>? otherHeader,
    bool isDefaultAuthorizationKeyAdd = true,
    bool forMultipart =
        false, // when uploading files, content-type should be omitted
  }) {
    final header = <String, String>{};

    if (!forMultipart) {
      header['Content-Type'] = 'application/json';
    }
    header['Accept'] = 'application/json';

    if (isDefaultAuthorizationKeyAdd) {
      final token = Get.find<Repository>().getStringValue(LocalKeys.authToken);
      print(token);
      if (token.isNotEmpty) {
        header['Authorization'] = 'Bearer $token';
      }
    }

    if (otherHeader != null) {
      header.addAll(otherHeader);
    }
    return header;
  }

  //Password validation
  static String? validatePassword(String value) {
    if (value.trim().isNotEmpty) {
      if (value.contains(RegExp(r'[A-Z]'))) {
        if (value.contains(RegExp(r'[0-9]'))) {
          if (value.length < 6) {
            return 'Should Be 6 Characters'.tr;
          } else {
            return null;
          }
        } else {
          return 'Should Have OneDigit'.tr;
        }
      } else {
        return 'Should Have One Uppercase Letter'.tr;
      }
    } else {
      return 'Password Required'.tr;
    }
  }

  //Email validation
  static bool emailValidation(String value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    return (!regex.hasMatch(value)) ? false : true;
  }

  //Remove All Html Tag
  static String removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  /// createDate '2018-04-10T04:00:00.000Z' To Time
  static String getFormatedTime(String dateTime, String dateTimeformat) {
    var date = DateTime.parse(dateTime);
    var format = DateFormat(dateTimeformat);
    return format.format(date);
  }

  //Timestemp to Time & Date
  static String parseTimeStampToTime(int value, String dateTimeformat) {
    var date = DateTime.fromMillisecondsSinceEpoch(value);
    var d12 = DateFormat(dateTimeformat).format(date);
    return d12;
  }

  // Date Format Change
  static String dateStringConvertDate(String tod) {
    var inputFormat = DateFormat('dd-MM-yyyy');
    var date = inputFormat.parse(tod);
    var formattedTime = DateFormat('dd/MM/yyyy');
    return formattedTime.format(date);
  }

  /// Calculates number of weeks for a given year as per https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
  static int _numOfWeeks(int year) {
    var dec28 = DateTime(year, 12, 28);
    var dayOfDec28 = int.parse(DateFormat('D').format(dec28));
    return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
  }

  // Calculates week number from a date as per https://en.wikipedia.org/wiki/ISO_week_date#Calculation
  static int weekNumber(DateTime date) {
    var dayOfYear = int.parse(DateFormat('D').format(date));
    var woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = _numOfWeeks(date.year - 1);
    } else if (woy > _numOfWeeks(date.year)) {
      woy = 1;
    }
    return woy;
  }

  /// URL Launcher
  static void launchLinkURL(String url) async {
    await launchUrl(Uri.parse(url)).onError((error, stackTrace) {
      print("Url is not valid!");
      return false;
    });
  }

  static int _loaderCount = 0;

  /// Show transparent loader with car GIF
  static void showLoader() async {
    _loaderCount++;
    if (_loaderCount > 1) return;
    await Get.dialog<dynamic>(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Center(
            child: Image.asset(
              AssetConstants.loaderGif,
              width: 280,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.25),
    );
  }

  static Widget loaderWidget() => Center(
        child: Image.asset(
          AssetConstants.loaderGif,
          width: 240,
          fit: BoxFit.contain,
        ),
      );

  /// Close loader
  static void closeLoader({bool force = false}) {
    if (force || _loaderCount <= 1) {
      _loaderCount = 0;
      closeDialog();
    } else {
      _loaderCount--;
    }
  }

  /// Close any open dialog.
  static void closeDialog() {
    if (Get.isDialogOpen == true) {
      Get.back<void>();
    }
  }

  /// Close any open snackbar
  static void closeSnackbar() {
    if (Get.isSnackbarOpen) {
      Get.back<void>();
    }
  }

  /// Returns Platform type
  static String platFormType() {
    var value = kIsWeb
        ? 3
        : GetPlatform.isAndroid
        ? 1
        : 2;
    return value.toString();
  }

  /// Random number generator
  static int getRandomNumer(int num) {
    var random = Random();
    return random.nextInt(num);
  }

  /// Return file size
  static String getFileSize(int size) {
    if (size == 0) {
      return '0 KB';
    } else {
      var val = size / pow(1024, (log(size) / log(1024)).floor());
      if (size < 1024) {
        return '$val KB';
      } else {
        return '${val.toStringAsFixed(1)} MB';
      }
    }
  }

  ////imageOptimization
  static String imageOptimization({
    required String bucket,
    required String url,
    required int width,
    required int height,
    required int quality,
    bool progressive = true,
    bool mozjpeg = true,
    required int blur,
  }) {
    var map = '';
    if (blur == 0) {
      map =
          '{"bucket": "$bucket","key": "$url","edits": {"resize": {"width": $width},"jpeg": {"quality": $quality,"progressive": $progressive,"mozjpeg": $mozjpeg}}}';
    } else {
      map =
          '{"bucket": "$bucket","key": "$url","edits": {"resize": {"width": $width},"jpeg": {"quality": $quality,"progressive": $progressive,"mozjpeg": $mozjpeg},"blur": $blur}}';
    }
    var data = base64Encode(utf8.encode(map));
    return data;
  }

  /// imageOptimizationWithoutSize
  static String imageOptimizationWithoutSize({
    required String bucket,
    required String key,
    required int quality,
    required bool progressive,
    required bool mozjpeg,
    required int blur,
  }) {
    var map = '';
    if (blur == 0) {
      map =
          '{"bucket": "$bucket","key": "$key","edits": {"jpeg": {"quality": $quality,"progressive": $progressive,"mozjpeg": $mozjpeg}}}';
    } else {
      map =
          '{"bucket": "$bucket","key": "$key","edits": {"jpeg": {"quality": $quality,"progressive": $progressive,"mozjpeg": $mozjpeg},"blur": $blur}}';
    }
    var data = base64Encode(utf8.encode(map));
    return data;
  }

  // Check Dark/Light Mode
  static bool isThemeDarkMode() {
    var repository = Get.find<Repository>();
    var themeMode = repository.getStoredValue(LocalKeys.isThemeDarkMode);
    return themeMode;
  }

  /// Compare password & confirm password.
  static bool comparePasswords(String password, String confirmPassword) {
    if (password == confirmPassword) {
      return true;
    }
    return false;
  }

  //Showmessage Type
  //Showmessage Type
  static void showMessage(
    String? message,
    MessageType type,
    Function()? onTap,
    String actionName,
  ) {
    if (message == null || message.isEmpty) return;

    Color bg = Colors.black;
    if (type == MessageType.error) bg = Colors.red;
    if (type == MessageType.success) bg = Colors.green;
    if (type == MessageType.information) bg = Colors.blueGrey;

    final context = Get.context;
    if (context == null) return;

    // Clear previous snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show TOP snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
        backgroundColor: bg,
        duration: const Duration(seconds: 2), // Auto close after 2 sec
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 12), // TOP spacing
        dismissDirection: DismissDirection.down,

        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        animation: CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: Curves.easeOut,
        ),
        // action: SnackBarAction(
        //   label: actionName,
        //   textColor: Colors.white,
        //   onPressed: onTap ?? () {},
        // ),
      ),
    );
  }

  /// Show Error bottomsheet.
  ///
  static void showErrorBottomSheet({
    required String? message,
    Function()? onPress,
    bool isDismissible = true,
    bool autoDismiss = true,
  }) async {
    await Get.bottomSheet<void>(
      Container(
        padding: Dimens.edgeInsets30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$message',
              style: Styles.txtBlackColorW70020.copyWith(
                color: const Color.fromRGBO(235, 87, 87, 1),
              ),
            ),
            Dimens.boxHeight10,
          ],
        ),
      ),
      backgroundColor: const Color.fromRGBO(255, 206, 206, 1),
      isScrollControlled: true,
      isDismissible: isDismissible,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
    ).timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        if (autoDismiss) {
          if (Get.isBottomSheetOpen!) {
            Get.back<void>();
          }
        }
      },
    );
  }

  /// Method For Get Floated Snack Bar
  static void getRawSnackBar(String message, Color backgroundColor) async {
    Get.rawSnackbar(
      message: message,
      mainButton: TextButton(
        onPressed: Get.back,
        child: Text('okay'.tr, style: const TextStyle(color: Colors.white)),
      ),
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(15.0),
      borderRadius: 15,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  // SnackBar
  static void snacBar(String message, Color backgroundColor) async {
    Get.rawSnackbar(
      message: message,
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(15.0),
      borderRadius: 15,
      snackStyle: SnackStyle.FLOATING,
      snackPosition: SnackPosition.TOP,
    );
  }

  // Error Message
  static errorMessage(String message) async {
    return Get.rawSnackbar(
      title: "Error",
      message: message.isNotEmpty ? message : "Internal server error",
      backgroundColor: Colors.red.shade400,
      snackPosition: SnackPosition.TOP,
      icon: const Icon(Icons.error, color: Colors.white70),
      shouldIconPulse: true,
      instantInit: true,
    );
  }

  static copyText(text) {
    Clipboard.setData(ClipboardData(text: text));
    snacBar("Copied to clipboard.", ColorsValue.appColor);
  }

  /// Document Type List For Every Platform
  static List<String> docsTypeList = [
    'zip',
    'txt',
    'rar',
    'pdf',
    'csv',
    'doc',
    'xls',
    'ppt',
    'tar',
    'tar.gz',
    'odp',
    'ods',
    'odt',
    'docx',
    'pptx',
    'xlsx',
    '7z',
  ];

  /// video Type List For Every Platform
  static List<String> videoTypeList = [
    'webm',
    'mkv',
    'flv',
    'vob',
    'ogv',
    'ogg',
    'rrc',
    'gifv',
    'mng',
    'mov',
    'avi',
    'qt',
    'wmv',
    'yuv',
    'rm',
    'asf',
    'amv',
    'mp4',
    'm4p',
    'm4v',
    'mpg',
    'mp2',
    'mpeg',
    'mpe',
    'mpv',
    'm4v',
    'svi',
    '3gp',
    '3g2',
    'mxf',
    'roq',
    'nsv',
    'flv',
    'f4v',
    'f4p',
    'f4a',
    'f4b',
    'mod',
  ];

  /// Image Type List For Every Platform
  static List<String> imageTypeList = [
    'ase',
    'art',
    'bmp',
    'blp',
    'cd5',
    'cit',
    'cpt',
    'cr2',
    'cut',
    'dds',
    'dib',
    'djvu',
    'egt',
    'exif',
    'gif',
    'gpl',
    'grf',
    'icns',
    'ico',
    'iff',
    'jng',
    'jpeg',
    'jpg',
    'jfif',
    'jp2',
    'jps',
    'lbm',
    'max',
    'miff',
    'mng',
    'msp',
    'nitf',
    'ota',
    'pbm',
    'pc1',
    'pc2',
    'pc3',
    'pcf',
    'pcx',
    'pdn',
    'pgm',
    'PI1',
    'PI2',
    'PI3',
    'pict',
    'pct',
    'pnm',
    'pns',
    'ppm',
    'psb',
    'psd',
    'pdd',
    'psp',
    'px',
    'pxm',
    'pxr',
    'qfx',
    'raw',
    'rle',
    'sct',
    'sgi',
    'rgb',
    'int',
    'bw',
    'tga',
    'tiff',
    'tif',
    'vtf',
    'xbm',
    'xcf',
    'xpm',
    '3dv',
    'amf',
    'ai',
    'awg',
    'cgm',
    'cdr',
    'cmx',
    'dxf',
    'e2d',
    'egt',
    'eps',
    'fs',
    'gbr',
    'odg',
    'svg',
    'stl',
    'vrml',
    'x3d',
    'sxd',
    'v2d',
    'vnd',
    'wmf',
    'emf',
    'art',
    'xar',
    'png',
    'webp',
    'jxr',
    'hdp',
    'wdp',
    'cur',
    'ecw',
    'iff',
    'lbm',
    'liff',
    'nrrd',
    'pam',
    'pcx',
    'pgf',
    'sgi',
    'rgb',
    'rgba',
    'bw',
    'int',
    'inta',
    'sid',
    'ras',
    'sun',
    'tga',
  ];

  /// Method For Convert URL to local path and save in local
  static Future<File> imageURLToFile({required String imageUrl}) async {
    // generate random number.
    var rng = Random();
    // get temporary directory of device.
    var tempDir = await getTemporaryDirectory();
    // get temporary path from temporary directory.
    var tempPath = tempDir.path;
    // create a new file in temporary path with random file name.
    var file = File('$tempPath${rng.nextInt(100)}.png');
    // call API client get method and pass imageUrl into it to get response.
    var response = await ApiWrapper.client.get(Uri.parse(imageUrl));
    // write bodyBytes received in response to file.
    await file.writeAsBytes(response.bodyBytes);
    // now return the file which is created with random name in
    // temporary directory and image bytes from response is written to // that file.
    return file;
  }

  /// Method For Image Get URL to Bytes
  static Future<Uint8List> urlToBytes({required String imageURL}) async {
    final data = await NetworkAssetBundle(Uri.parse(imageURL)).load(imageURL);
    final bytes = data.buffer.asUint8List();
    return bytes;
  }

  /// Method For Convert Duration To String
  static String durationToString({required Duration duration}) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    var twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    var twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    var hour = num.parse(twoDigits(duration.inHours));
    if (hour > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  /// Age Calculator Method
  static int calculateAge(DateTime birthDate) {
    var currentDate = DateTime.now();
    var age = currentDate.year - birthDate.year;
    var month1 = currentDate.month;
    var month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      var day1 = currentDate.day;
      var day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  // Get File Extension
  static String getFileExtension(String fileName) {
    try {
      return ".${fileName.split('.').last}";
    } catch (e) {
      return "";
    }
  }

  // Date to get today,yesterday string
  static String dateTimeTodayWithDate(timeDate) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeDate);

    final DateTime dtToday = DateTime.now();
    final DateTime dtYesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );
    final DateFormat formatter = DateFormat("dd-MM-yyyy");
    final DateFormat formatterDateTime = DateFormat("dd,MMMM yyyy hh:mm a");
    final DateFormat timeFormat = DateFormat("hh:mm a");

    return formatter.format(dateTime) == formatter.format(dtToday)
        ? "Today ${timeFormat.format(dateTime)}"
        : formatter.format(dateTime) == formatter.format(dtYesterday)
        ? "Yesterday ${timeFormat.format(dateTime)}"
        : formatterDateTime.format(dateTime);
  }

  // DateTime.now() to enter time minutes get
  static bool timeToNext(sendTime) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(sendTime);

    String timeApi = DateFormat('hh-mm').format(dateTime);
    DateTime currentTime = DateTime.now();

    DateTime targetTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      int.parse(timeApi.split('-').first),
      int.parse(timeApi.split('-').last),
    );

    bool within10Minutes =
        currentTime.isAfter(targetTime.subtract(const Duration(minutes: 10))) &&
        currentTime.isBefore(targetTime.add(const Duration(minutes: 10)));

    return within10Minutes;
  }

  // Date to get today,yesterday string
  static String timestempToTime(int time) {
    var dt = DateTime.fromMillisecondsSinceEpoch(time);

    final todayDate = DateTime.now();

    final today = DateTime(todayDate.year, todayDate.month, todayDate.day);
    final yesterday = DateTime(
      todayDate.year,
      todayDate.month,
      todayDate.day - 1,
    );
    String difference = '';
    final aDate = DateTime(dt.year, dt.month, dt.day);

    if (aDate == today) {
      difference = "Today";
    } else if (aDate == yesterday) {
      difference = "Yesterday";
    } else {
      difference = DateFormat.yMMMd().format(dt).toString();
    }

    return difference;
  }

  // Enter date to time ago time
  static String timeAgo(String d) {
    var date = DateTime.fromMillisecondsSinceEpoch(int.parse(d));
    var d12 = DateFormat('yyyy-MM-ddThh:mm:ss').format(date);

    DateTime dateTime = DateTime.parse(d12);
    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) {
      return "${(diff.inDays / 365).floor()} ${(diff.inDays / 365).floor() == 1 ? "year" : "years"} ago";
    }
    if (diff.inDays > 30) {
      return "${(diff.inDays / 30).floor()} ${(diff.inDays / 30).floor() == 1 ? "month" : "months"} ago";
    }
    if (diff.inDays > 7) {
      return "${(diff.inDays / 7).floor()} ${(diff.inDays / 7).floor() == 1 ? "week" : "weeks"} ago";
    }
    if (diff.inDays > 0) {
      return "${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago";
    }
    if (diff.inHours > 0) {
      return "${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago";
    }
    if (diff.inMinutes > 0) {
      return "${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"} ago";
    }
    return "just now";
  }

  /// Image And Video Permssion Cheack
  static Future<bool> imagePermissionCheack(BuildContext context) async {
    bool status = false;
    bool statusVideos = false;
    bool permanentlyDenied = false;
    bool permanentlyVideoDenied = false;
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        status = await Permission.storage.request().isDenied;
        permanentlyDenied = await Permission.storage
            .request()
            .isPermanentlyDenied;
      } else {
        status = await Permission.photos.request().isDenied;
        permanentlyDenied = await Permission.photos
            .request()
            .isPermanentlyDenied;
        statusVideos = await Permission.videos.request().isDenied;
        permanentlyVideoDenied = await Permission.videos
            .request()
            .isPermanentlyDenied;
      }
    } else {
      status = await Permission.photos.request().isDenied;
      permanentlyDenied = await Permission.photos.request().isPermanentlyDenied;
    }
    if (status || permanentlyDenied || statusVideos || permanentlyVideoDenied) {
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Photos Permission for uploading the image.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  /// Camera Permission Chan
  static Future<bool> cameraPermissionCheack(BuildContext context) async {
    final bool status;
    bool permanentlyDenied;
    status = await Permission.camera.request().isDenied;
    permanentlyDenied = await Permission.camera.request().isPermanentlyDenied;
    if (status || permanentlyDenied) {
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Camera Permission for capture image.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  /// Audio Permission
  static Future<bool> audioPermissionCheack(BuildContext context) async {
    final bool status;
    bool permanentlyDenied;
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        status = await Permission.storage.request().isDenied;
        permanentlyDenied = await Permission.storage
            .request()
            .isPermanentlyDenied;
      } else {
        status = await Permission.audio.request().isDenied;
        permanentlyDenied = await Permission.audio
            .request()
            .isPermanentlyDenied;
      }
    } else {
      status = await Permission.microphone.request().isDenied;
      permanentlyDenied = await Permission.microphone
          .request()
          .isPermanentlyDenied;
    }
    if (status || permanentlyDenied) {
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Audio Permission for uploading the audio.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  /// Microphone Permission
  static Future<bool> microphonePermissionCheack(BuildContext context) async {
    final bool status;
    bool permanentlyDenied;
    status = await Permission.microphone.request().isDenied;
    permanentlyDenied = await Permission.microphone
        .request()
        .isPermanentlyDenied;
    // }
    if (status || permanentlyDenied) {
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Microphone Permission for voice call.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  /// FilePicker Permission
  static Future<bool> filePickPermissionCheack() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final bool status;
    bool permanentlyDenied;
    if (Platform.isIOS) {
      status = await Permission.storage.request().isDenied;
      permanentlyDenied = await Permission.storage
          .request()
          .isPermanentlyDenied;
    } else {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt < 33) {
        status = await Permission.storage.request().isDenied;
        permanentlyDenied = await Permission.storage
            .request()
            .isPermanentlyDenied;
      } else {
        status = await Permission.photos.request().isDenied;
        permanentlyDenied = await Permission.photos
            .request()
            .isPermanentlyDenied;
      }
    }
    if (status || permanentlyDenied) {
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Storage Permission for uploading the File.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  /// Location Permission
  static Future<bool> locationPermissionCheack() async {
    final status = await Permission.locationWhenInUse.request().isDenied;
    var permanentlyDenied = await Permission.locationWhenInUse
        .request()
        .isPermanentlyDenied;
    if (status || permanentlyDenied) {
      // ignore: use_build_context_synchronously
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Location Permission for Current Location.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  /// Contact Permission
  static Future<bool> contactPermissionCheack() async {
    final status = await Permission.contacts.request().isDenied;
    var permanentlyDenied = await Permission.contacts
        .request()
        .isPermanentlyDenied;
    if (status || permanentlyDenied) {
      // ignore: use_build_context_synchronously
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Contacts Permission for get contact.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  /// Notification Permission
  static Future<bool> notificationPermissionCheack() async {
    final status = await Permission.notification.request().isDenied;
    var permanentlyDenied = await Permission.notification
        .request()
        .isPermanentlyDenied;
    if (status || permanentlyDenied) {
      // ignore: use_build_context_synchronously
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: Text("Permission Needed!", style: Styles.black50018),
          content: Text(
            "Please give the Notification Permission for notification.",
            style: Styles.redColor50014,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Allow", style: Styles.redColor50014),
              onPressed: () async {
                Get.back();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Deny", style: Styles.black50014),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  // Image Fix Size Upload
  static double getImageSizeMB(String filePath) {
    var file = File(filePath);
    final bytes = file.readAsBytesSync().lengthInBytes;
    final kb = bytes / 1024;
    final mb = kb / 1024;
    return mb;
  }

  static Timer? timer;

  static showTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 3), () {
      timer?.cancel();
    });
  }

  static showTimerCancle() {
    timer?.cancel();
  }

  //DownloadPdfFile and Save
  static Future<void> downloadAndSavePDF(
    String url,
    String folderName,
    int invoiceNo,
  ) async {
    // late AwesomeNotifications awesomeNotifications = AwesomeNotifications();
    String fileName = url.split('/').last;

    final response = await ApiWrapper.client.get(
      Uri.parse(ApiWrapper.imageUrl + url),
    );
    Directory? appDocumentsDirectory;
    if (response.statusCode == 200) {
      if (Platform.isAndroid) {
        appDocumentsDirectory = Directory("/storage/emulated/0/Download");
      } else {
        appDocumentsDirectory = await getApplicationDocumentsDirectory();
      }

      String folderPath = '${appDocumentsDirectory.path}/$folderName';
      await Directory(folderPath).create(recursive: true);

      String filePath = '$folderPath/$fileName';
      File pdfFile = File(filePath);
      await pdfFile.writeAsBytes(Uint8List.fromList(response.bodyBytes));

      // awesomeNotifications.createNotification(
      //   content: NotificationContent(
      //       id: invoiceNo,
      //       channelKey: "high_importance_channel",
      //       title: fileName.split(".").first,
      //       payload: {"pdf_url": url},
      //       body: "$fileName successfully downloaded."),
      // );

      // AwesomeNotifications().setListeners(
      //   onActionReceivedMethod: (receivedAction) async {
      //     if (receivedAction.payload != null) {
      //       launchUrl(Uri.parse(ApiWrapper.imageUrl + url));
      //     }
      //   },
      // );
    } else {
      print('Failed to download PDF. Status code: ${response.statusCode}');
    }
  }

  static const MethodChannel _nativeChannel = MethodChannel('com.bambam.driver/overlay');

  /// Saves file bytes directly into the public Downloads directory using Android MediaStore
  static Future<bool> saveBytesToPublicDownloads({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? url,
  }) async {
    bool saved = false;

    // 1. Android MediaStore Downloads & DownloadManager
    if (Platform.isAndroid) {
      try {
        final res = await _nativeChannel.invokeMethod('saveToDownloads', {
          'bytes': bytes,
          'fileName': fileName,
          'mimeType': mimeType,
        });
        if (res != null) {
          saved = true;
          debugPrint("Saved to MediaStore Downloads: $res");
        }
      } catch (e) {
        debugPrint("Error in native saveToDownloads: $e");
      }

      // Also trigger DownloadManager notification if URL exists
      if (url != null && url.isNotEmpty) {
        try {
          await _nativeChannel.invokeMethod('startDownloadManager', {
            'url': url,
            'fileName': fileName,
            'mimeType': mimeType,
          });
        } catch (e) {
          debugPrint("Error in startDownloadManager: $e");
        }
      }
    }

    // 2. Direct Downloads directory attempt (fallback for permissions / iOS)
    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir != null) {
        final file = File('${targetDir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        saved = true;
      }
    } catch (e) {
      debugPrint("Fallback file write error: $e");
    }

    return saved;
  }
}
