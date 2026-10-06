import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/app/widgets/verification_dialogs.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_driver/domain/repositories/repository.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bam_bam_driver/domain/services/socket_connection.dart';

class ProfileController extends GetxController {
  ProfileController(this.profilePresenter);

  final ProfilePresenter profilePresenter;

  // Profile payload from server
  Map<String, dynamic>? profile;

  // Stepper state (0 to 5, total 6 steps)
  int currentStep = 0;
  final int totalSteps = 6;

  bool get isCompanyDriver {
    try {
      final repo = Get.find<Repository>();
      final String stored = repo.getStringValue(LocalKeys.loginType).toLowerCase().trim();
      if (stored == 'individual') return false;
      if (stored == 'company') return true;

      // Check HomeController if registered
      if (Get.isRegistered<HomeController>()) {
        final homeType = Get.find<HomeController>().loginType.toLowerCase().trim();
        if (homeType == 'individual') return false;
        if (homeType == 'company') return true;
      }

      // Check TripController if registered
      if (Get.isRegistered<TripController>()) {
        final tripType = Get.find<TripController>().loginType.toLowerCase().trim();
        if (tripType == 'individual') return false;
        if (tripType == 'company') return true;
      }

      // Check profile login_type
      final pLoginType = profile?['login_type']?.toString().toLowerCase().trim();
      if (pLoginType == 'individual') return false;
      if (pLoginType == 'company') return true;

      // Check userDetails
      final userDetailsStr = repo.getStringValue(LocalKeys.userDetails);
      if (userDetailsStr.isNotEmpty) {
        final ud = jsonDecode(userDetailsStr);
        if (ud is Map) {
          final udLoginType = ud['login_type']?.toString().toLowerCase().trim();
          if (udLoginType == 'individual') return false;
          if (udLoginType == 'company') return true;
        }
      }
    } catch (_) {}
    return false;
  }

  int get currentRegisterStep => currentStep;
  GlobalKey<FormState> get registerKey => saveKey;
  bool get isRegistering => isUpdating;
  bool get isCheckingMobile => false;
  String? get mobileAlreadyExistsError => null;

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      currentStep++;
      update();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      update();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep = step;
      update();
    }
  }

  void goToPreviousStep() {
    if (currentStep > 0) {
      currentStep--;
      update();
    } else {
      Get.back();
    }
  }

  /// 🚦 Validate current step before proceeding to next step or submitting
  bool validateCurrentStep() {
    if (currentStep == 0) {
      // Step 0: Personal Information & Location
      final bool hasPhoto = (driverPhotoPath != null && driverPhotoPath!.isNotEmpty) || driverPhotoUrl.isNotEmpty;
      if (!hasPhoto) {
        Utility.showMessage("Driver profile photo is required", MessageType.error, null, "OK");
        return false;
      }
      if (fullNameController.text.trim().length < 3) {
        Utility.showMessage("Driver name must be at least 3 characters", MessageType.error, null, "OK");
        return false;
      }
      if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNumberController.text.trim())) {
        Utility.showMessage("Enter valid 10-digit mobile number", MessageType.error, null, "OK");
        return false;
      }
      if (dobController.text.trim().isEmpty) {
        Utility.showMessage("Please select Date of Birth", MessageType.error, null, "OK");
        return false;
      }
      if (addressSelectionType == "manual") {
        if (addressController.text.trim().length < 5) {
          Utility.showMessage("Please enter street address", MessageType.error, null, "OK");
          return false;
        }
        if (!RegExp(r'^[0-9]{6}$').hasMatch(pinCodeController.text.trim())) {
          Utility.showMessage("Enter valid 6-digit pincode", MessageType.error, null, "OK");
          return false;
        }
      } else {
        if (addressController.text.trim().isEmpty) {
          Utility.showMessage("Please detect GPS location or enter address", MessageType.error, null, "OK");
          return false;
        }
      }
      if (selectedState == null || selectedState!.trim().isEmpty) {
        Utility.showMessage("Please select State", MessageType.error, null, "OK");
        return false;
      }
      if (selectedCity == null || selectedCity!.trim().isEmpty) {
        Utility.showMessage("Please select City", MessageType.error, null, "OK");
        return false;
      }
      return true;
    } else if (currentStep == 1) {
      // Step 1: Driving License & Experience
      final bool hasDlPhoto = (dlPhotoPath != null && dlPhotoPath!.isNotEmpty) || dlPhotoUrl.isNotEmpty;
      if (!hasDlPhoto) {
        Utility.showMessage("Driving license image is required", MessageType.error, null, "OK");
        return false;
      }
      if (dlNumberController.text.trim().isEmpty) {
        Utility.showMessage("Enter Driving License number", MessageType.error, null, "OK");
        return false;
      }
      if (!isDlVerified) {
        Utility.showMessage("Please verify your Driving License first", MessageType.error, null, "OK");
        return false;
      }
      if (dlIssueController.text.trim().isEmpty) {
        Utility.showMessage("Select Driving License issue date", MessageType.error, null, "OK");
        return false;
      }
      if (dlExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Select Driving License expiry date", MessageType.error, null, "OK");
        return false;
      }
      if (selectedLanguageIds.isEmpty) {
        Utility.showMessage("Please select at least one language", MessageType.error, null, "OK");
        return false;
      }
      if (selectedVehicleIds.isEmpty) {
        Utility.showMessage("Please select at least one vehicle type you can drive", MessageType.error, null, "OK");
        return false;
      }
      return true;
    } else if (currentStep == 2) {
      // Step 2: Identity Documents (KYC)
      final aadharClean = aadharController.text.trim().replaceAll(' ', '');
      if (aadharClean.length != 12) {
        Utility.showMessage("Aadhaar number must be exactly 12 digits", MessageType.error, null, "OK");
        return false;
      }
      if (!isAadhaarVerified) {
        Utility.showMessage("Please verify your Aadhaar Card with OTP first", MessageType.error, null, "OK");
        return false;
      }
      final bool hasAadharFront = (aadharFrontPath != null && aadharFrontPath!.isNotEmpty) || aadharFrontUrl.isNotEmpty;
      if (!hasAadharFront) {
        Utility.showMessage("Aadhaar front image is required", MessageType.error, null, "OK");
        return false;
      }
      final bool hasAadharBack = (aadharBackPath != null && aadharBackPath!.isNotEmpty) || aadharBackUrl.isNotEmpty;
      if (!hasAadharBack) {
        Utility.showMessage("Aadhaar back image is required", MessageType.error, null, "OK");
        return false;
      }
      final panText = panController.text.trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(panText)) {
        Utility.showMessage("Enter valid PAN format (e.g. ABCDE1234F)", MessageType.error, null, "OK");
        return false;
      }
      if (!isPanVerified) {
        Utility.showMessage("Please verify your PAN Card first", MessageType.error, null, "OK");
        return false;
      }
      final bool hasPanPhoto = (panPhotoPath != null && panPhotoPath!.isNotEmpty) || panPhotoUrl.isNotEmpty;
      if (!hasPanPhoto) {
        Utility.showMessage("PAN card photo is required", MessageType.error, null, "OK");
        return false;
      }
      // Note: GST, Address Proof & Visiting Card are optional - never block moving next
      return true;
    } else if (currentStep == 3) {
      // Step 3: Bank Details
      if (ifscCodeController.text.trim().isEmpty) {
        Utility.showMessage("Please enter IFSC code", MessageType.error, null, "OK");
        return false;
      }
      if (!isBankVerified) {
        Utility.showMessage("Please verify your IFSC Code first", MessageType.error, null, "OK");
        return false;
      }
      if (bankNameController.text.trim().isEmpty) {
        Utility.showMessage("Bank name is required", MessageType.error, null, "OK");
        return false;
      }
      if (branchNameController.text.trim().isEmpty) {
        Utility.showMessage("Branch name is required", MessageType.error, null, "OK");
        return false;
      }
      if (accountNumberController.text.trim().length < 8) {
        Utility.showMessage("Enter valid bank account number", MessageType.error, null, "OK");
        return false;
      }
      if (accountHolderNameController.text.trim().isEmpty) {
        Utility.showMessage("Account holder name is required", MessageType.error, null, "OK");
        return false;
      }
      final bool hasPassbook = (passbookPhotoPath != null && passbookPhotoPath!.isNotEmpty) || passbookPhotoUrl.isNotEmpty;
      if (!hasPassbook) {
        Utility.showMessage("Please upload Bank Passbook or Cheque photo", MessageType.error, null, "OK");
        return false;
      }
      // Note: UPI ID is optional - never block moving next
      return true;
    } else if (currentStep == 4) {
      // Step 4: Vehicle Information & Statutory Documents
      if (rcNumberController.text.trim().isEmpty) {
        Utility.showMessage("RC number is required", MessageType.error, null, "OK");
        return false;
      }
      if (!isRcVerified) {
        Utility.showMessage("Please verify RC Number first", MessageType.error, null, "OK");
        return false;
      }
      if (brandNameController.text.trim().isEmpty) {
        Utility.showMessage("Vehicle brand/make is required", MessageType.error, null, "OK");
        return false;
      }
      if (vehiclesList.isNotEmpty && (selectedVehicleType == null || selectedVehicleType!.isEmpty)) {
        Utility.showMessage("Please select Vehicle Type", MessageType.error, null, "OK");
        return false;
      }
      if (vehicleNumberController.text.trim().isEmpty) {
        Utility.showMessage("Vehicle registration number is required", MessageType.error, null, "OK");
        return false;
      }
      if (fuelTypeDropdownList.isNotEmpty && (selectedFuelType == null || selectedFuelType!.isEmpty)) {
        Utility.showMessage("Please select Fuel Type", MessageType.error, null, "OK");
        return false;
      }
      if (makeYearController.text.trim().isEmpty) {
        Utility.showMessage("Vehicle make year is required", MessageType.error, null, "OK");
        return false;
      }
      final bool hasRentedAgreement = (rentedAgreementPath != null && rentedAgreementPath!.isNotEmpty) || rentedAgreementUrl.isNotEmpty;
      if (selectedSourcing == "Rented Vehicle" && !hasRentedAgreement) {
        Utility.showMessage("Rental Agreement is required for rented vehicle", MessageType.error, null, "OK");
        return false;
      }
      final bool hasRcPhoto = (rcPhotoPath != null && rcPhotoPath!.isNotEmpty) || rcPhotoUrl.isNotEmpty;
      if (!hasRcPhoto) {
        Utility.showMessage("RC document photo is required", MessageType.error, null, "OK");
        return false;
      }
      if (insuranceExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Please select Insurance Expiry Date", MessageType.error, null, "OK");
        return false;
      }
      final bool hasInsuranceDoc = (insuranceDocumentPath != null && insuranceDocumentPath!.isNotEmpty) || insuranceDocumentUrl.isNotEmpty;
      if (!hasInsuranceDoc) {
        Utility.showMessage("Insurance Policy Document is required", MessageType.error, null, "OK");
        return false;
      }
      if (fitnessExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Please select Fitness Expiry Date", MessageType.error, null, "OK");
        return false;
      }
      final bool hasFitnessDoc = (fitnessDocumentPath != null && fitnessDocumentPath!.isNotEmpty) || fitnessDocumentUrl.isNotEmpty;
      if (!hasFitnessDoc) {
        Utility.showMessage("Fitness Certificate Document is required", MessageType.error, null, "OK");
        return false;
      }
      if (permitExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Please select Permit Expiry Date", MessageType.error, null, "OK");
        return false;
      }
      final bool hasPermitDoc = (permitDocumentPath != null && permitDocumentPath!.isNotEmpty) || permitDocumentUrl.isNotEmpty;
      if (!hasPermitDoc) {
        Utility.showMessage("Permit Document is required", MessageType.error, null, "OK");
        return false;
      }
      final bool hasPucDoc = (pucDocumentPath != null && pucDocumentPath!.isNotEmpty) || pucDocumentUrl.isNotEmpty;
      if (!hasPucDoc) {
        Utility.showMessage("PUC Document is required", MessageType.error, null, "OK");
        return false;
      }
      return true;
    } else if (currentStep == 5) {
      // Step 5: Vehicle Images
      final bool hasFront = (vehicleFrontPhotoPath != null && vehicleFrontPhotoPath!.isNotEmpty) || vehicleFrontPhotoUrl.isNotEmpty;
      final bool hasBack = (vehicleBackPhotoPath != null && vehicleBackPhotoPath!.isNotEmpty) || vehicleBackPhotoUrl.isNotEmpty;
      if (!hasFront || !hasBack) {
        Utility.showMessage("Vehicle Front & Back photos are required", MessageType.error, null, "OK");
        return false;
      }
      final bool hasPlate = (vehicleNumberPlatePhotoPath != null && vehicleNumberPlatePhotoPath!.isNotEmpty) || vehicleNumberPlatePhotoUrl.isNotEmpty;
      if (!hasPlate) {
        Utility.showMessage("Vehicle Number Plate photo is required", MessageType.error, null, "OK");
        return false;
      }
      final bool hasCarrier = (vehicleCarrierPhotoPath != null && vehicleCarrierPhotoPath!.isNotEmpty) || vehicleCarrierPhotoUrl.isNotEmpty;
      if (luggageCarrier == "Yes" && !hasCarrier) {
        Utility.showMessage("Roof Luggage Carrier photo is required", MessageType.error, null, "OK");
        return false;
      }
      return true;
    }
    return true;
  }

  void goToNextStep() {
    if (!validateCurrentStep()) return;

    if (currentStep < totalSteps - 1) {
      currentStep++;
      update();
    } else {
      updateProfile();
    }
  }

  // Form key & controllers
  GlobalKey<FormState> saveKey = GlobalKey<FormState>();

  // Search controllers for searchable bottom sheets
  final TextEditingController stateSearchController = TextEditingController();
  final TextEditingController citySearchController = TextEditingController();
  final TextEditingController languageSearchController = TextEditingController();
  final TextEditingController vehicleSearchController = TextEditingController();

  // Location & State/City loading
  String addressSelectionType = "manual"; // "current_location" or "manual"
  bool isFetchingLocation = false;
  bool isStatesLoading = false;
  bool isCitiesLoading = false;
  String? detectedLocationDisplay;
  double? currentLat;
  double? currentLng;

  void setAddressSelectionType(String type) {
    addressSelectionType = type;
    update();
  }

  // ─── STEP 0: Personal Information ─────────────────────────────────────────
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  String selectedGender = "Male"; // Male, Female, Other
  TextEditingController addressController = TextEditingController();
  String? selectedState;
  String? selectedCity;
  TextEditingController pinCodeController = TextEditingController();
  String? driverPhotoPath;
  String driverPhotoUrl = '';

  TextEditingController get registerNameController => fullNameController;
  TextEditingController get registerMobileController => phoneNumberController;
  TextEditingController get registerDobController => dobController;
  TextEditingController get registerAddressController => addressController;
  TextEditingController get registerPinCodeController => pinCodeController;
  String? get selectedRegisterState => selectedState;
  set selectedRegisterState(String? val) => selectedState = val;
  String? get selectedRegisterCity => selectedCity;
  set selectedRegisterCity(String? val) => selectedCity = val;

  List<String> genderList = ["Male", "Female", "Other"];
  List<Map<String, String>> statesList = [];
  List<Map<String, String>> citiesList = [];
  List<String> cityList = ["Surat", "Ahmedabad", "Vadodara", "Rajkot", "Bharuch", "Navsari", "Vapi"];

  // ─── STEP 1: Driving License & Skills ──────────────────────────────────────
  TextEditingController dlNumberController = TextEditingController();
  TextEditingController dlIssueController = TextEditingController();
  TextEditingController dlExpiryController = TextEditingController();
  String? dlPhotoPath;
  String dlPhotoUrl = '';
  String? dlBackPhotoPath;
  String dlBackPhotoUrl = '';
  bool isDlVerified = false;
  bool isDlVerifying = false;

  List<Map<String, String>> languagesList = [];
  List<String> selectedLanguageIds = [];

  List<Map<String, String>> vehiclesList = [];
  List<String> selectedVehicleIds = [];

  // ─── STEP 2: Identity Documents (KYC) ─────────────────────────────────────
  TextEditingController aadharController = TextEditingController();
  String? aadharFrontPath;
  String aadharFrontUrl = '';
  String? aadharBackPath;
  String aadharBackUrl = '';
  bool isAadhaarVerified = false;
  bool isAadhaarVerifying = false;
  String aadhaarRefId = '';
  bool isAadhaarOtpVerifying = false;
  bool isAadhaarOtpResending = false;

  TextEditingController panController = TextEditingController();
  String? panPhotoPath;
  String panPhotoUrl = '';
  bool isPanVerified = false;
  bool isPanVerifying = false;

  TextEditingController gstNumberController = TextEditingController();
  String? gstCertificatePhotoPath;
  String gstCertificatePhotoUrl = '';
  String? visitingCardPhotoPath;
  String visitingCardPhotoUrl = '';
  bool isGstVerified = false;
  bool isGstVerifying = false;

  String selectedAddressProofType = "Light Bill"; // Light Bill, Rent Agreement, Phone Bill
  List<String> addressProofTypes = ["Light Bill", "Rent Agreement", "Phone Bill"];
  TextEditingController addressProofNumberController = TextEditingController();
  String? addressProofDocumentPath;
  String addressProofDocumentUrl = '';

  // Police Criminal Certificate (PCC) - Optional
  TextEditingController pccNumberController = TextEditingController();
  String? pccCertificatePath;
  String pccCertificateUrl = '';

  // ─── STEP 3: Bank Details ──────────────────────────────────────────────────
  TextEditingController accountHolderNameController = TextEditingController();
  TextEditingController bankNameController = TextEditingController();
  TextEditingController branchNameController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController confirmAccountNumberController = TextEditingController();
  TextEditingController ifscCodeController = TextEditingController();
  TextEditingController upiIdController = TextEditingController();
  String? passbookPhotoPath;
  String passbookPhotoUrl = '';
  bool isBankVerified = false;
  bool isBankVerifying = false;

  // ─── STEP 4: Vehicle & Statutory Details ──────────────────────────────────
  TextEditingController brandNameController = TextEditingController();
  TextEditingController vehicleNumberController = TextEditingController();
  TextEditingController makeYearController = TextEditingController();
  List<Map<String, String>> vehicleTypeDropdownList = [];
  String? selectedVehicleType;
  List<Map<String, String>> fuelTypeDropdownList = [];
  String? selectedFuelType;

  String selectedSourcing = "Owner Vehicle";
  List<String> sourcingList = ["Owner Vehicle", "Rented Vehicle", "Company Vehicle"];

  String petFriendly = "No";
  String luggageCarrier = "No";
  String rearSeatBelts = "No";
  String selectedPermitType = "State Permit";
  List<String> permitTypes = ["State Permit", "National Permit / All India Tourist Permit", "Local Permit"];

  TextEditingController rcNumberController = TextEditingController();
  String? rcPhotoPath;
  String rcPhotoUrl = '';
  bool isRcVerified = false;
  bool isRcVerifying = false;

  TextEditingController insuranceExpiryController = TextEditingController();
  String? insuranceDocumentPath;
  String insuranceDocumentUrl = '';

  TextEditingController fitnessExpiryController = TextEditingController();
  String? fitnessDocumentPath;
  String fitnessDocumentUrl = '';

  TextEditingController permitExpiryController = TextEditingController();
  String? permitDocumentPath;
  String permitDocumentUrl = '';

  String? pucDocumentPath;
  String pucDocumentUrl = '';

  String? rentedAgreementPath;
  String rentedAgreementUrl = '';
  String bambamRentAgreementUrl = '';
  bool isDownloadingAgreement = false;

  // ─── STEP 5: Vehicle Photos ───────────────────────────────────────────────
  String? vehicleFrontPhotoPath;
  String vehicleFrontPhotoUrl = '';
  String? vehicleBackPhotoPath;
  String vehicleBackPhotoUrl = '';
  String? vehicleLeftPhotoPath;
  String vehicleLeftPhotoUrl = '';
  String? vehicleRightPhotoPath;
  String vehicleRightPhotoUrl = '';
  String? vehicleInteriorPhotoPath;
  String vehicleInteriorPhotoUrl = '';
  String? vehicleNumberPlatePhotoPath;
  String vehicleNumberPlatePhotoUrl = '';
  String? vehicleDickyPhotoPath;
  String vehicleDickyPhotoUrl = '';
  String? vehicleCarrierPhotoPath;
  String vehicleCarrierPhotoUrl = '';

  // Aliases for Steps 1-5 matching register_screen layout
  TextEditingController get registerDlNumberController => dlNumberController;
  TextEditingController get registerDlIssueController => dlIssueController;
  TextEditingController get registerDlExpiryController => dlExpiryController;

  TextEditingController get registerAadharController => aadharController;
  String? get aadharPhotoPath => aadharFrontPath;
  set aadharPhotoPath(String? v) => aadharFrontPath = v;
  String? get aadharBackPhotoPath => aadharBackPath;
  set aadharBackPhotoPath(String? v) => aadharBackPath = v;
  TextEditingController get registerPanController => panController;
  TextEditingController get registerGstNumberController => gstNumberController;

  TextEditingController get registerIfscController => ifscCodeController;
  TextEditingController get registerBankNameController => bankNameController;
  TextEditingController get registerBranchNameController => branchNameController;
  TextEditingController get registerAccountNumberController => accountNumberController;
  TextEditingController get registerAccountHolderController => accountHolderNameController;
  TextEditingController get registerUpiController => upiIdController;

  TextEditingController get registerRcNumberController => rcNumberController;
  TextEditingController get registerVehicleMakeController => brandNameController;
  TextEditingController get registerVehicleNumberController => vehicleNumberController;
  TextEditingController get registerVehicleMakeYearController => makeYearController;
  String get permitType => selectedPermitType;
  set permitType(String v) => selectedPermitType = v;
  TextEditingController get registerInsuranceExpiryController => insuranceExpiryController;
  TextEditingController get registerFitnessExpiryController => fitnessExpiryController;
  TextEditingController get registerPermitExpiryController => permitExpiryController;
  String? get rentedVehicleAgreementPath => rentedAgreementPath;
  set rentedVehicleAgreementPath(String? v) => rentedAgreementPath = v;

  Future<void> pickAadharPhoto() => pickAadharFront();
  Future<void> pickAadharBackPhoto() => pickAadharBack();
  Future<void> pickRentedVehicleAgreement() => pickRentedAgreement();
  Future<void> pickVehicleFrontPhoto() => pickVehicleFront();
  Future<void> pickVehicleBackPhoto() => pickVehicleBack();
  Future<void> pickVehicleLeftPhoto() => pickVehicleLeft();
  Future<void> pickVehicleRightPhoto() => pickVehicleRight();
  Future<void> pickVehicleInteriorPhoto() => pickVehicleInterior();
  Future<void> pickVehicleNumberPlatePhoto() => pickVehicleNumberPlate();
  Future<void> pickVehicleDickyPhoto() => pickVehicleDicky();
  Future<void> pickVehicleCarrierPhoto() => pickVehicleCarrier();

  List<dynamic> get filteredStates {
    final q = stateSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return statesList;
    return statesList.where((s) {
      final name = (s is Map ? (s['name'] ?? s['state_name']) : s).toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  List<dynamic> get filteredCities {
    final q = citySearchController.text.trim().toLowerCase();
    if (q.isEmpty) return citiesList;
    return citiesList.where((c) {
      final name = (c is Map ? (c['name'] ?? c['city_name'] ?? c['city']) : c).toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  List<Map<String, String>> get filteredLanguages {
    final q = languageSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return languagesList;
    return languagesList.where((l) => (l['name'] ?? '').toLowerCase().contains(q)).toList();
  }

  List<Map<String, String>> get filteredVehicles {
    final q = vehicleSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return vehiclesList;
    return vehiclesList.where((v) => (v['name'] ?? '').toLowerCase().contains(q)).toList();
  }

  String get selectedLanguageNamesText {
    return languagesList
        .where((l) => selectedLanguageIds.contains(l['id']))
        .map((l) => l['name'] ?? '')
        .join(', ');
  }

  String get selectedVehicleNamesText {
    return vehiclesList
        .where((v) => selectedVehicleIds.contains(v['id']))
        .map((v) => v['name'] ?? '')
        .join(', ');
  }

  // State
  bool isLoadingProfile = false;
  bool isUpdating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    fetchMasterData();
  }

  String _fullUrl(String? key) {
    if (key == null || key.isEmpty) return '';
    if (key.startsWith('http')) return key;
    return ApiWrapper.imageUrl + key;
  }

  /// Master data loaders
  Future<void> fetchMasterData() async {
    // 1. Vehicle Types
    try {
      final res = await profilePresenter.getVehicleTypes();
      if (!res.hasError) {
        final body = jsonDecode(res.data);
        final list = (body['Data'] ?? body['data'] ?? []) as List;
        vehicleTypeDropdownList = list.map((item) {
          return {
            'id': (item['_id'] ?? '').toString(),
            'name': (item['name'] ?? '').toString(),
          };
        }).toList();
        vehiclesList = List.from(vehicleTypeDropdownList);
      }
    } catch (_) {}

    // 2. Fuel Types
    try {
      final res = await profilePresenter.getFuelTypes();
      if (!res.hasError) {
        final body = jsonDecode(res.data);
        final list = (body['Data'] ?? body['data'] ?? []) as List;
        fuelTypeDropdownList = list.map((item) {
          return {
            'id': (item['_id'] ?? '').toString(),
            'name': (item['name'] ?? item['fuel_type'] ?? '').toString(),
          };
        }).toList();
      }
    } catch (_) {}

    // 3. Languages
    try {
      final res = await profilePresenter.getLanguages();
      if (!res.hasError) {
        final body = jsonDecode(res.data);
        final list = (body['Data'] ?? body['data'] ?? []) as List;
        languagesList = list.map((item) {
          return {
            'id': (item['_id'] ?? '').toString(),
            'name': (item['name'] ?? '').toString(),
          };
        }).toList();
      }
    } catch (_) {}

    // 4. States
    try {
      final res = await profilePresenter.getStates();
      if (!res.hasError) {
        final body = jsonDecode(res.data);
        final list = (body['Data'] ?? body['data'] ?? []) as List;
        statesList = list.map((item) {
          return {
            'code': (item['isoCode'] ?? item['state_code'] ?? item['code'] ?? '').toString(),
            'name': (item['name'] ?? item['state_name'] ?? '').toString(),
          };
        }).toList();
      }
    } catch (_) {}

    update();
  }

  Future<void> fetchStates() async {
    isStatesLoading = true;
    update();
    try {
      final res = await profilePresenter.getStates();
      if (!res.hasError && res.data.isNotEmpty) {
        final body = jsonDecode(res.data);
        final list = body['data'] ?? body['Data'];
        if (list is List && list.isNotEmpty) {
          statesList = list.map<Map<String, String>>((e) => {
            'name': (e['name'] ?? e['state_name'] ?? '').toString(),
            'code': (e['isoCode'] ?? e['code'] ?? '').toString(),
          }).toList();
          statesList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

          if (selectedState != null && selectedState!.isNotEmpty && citiesList.isEmpty) {
            final found = statesList.firstWhere(
              (s) => (s['name'] ?? '').toLowerCase() == selectedState!.toLowerCase(),
              orElse: () => {'name': selectedState!, 'code': ''},
            );
            if ((found['code'] ?? '').isNotEmpty) {
              fetchCitiesForState(found['code']!);
            }
          }
        }
      }
    } catch (_) {} finally {
      isStatesLoading = false;
      update();
    }
  }

  Future<void> fetchCitiesForState(String stateCode) async {
    isCitiesLoading = true;
    update();
    try {
      final res = await profilePresenter.getCities(stateCode);
      if (!res.hasError && res.data.isNotEmpty) {
        final body = jsonDecode(res.data);
        final list = body['data'] ?? body['Data'];
        if (list is List && list.isNotEmpty) {
          citiesList = list.map<Map<String, String>>((e) => {
            'name': (e['name'] ?? e['city_name'] ?? e.toString()).toString(),
          }).toList();
        }
      }
    } catch (_) {} finally {
      isCitiesLoading = false;
      update();
    }
  }

  Future<void> onStateChanged(String stateName, {String? stateCode}) async {
    selectedState = stateName;
    selectedCity = null;
    citiesList = [];
    update();

    String code = stateCode ?? '';
    if (code.isEmpty) {
      final stateObj = statesList.firstWhere(
        (s) => (s['name'] ?? '').toLowerCase() == stateName.toLowerCase(),
        orElse: () => {'code': '', 'name': ''},
      );
      code = stateObj['code'] ?? '';
    }

    if (code.isNotEmpty) {
      await fetchCitiesForState(code);
    }
  }

  /// 📍 Detect driver's current GPS location & reverse geocode
  Future<void> detectCurrentLocation() async {
    try {
      isFetchingLocation = true;
      update();

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Utility.showMessage("Location services are disabled. Please enable GPS in device settings.", MessageType.error, null, "OK");
        isFetchingLocation = false;
        update();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Utility.showMessage("Location permissions are denied.", MessageType.error, null, "OK");
          isFetchingLocation = false;
          update();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Utility.showMessage("Location permissions are permanently denied. Please enable them in app settings.", MessageType.error, null, "OK");
        isFetchingLocation = false;
        update();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      currentLat = position.latitude;
      currentLng = position.longitude;

      final res = await profilePresenter.reverseGeocode(lat: position.latitude, lng: position.longitude);
      if (!res.hasError && res.data.isNotEmpty) {
        final body = jsonDecode(res.data);
        if (body is Map && body.containsKey('Data')) {
          final data = body['Data'];
          final formatted = data['formatted_address']?.toString() ?? "";
          final city = data['city']?.toString() ?? "";
          final state = data['state']?.toString() ?? "";
          final pincode = data['pincode']?.toString() ?? "";

          if (formatted.isNotEmpty) {
            addressController.text = formatted;
            detectedLocationDisplay = formatted;
          }
          if (pincode.isNotEmpty) {
            pinCodeController.text = pincode;
          }
          if (state.isNotEmpty) {
            onStateChanged(state);
          }
          if (city.isNotEmpty) {
            selectedCity = city;
          }
          Utility.showMessage("Location detected successfully!", MessageType.success, null, "OK");
        }
      } else {
        addressController.text = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        detectedLocationDisplay = addressController.text;
        Utility.showMessage("Location coordinates captured!", MessageType.success, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("Failed to detect location: ${e.toString()}", MessageType.error, null, "OK");
    } finally {
      isFetchingLocation = false;
      update();
    }
  }

  /// Fetch profile and populate all 6 steps
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

        String driverId = profile?['_id']?.toString() ?? '';
        if (driverId.isNotEmpty) {
          SocketConnection.updateChannelId(driverId);
        }

        // ─── Step 0: Personal ─────────────────────────
        fullNameController.text = profile?['driver_name']?.toString() ?? '';
        emailController.text = profile?['email']?.toString() ?? '';
        phoneNumberController.text = profile?['driver_mobile']?.toString() ?? '';
        pinCodeController.text = profile?['zip_code']?.toString() ?? '';
        addressController.text = profile?['address']?.toString() ?? '';
        selectedState = profile?['state']?.toString();
        selectedCity = profile?['city']?.toString();
        if (profile?['gender'] != null && profile!['gender'].toString().isNotEmpty) {
          selectedGender = profile!['gender'].toString();
        }

        if (profile?['dob'] != null) {
          try {
            DateTime dt = DateTime.parse(profile!['dob'].toString());
            dobController.text = dt.toIso8601String().split('T').first;
          } catch (_) {
            dobController.text = profile?['dob']?.toString() ?? '';
          }
        }
        driverPhotoUrl = _fullUrl(profile?['driver_photo']?.toString());

        // ─── Step 1: DL & Skills ─────────────────────
        dlNumberController.text = profile?['DL_number']?.toString() ?? '';
        if (dlNumberController.text.isNotEmpty) isDlVerified = true;
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
        dlPhotoUrl = _fullUrl(profile?['DL_photo']?.toString());
        dlBackPhotoUrl = _fullUrl(profile?['DL_back_photo']?.toString());

        selectedLanguageIds = [];
        if (profile?['language_known'] is List) {
          for (var item in profile!['language_known']) {
            if (item is Map) {
              final id = item['_id']?.toString() ?? '';
              if (id.isNotEmpty) selectedLanguageIds.add(id);
            } else if (item is String && item.isNotEmpty) {
              selectedLanguageIds.add(item);
            }
          }
          selectedLanguageIds = selectedLanguageIds.toSet().toList();
        }

        selectedVehicleIds = [];
        if (profile?['vehicales_drive'] is List) {
          for (var item in profile!['vehicales_drive']) {
            if (item is Map) {
              final id = item['_id']?.toString() ?? '';
              if (id.isNotEmpty) selectedVehicleIds.add(id);
            } else if (item is String && item.isNotEmpty) {
              selectedVehicleIds.add(item);
            }
          }
          selectedVehicleIds = selectedVehicleIds.toSet().toList();
        }

        // ─── Step 2: Identity Documents (KYC) ────────
        aadharController.text = profile?['aadhar_number']?.toString() ?? '';
        if (aadharController.text.isNotEmpty) isAadhaarVerified = true;
        aadharFrontUrl = _fullUrl(profile?['aadhar_photo']?.toString());
        aadharBackUrl = _fullUrl(profile?['aadhar_back_photo']?.toString());

        panController.text = profile?['pan_number']?.toString() ?? '';
        if (panController.text.isNotEmpty) isPanVerified = true;
        panPhotoUrl = _fullUrl(profile?['pan_photo']?.toString());

        gstNumberController.text = profile?['gst_number']?.toString() ?? '';
        if (gstNumberController.text.isNotEmpty) isGstVerified = true;
        gstCertificatePhotoUrl = _fullUrl(profile?['gst_certificate']?.toString());
        visitingCardPhotoUrl = _fullUrl(profile?['visiting_card']?.toString());

        if (profile?['address_proof_type'] != null && profile!['address_proof_type'].toString().isNotEmpty) {
          selectedAddressProofType = profile!['address_proof_type'].toString();
        }
        addressProofNumberController.text = profile?['address_proof_number']?.toString() ?? '';
        addressProofDocumentUrl = _fullUrl(profile?['address_proof_document']?.toString());
        pccNumberController.text = profile?['pcc_number']?.toString() ?? '';
        pccCertificateUrl = _fullUrl(profile?['pcc_certificate']?.toString());

        // ─── Step 3: Bank Details ────────────────────
        final bank = (profile?['bank_details'] is Map) ? profile!['bank_details'] : {};
        accountHolderNameController.text = bank['account_holder_name']?.toString() ?? '';
        bankNameController.text = bank['bank_name']?.toString() ?? '';
        branchNameController.text = bank['branch_name']?.toString() ?? '';
        accountNumberController.text = bank['account_number']?.toString() ?? '';
        confirmAccountNumberController.text = bank['account_number']?.toString() ?? '';
        ifscCodeController.text = bank['ifsc_code']?.toString() ?? '';
        upiIdController.text = bank['upi_id']?.toString() ?? '';
        passbookPhotoUrl = _fullUrl(bank['passbook_photo']?.toString());
        if (accountNumberController.text.isNotEmpty && ifscCodeController.text.isNotEmpty) {
          isBankVerified = true;
        }

        // ─── Step 4 & 5: Vehicle & Statutory Details ─
        final veh = (profile?['vehicle_details'] is Map)
            ? profile!['vehicle_details']
            : ((profile?['vehicle'] is Map) ? profile!['vehicle'] : {});

        brandNameController.text = (veh['brand_name'] ?? veh['make'] ?? '').toString();
        vehicleNumberController.text = (veh['vehicle_number'] ?? veh['registration_number'] ?? '').toString();
        rcNumberController.text = vehicleNumberController.text;
        if (vehicleNumberController.text.isNotEmpty) isRcVerified = true;

        makeYearController.text = (veh['vehicle_make_year'] ?? veh['model'] ?? '').toString();

        if (veh['vehicle_type'] != null) {
          if (veh['vehicle_type'] is Map) {
            selectedVehicleType = veh['vehicle_type']['_id']?.toString();
          } else {
            selectedVehicleType = veh['vehicle_type']?.toString();
          }
        }
        if (veh['fuel_type'] != null) {
          if (veh['fuel_type'] is List && (veh['fuel_type'] as List).isNotEmpty) {
            selectedFuelType = veh['fuel_type'][0]?.toString();
          } else if (veh['fuel_type'] is Map) {
            selectedFuelType = veh['fuel_type']['_id']?.toString();
          } else {
            selectedFuelType = veh['fuel_type']?.toString();
          }
        }
        if (veh['sourcing'] != null && veh['sourcing'].toString().isNotEmpty) {
          selectedSourcing = veh['sourcing'].toString();
        }
        if (veh['pet_friendly'] != null && veh['pet_friendly'].toString().isNotEmpty) {
          petFriendly = veh['pet_friendly'].toString();
        }
        if (veh['luggage_carrier'] != null && veh['luggage_carrier'].toString().isNotEmpty) {
          luggageCarrier = veh['luggage_carrier'].toString();
        }
        if (veh['working_rear_seat_belts'] != null && veh['working_rear_seat_belts'].toString().isNotEmpty) {
          rearSeatBelts = veh['working_rear_seat_belts'].toString();
        }
        if (veh['permit_type'] != null && veh['permit_type'].toString().isNotEmpty) {
          selectedPermitType = veh['permit_type'].toString();
        }

        insuranceExpiryController.text = _formatDateStr(veh['insurance_expiry']);
        fitnessExpiryController.text = _formatDateStr(veh['fitness_expiry']);
        permitExpiryController.text = _formatDateStr(veh['permit_expiry']);

        rcPhotoUrl = _fullUrl(veh['rc_photo']?.toString() ?? veh['rc_image']?.toString());
        rentedAgreementUrl = _fullUrl(veh['rented_vehicle_agreement']?.toString());
        insuranceDocumentUrl = _fullUrl(veh['insurance_document']?.toString());
        fitnessDocumentUrl = _fullUrl(veh['fitness_document']?.toString());
        permitDocumentUrl = _fullUrl(veh['permit_document']?.toString());
        pucDocumentUrl = _fullUrl(veh['puc_document']?.toString());

        // Vehicle photos
        vehicleFrontPhotoUrl = _fullUrl(veh['front_photo']?.toString() ?? veh['front_image']?.toString());
        vehicleBackPhotoUrl = _fullUrl(veh['back_photo']?.toString() ?? veh['back_image']?.toString());
        vehicleLeftPhotoUrl = _fullUrl(veh['left_photo']?.toString() ?? veh['left_image']?.toString());
        vehicleRightPhotoUrl = _fullUrl(veh['right_photo']?.toString() ?? veh['right_image']?.toString());
        vehicleInteriorPhotoUrl = _fullUrl(veh['interior_photo']?.toString() ?? veh['interior_image']?.toString());
        vehicleNumberPlatePhotoUrl = _fullUrl(veh['number_plate_photo']?.toString() ?? veh['number_plate_image']?.toString());
        vehicleDickyPhotoUrl = _fullUrl(veh['dicky_photo']?.toString() ?? veh['dicky_image']?.toString());
        vehicleCarrierPhotoUrl = _fullUrl(veh['carrier_photo']?.toString() ?? veh['carrier_image']?.toString());

        // Online & Leave Sync
        if (Get.isRegistered<HomeController>()) {
          final hCtrl = Get.find<HomeController>();
          final onlineStatus = profile?['is_online'];
          final leaveStatus = profile?['leave_status'];
          final leaveRemark = profile?['leave_remark'];
          if (onlineStatus is bool) hCtrl.isOnline = onlineStatus;
          if (leaveStatus is bool) hCtrl.isLeave = leaveStatus;
          if (leaveRemark is String) hCtrl.leaveRemark = leaveRemark;
          hCtrl.update();
        }
      }
    } catch (e) {
      Utility.showMessage('Failed to parse profile: $e', MessageType.error, null, 'OK');
    }

    update();
  }

  String _formatDateStr(dynamic d) {
    if (d == null) return '';
    try {
      DateTime dt = DateTime.parse(d.toString());
      return dt.toIso8601String().split('T').first;
    } catch (_) {
      return d.toString();
    }
  }

  // ─── Image Pickers & Popup ───────────────────────────────────────────────
  Future<ImageSource?> showImageSourcePicker({String title = "Select Option"}) async {
    return await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose photo / document source",
              style: TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.back(result: ImageSource.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: ColorsValue.appColor.withOpacity(0.08),
                        border: Border.all(color: ColorsValue.appColor.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorsValue.appColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Camera",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          const Text("Take photo", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => Get.back(result: ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Browse Gallery",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          const Text("Choose from gallery", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }

  Future<String?> _pickImageWithPopup({String title = "Select Option"}) async {
    final ImageSource? source = await showImageSourcePicker(title: title);
    if (source == null) return null;
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
      return picked?.path;
    } catch (e) {
      Utility.showMessage("Failed to pick image: $e", MessageType.error, null, "OK");
      return null;
    }
  }

  Future<void> pickDriverPhoto() async {
    final path = await _pickImageWithPopup(title: "Driver Image");
    if (path != null) { driverPhotoPath = path; driverPhotoUrl = ''; update(); }
  }
  Future<void> pickDlPhoto() async {
    final path = await _pickImageWithPopup(title: "DL Image");
    if (path != null) { dlPhotoPath = path; dlPhotoUrl = ''; update(); }
  }
  Future<void> pickDlBackPhoto() async {
    final path = await _pickImageWithPopup(title: "DL Back Image");
    if (path != null) { dlBackPhotoPath = path; dlBackPhotoUrl = ''; update(); }
  }
  Future<void> pickAadharFront() async {
    final path = await _pickImageWithPopup(title: "Aadhaar Card Front Image");
    if (path != null) { aadharFrontPath = path; aadharFrontUrl = ''; update(); }
  }
  Future<void> pickAadharBack() async {
    final path = await _pickImageWithPopup(title: "Aadhaar Card Back Image");
    if (path != null) { aadharBackPath = path; aadharBackUrl = ''; update(); }
  }
  Future<void> pickPanPhoto() async {
    final path = await _pickImageWithPopup(title: "PAN Card Image");
    if (path != null) { panPhotoPath = path; panPhotoUrl = ''; update(); }
  }
  Future<void> pickGstCertificate() async {
    final path = await _pickImageWithPopup(title: "GST Certificate");
    if (path != null) { gstCertificatePhotoPath = path; gstCertificatePhotoUrl = ''; update(); }
  }
  Future<void> pickVisitingCard() async {
    final path = await _pickImageWithPopup(title: "Visiting Card");
    if (path != null) { visitingCardPhotoPath = path; visitingCardPhotoUrl = ''; update(); }
  }
  Future<void> pickAddressProofDocument() async {
    final path = await _pickImageWithPopup(title: "Address Proof Document");
    if (path != null) { addressProofDocumentPath = path; addressProofDocumentUrl = ''; update(); }
  }
  Future<void> pickPccCertificate() async {
    final path = await _pickImageWithPopup(title: "Select Police Criminal Certificate (PCC)");
    if (path != null) { pccCertificatePath = path; pccCertificateUrl = ''; update(); }
  }
  Future<void> pickPassbookPhoto() async {
    final path = await _pickImageWithPopup(title: "Bank Passbook / Cheque");
    if (path != null) { passbookPhotoPath = path; passbookPhotoUrl = ''; update(); }
  }
  Future<void> pickRcPhoto() async {
    final path = await _pickImageWithPopup(title: "RC Document");
    if (path != null) { rcPhotoPath = path; rcPhotoUrl = ''; update(); }
  }
  Future<void> pickInsuranceDocument() async {
    final path = await _pickImageWithPopup(title: "Insurance Document");
    if (path != null) { insuranceDocumentPath = path; insuranceDocumentUrl = ''; update(); }
  }
  Future<void> pickFitnessDocument() async {
    final path = await _pickImageWithPopup(title: "Fitness Document");
    if (path != null) { fitnessDocumentPath = path; fitnessDocumentUrl = ''; update(); }
  }
  Future<void> pickPermitDocument() async {
    final path = await _pickImageWithPopup(title: "Permit Document");
    if (path != null) { permitDocumentPath = path; permitDocumentUrl = ''; update(); }
  }
  Future<void> pickPucDocument() async {
    final path = await _pickImageWithPopup(title: "PUC Document");
    if (path != null) { pucDocumentPath = path; pucDocumentUrl = ''; update(); }
  }
  Future<void> pickRentedAgreement() async {
    final path = await _pickImageWithPopup(title: "Car Rent Agreement");
    if (path != null) { rentedAgreementPath = path; rentedAgreementUrl = ''; update(); }
  }

  /// Download official BamBam Rent Agreement template directly (PDF or Image)
  Future<void> downloadBambamRentAgreement() async {
    try {
      isDownloadingAgreement = true;
      update();

      final res = await profilePresenter.getRentAgreement();
      if (res.hasError || res.data == null) {
        Utility.showMessage("Car Rent Agreement has not been uploaded by Admin yet.", MessageType.error, null, "OK");
        return;
      }

      final decoded = jsonDecode(res.data.toString());
      final data = decoded['data'] ?? decoded['Data'];
      if (data == null || data['file_url'] == null || data['file_url'].toString().trim().isEmpty) {
        Utility.showMessage("Car Rent Agreement has not been uploaded by Admin yet.", MessageType.error, null, "OK");
        return;
      }

      bambamRentAgreementUrl = _fullUrl(data['file_url'].toString());
      if (bambamRentAgreementUrl.startsWith('http://apis.bambamcabs.com')) {
        bambamRentAgreementUrl = bambamRentAgreementUrl.replaceFirst('http://apis.bambamcabs.com', 'https://apis.bambamcabs.com');
      }
      final fileTypeFromApi = (data['file_type'] ?? '').toString().toLowerCase();

      // Download file directly with cache-busting
      final downloadUri = Uri.parse(bambamRentAgreementUrl).replace(
        queryParameters: {'_t': '${DateTime.now().millisecondsSinceEpoch}'},
      );
      final response = await http.get(downloadUri, headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final bool isPdf = fileTypeFromApi == 'pdf' || bambamRentAgreementUrl.toLowerCase().contains('.pdf');
        String ext = isPdf ? '.pdf' : '.png';
        String mimeType = isPdf ? 'application/pdf' : 'image/png';
        if (!isPdf) {
          if (bambamRentAgreementUrl.toLowerCase().contains('.jpg')) { ext = '.jpg'; mimeType = 'image/jpeg'; }
          if (bambamRentAgreementUrl.toLowerCase().contains('.jpeg')) { ext = '.jpeg'; mimeType = 'image/jpeg'; }
        }
        final fileName = 'BamBam_Car_Rent_Agreement$ext';

        if (!isPdf) {
          // Interactive zoomable image preview dialog
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "BamBam Car Rent Agreement",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(maxHeight: Get.height * 0.65),
                      padding: const EdgeInsets.all(8),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Image.memory(bytes),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5C00),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                            label: const Text(
                              "Download",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            onPressed: () async {
                              Get.back();
                              await Utility.saveBytesToPublicDownloads(
                                bytes: bytes,
                                fileName: fileName,
                                mimeType: mimeType,
                                url: bambamRentAgreementUrl,
                              );
                              Utility.showMessage(
                                "Car Rent Agreement downloaded successfully!\nSaved to your phone's Downloads folder ($fileName).",
                                MessageType.success,
                                null,
                                "OK",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // PDF downloaded dialog
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: Color(0xFFFF5C00),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "BamBam Car Rent Agreement PDF",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The official BamBam Car Rent Agreement PDF is ready.\n\n$fileName",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                      label: const Text(
                        "Download",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () async {
                        Get.back();
                        await Utility.saveBytesToPublicDownloads(
                          bytes: bytes,
                          fileName: fileName,
                          mimeType: mimeType,
                          url: bambamRentAgreementUrl,
                        );
                        Utility.showMessage(
                          "Car Rent Agreement downloaded successfully!\nSaved to your phone's Downloads folder ($fileName).",
                          MessageType.success,
                          null,
                          "OK",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        Utility.showMessage(
          "Car Rent Agreement document is not found on server (Error ${response.statusCode}). Please ensure Admin has uploaded it.",
          MessageType.error,
          null,
          "OK",
        );
      }
    } catch (e) {
      debugPrint("Error downloading rent agreement: $e");
      Utility.showMessage("Could not download car rent agreement: $e", MessageType.error, null, "OK");
    } finally {
      isDownloadingAgreement = false;
      update();
    }
  }
  Future<void> pickVehicleFront() async {
    final path = await _pickImageWithPopup(title: "Vehicle Front Photo");
    if (path != null) { vehicleFrontPhotoPath = path; vehicleFrontPhotoUrl = ''; update(); }
  }
  Future<void> pickVehicleBack() async {
    final path = await _pickImageWithPopup(title: "Vehicle Back Photo");
    if (path != null) { vehicleBackPhotoPath = path; vehicleBackPhotoUrl = ''; update(); }
  }
  Future<void> pickVehicleLeft() async {
    final path = await _pickImageWithPopup(title: "Vehicle Left Photo");
    if (path != null) { vehicleLeftPhotoPath = path; vehicleLeftPhotoUrl = ''; update(); }
  }
  Future<void> pickVehicleRight() async {
    final path = await _pickImageWithPopup(title: "Vehicle Right Photo");
    if (path != null) { vehicleRightPhotoPath = path; vehicleRightPhotoUrl = ''; update(); }
  }
  Future<void> pickVehicleInterior() async {
    final path = await _pickImageWithPopup(title: "Vehicle Interior Photo");
    if (path != null) { vehicleInteriorPhotoPath = path; vehicleInteriorPhotoUrl = ''; update(); }
  }
  Future<void> pickVehicleNumberPlate() async {
    final path = await _pickImageWithPopup(title: "Vehicle Number Plate Photo");
    if (path != null) { vehicleNumberPlatePhotoPath = path; vehicleNumberPlatePhotoUrl = ''; update(); }
  }
  Future<void> pickVehicleDicky() async {
    final path = await _pickImageWithPopup(title: "Vehicle Dicky Photo");
    if (path != null) { vehicleDickyPhotoPath = path; vehicleDickyPhotoUrl = ''; update(); }
  }
  Future<void> pickVehicleCarrier() async {
    final path = await _pickImageWithPopup(title: "Vehicle Carrier Photo");
    if (path != null) { vehicleCarrierPhotoPath = path; vehicleCarrierPhotoUrl = ''; update(); }
  }

  String _formatDateForDl(dynamic d) {
    if (d == null) return '';
    final s = d.toString().trim();
    if (s.isEmpty || s == '—' || s == 'null' || s == 'N/A') return '';

    // Check DD-MM-YYYY or DD/MM/YYYY
    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(s);
    if (dmy != null) {
      final day = dmy.group(1)!.padLeft(2, '0');
      final month = dmy.group(2)!.padLeft(2, '0');
      final year = dmy.group(3)!;
      return "$year-$month-$day";
    }

    try {
      final dt = DateTime.parse(s.split('T').first);
      return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {}

    return s;
  }

  // ─── Document Verifications ───────────────────────────────────────────────
  Future<void> verifyDL() async {
    final dl = dlNumberController.text.trim().toUpperCase();
    final dob = dobController.text.trim();
    if (dl.isEmpty) {
      Utility.showMessage("Please enter DL number", MessageType.error, null, "OK");
      return;
    }
    if (dob.isEmpty) {
      Utility.showMessage("Please enter Date of Birth first", MessageType.error, null, "OK");
      return;
    }
    isDlVerifying = true;
    update();
    try {
      final res = await profilePresenter.verifyDL(dlNumber: dl, dob: dob, showLoader: false);
      if (!res.hasError) {
        isDlVerified = true;
        try {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;

          final name = (data['holder_name'] ?? data['name'] ?? '').toString().trim();
          if (name.isNotEmpty && name != '—' && name != 'null' && name != 'N/A') {
            fullNameController.text = name;
          }

          // Auto-populate DL Issue Date and Expiry Date from API response
          String rawIssue = (data['issue_date'] ?? data['dl_issue_date'] ?? data['date_of_issue'] ?? data['doi'] ?? '').toString();
          String rawExpiry = (data['expiry_date'] ?? data['dl_expiry_date'] ?? data['date_of_expiry'] ?? data['valid_upto'] ?? data['doe'] ?? '').toString();

          if (rawExpiry.isEmpty || rawExpiry == '—' || rawExpiry == 'null' || rawExpiry == 'N/A') {
            if (data['validity'] is Map) {
              final valMap = data['validity'] as Map;
              if (valMap['non_transport'] is Map && valMap['non_transport']['to'] != null) {
                rawExpiry = valMap['non_transport']['to'].toString();
              } else if (valMap['to'] != null) {
                rawExpiry = valMap['to'].toString();
              }
            }
          }

          if (rawIssue.isNotEmpty && rawIssue != '—' && rawIssue != 'null' && rawIssue != 'N/A') {
            dlIssueController.text = _formatDateForDl(rawIssue);
          }
          if (rawExpiry.isNotEmpty && rawExpiry != '—' && rawExpiry != 'null' && rawExpiry != 'N/A') {
            dlExpiryController.text = _formatDateForDl(rawExpiry);
          }

          update();

          if (Get.context != null) showDlDetailsDialog(Get.context!, data);
        } catch (_) {
          update();
          Utility.showMessage("DL verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid Driving License";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("DL verification error: $e", MessageType.error, null, "OK");
    } finally {
      isDlVerifying = false;
      update();
    }
  }

  Future<void> verifyPAN() async {
    final pan = panController.text.trim().toUpperCase();
    if (pan.isEmpty) {
      Utility.showMessage("Please enter PAN number", MessageType.error, null, "OK");
      return;
    }
    isPanVerifying = true;
    update();
    try {
      final res = await profilePresenter.verifyPAN(panNumber: pan, showLoader: false);
      if (!res.hasError) {
        isPanVerified = true;
        update();
        try {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;
          if (Get.context != null) showPanDetailsDialog(Get.context!, data);
        } catch (_) {
          Utility.showMessage("PAN verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid PAN Card";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("PAN verification error: $e", MessageType.error, null, "OK");
    } finally {
      isPanVerifying = false;
      update();
    }
  }

  Future<void> verifyGST() async {
    final gst = gstNumberController.text.trim().toUpperCase();
    if (gst.isEmpty) {
      Utility.showMessage("Please enter GST number", MessageType.error, null, "OK");
      return;
    }
    isGstVerifying = true;
    update();
    try {
      final res = await profilePresenter.verifyGST(gstNumber: gst, showLoader: false);
      if (!res.hasError) {
        isGstVerified = true;
        update();
        try {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;
          if (Get.context != null) showGstDetailsDialog(Get.context!, data);
        } catch (_) {
          Utility.showMessage("GST verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid GST number";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("GST verification error: $e", MessageType.error, null, "OK");
    } finally {
      isGstVerifying = false;
      update();
    }
  }

  String formatDateToDdMmYyyy(dynamic date) {
    if (date == null) return '';
    final s = date.toString().trim();
    if (s.isEmpty || s == '—' || s == 'null' || s == 'N/A') return '';
    try {
      final parsed = DateTime.tryParse(s.split('T').first);
      if (parsed != null) {
        return "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
      }
    } catch (_) {}
    return s;
  }

  Future<void> verifyRC() async {
    final rc = (rcNumberController.text.isNotEmpty ? rcNumberController.text : vehicleNumberController.text).trim().toUpperCase();
    if (rc.isEmpty) {
      Utility.showMessage("Please enter Vehicle Number", MessageType.error, null, "OK");
      return;
    }
    isRcVerifying = true;
    update();
    try {
      final res = await profilePresenter.verifyRC(vehicleNumber: rc, showLoader: false);
      if (!res.hasError) {
        isRcVerified = true;

        try {
          final body = jsonDecode(res.data);
          final data = ((body['Data'] ?? body['data'] ?? body) as Map<dynamic, dynamic>)
              .map((k, v) => MapEntry(k.toString(), v));

          // 1. Vehicle Number & RC Number
          final cleanRc = (data['rc_number'] ?? data['registration_number'] ?? rc).toString().trim().toUpperCase();
          if (cleanRc.isNotEmpty && cleanRc != 'N/A') {
            rcNumberController.text = cleanRc;
            vehicleNumberController.text = cleanRc;
          }

          // 2. Auto populate brand / make
          final bName = (data['maker_model'] ?? data['brand_name'] ?? data['maker_description'] ?? '').toString().trim();
          if (bName.isNotEmpty && bName != 'N/A') {
            brandNameController.text = bName;
          }

          // 3. Auto populate manufacturing year (fallback to registration_date year)
          String mfgYear = (data['manufacturing_year'] ?? '').toString().trim();
          if (mfgYear.isEmpty || mfgYear == 'N/A') {
            final regDate = (data['registration_date'] ?? '').toString().trim();
            if (regDate.isNotEmpty && regDate != 'N/A') {
              mfgYear = regDate;
            }
          }
          if (mfgYear.isNotEmpty && mfgYear != 'N/A') {
            final yearMatch = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(mfgYear);
            if (yearMatch != null) {
              makeYearController.text = yearMatch.group(0)!;
            } else {
              makeYearController.text = mfgYear.split('-')[0].split('/')[0];
            }
          }

          // 4. Auto populate fitness expiry
          final fitUpto = (data['fit_up_to'] ?? data['fitness_upto'] ?? '').toString().trim();
          if (fitUpto.isNotEmpty && fitUpto != 'N/A') {
            fitnessExpiryController.text = formatDateToDdMmYyyy(fitUpto);
          }

          // 5. Auto populate insurance expiry
          final insUpto = (data['insurance_upto'] ?? data['insurance_expiry'] ?? '').toString().trim();
          if (insUpto.isNotEmpty && insUpto != 'N/A') {
            insuranceExpiryController.text = formatDateToDdMmYyyy(insUpto);
          }

          // 6. Auto populate permit expiry
          final permitUpto = (data['permit_expiry'] ?? data['permit_upto'] ?? '').toString().trim();
          if (permitUpto.isNotEmpty && permitUpto != 'N/A') {
            permitExpiryController.text = formatDateToDdMmYyyy(permitUpto);
          }

          // 7. Auto match fuel type if possible
          final fuel = (data['fuel_type'] ?? '').toString().trim().toUpperCase();
          if (fuel.isNotEmpty && fuel != 'N/A' && fuelTypeDropdownList.isNotEmpty) {
            bool matched = false;
            for (final f in fuelTypeDropdownList) {
              final fName = (f['name'] ?? '').toUpperCase().trim();
              if (fName == fuel || fName.contains(fuel) || fuel.contains(fName)) {
                selectedFuelType = f['id'];
                matched = true;
                break;
              }
            }
            if (!matched) {
              final parts = fuel.split(RegExp(r'[/, -]+'));
              for (final part in parts) {
                if (part.isEmpty) continue;
                for (final f in fuelTypeDropdownList) {
                  final fName = (f['name'] ?? '').toUpperCase().trim();
                  if (fName == part || fName.contains(part) || part.contains(fName)) {
                    selectedFuelType = f['id'];
                    matched = true;
                    break;
                  }
                }
                if (matched) break;
              }
            }
          }

          // Auto-assign vehicle type from verified RC
          if (data['vehicle_type_id'] != null) {
            selectedVehicleType = data['vehicle_type_id'].toString();
          }

          update();

          if (Get.context != null) {
            showRcDetailsDialog(Get.context!, data);
          }
        } catch (_) {
          update();
          Utility.showMessage("RC verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid RC number";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("RC verification error: $e", MessageType.error, null, "OK");
    } finally {
      isRcVerifying = false;
      update();
    }
  }

  Future<void> verifyIFSC() async {
    final ifsc = ifscCodeController.text.trim().toUpperCase();
    if (ifsc.isEmpty) {
      Utility.showMessage("Please enter IFSC code first", MessageType.error, null, "OK");
      return;
    }
    if (ifsc.length < 5) {
      Utility.showMessage("Please enter valid IFSC code", MessageType.error, null, "OK");
      return;
    }
    isBankVerifying = true;
    update();
    try {
      String fetchedBank = '';
      String fetchedBranch = '';
      bool found = false;

      // 1. Direct call to Razorpay IFSC API for instant lookup
      try {
        final razorpayRes = await http.get(Uri.parse("https://ifsc.razorpay.com/$ifsc")).timeout(const Duration(seconds: 6));
        if (razorpayRes.statusCode == 200) {
          final decoded = jsonDecode(razorpayRes.body);
          fetchedBank = (decoded['BANK'] ?? decoded['bank'] ?? '').toString();
          fetchedBranch = (decoded['BRANCH'] ?? decoded['branch'] ?? '').toString();
          if (fetchedBank.isNotEmpty) found = true;
        }
      } catch (_) {}

      // 2. Fallback to backend verify/ifsc
      if (!found) {
        final res = await profilePresenter.verifyIFSC(ifscCode: ifsc, showLoader: false);
        if (!res.hasError) {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;
          fetchedBank = (data['bank'] ?? data['BANK'] ?? data['bank_name'] ?? '').toString();
          fetchedBranch = (data['branch'] ?? data['BRANCH'] ?? data['branch_name'] ?? '').toString();
          if (fetchedBank.isNotEmpty) found = true;
        }
      }

      if (found) {
        isBankVerified = true;
        if (fetchedBank.isNotEmpty) {
          bankNameController.text = fetchedBank;
        }
        if (fetchedBranch.isNotEmpty) {
          branchNameController.text = fetchedBranch;
        }
        update();
        Utility.showMessage("IFSC verified! $fetchedBank, $fetchedBranch", MessageType.success, null, "OK");
      } else {
        isBankVerified = false;
        update();
        Utility.showMessage("Invalid IFSC Code. Please enter a valid IFSC code.", MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("IFSC verification error: $e", MessageType.error, null, "OK");
    } finally {
      isBankVerifying = false;
      update();
    }
  }

  // Alias for backward compatibility
  Future<void> verifyBank() => verifyIFSC();

  Future<void> verifyAadhaar() async {
    final aadhar = aadharController.text.trim().replaceAll(' ', '');
    if (aadhar.length != 12) {
      Utility.showMessage("Aadhaar must be 12 digits", MessageType.error, null, "OK");
      return;
    }
    isAadhaarVerifying = true;
    update();
    try {
      final res = await profilePresenter.requestAadhaarOtp(aadhaarNumber: aadhar, showLoader: false);
      if (!res.hasError) {
        try {
          final body = jsonDecode(res.data);
          final dataObj = body['Data'] ?? body['data'] ?? {};
          aadhaarRefId = (dataObj['ref_id'] ?? dataObj['data']?['ref_id'] ?? '').toString();
        } catch (_) {
          aadhaarRefId = '';
        }
        isAadhaarVerifying = false;
        update();
        showAadhaarOtpDialog(
          aadhaarNumber: aadhar,
          isVerifying: isAadhaarOtpVerifying,
          isResending: isAadhaarOtpResending,
          onVerify: (otp) async {
            await _verifyAadhaarOtp(otp);
          },
          onResend: () async {
            isAadhaarOtpResending = true;
            update();
            try {
              final res2 = await profilePresenter.requestAadhaarOtp(aadhaarNumber: aadhar, showLoader: false);
              if (!res2.hasError) {
                try {
                  final body = jsonDecode(res2.data);
                  final dataObj = body['Data'] ?? body['data'] ?? {};
                  aadhaarRefId = (dataObj['ref_id'] ?? dataObj['data']?['ref_id'] ?? '').toString();
                } catch (_) {}
                Utility.showMessage("OTP resent to Aadhaar-linked mobile", MessageType.success, null, "OK");
              }
            } catch (_) {} finally {
              isAadhaarOtpResending = false;
              update();
            }
          },
        );
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Aadhaar OTP request failed";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("Aadhaar OTP error: $e", MessageType.error, null, "OK");
    } finally {
      isAadhaarVerifying = false;
      update();
    }
  }

  Future<void> _verifyAadhaarOtp(String otp) async {
    isAadhaarOtpVerifying = true;
    update();
    try {
      final res = await profilePresenter.verifyAadhaarOtp(otp: otp, refId: aadhaarRefId, showLoader: false);
      if (!res.hasError) {
        isAadhaarVerified = true;
        update();
        Get.back(); // close dialog
        try {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;
          if (Get.context != null) showAadhaarDetailsDialog(Get.context!, data);
        } catch (_) {
          Utility.showMessage("Aadhaar verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid OTP";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("OTP verification error: $e", MessageType.error, null, "OK");
    } finally {
      isAadhaarOtpVerifying = false;
      update();
    }
  }

  // ─── Multi-select Toggles ──────────────────────────────────────────────────
  void toggleLanguage(String id) {
    if (selectedLanguageIds.contains(id)) {
      selectedLanguageIds.remove(id);
    } else {
      selectedLanguageIds.add(id);
    }
    update();
  }

  void toggleVehicle(String id) {
    if (selectedVehicleIds.contains(id)) {
      selectedVehicleIds.clear();
    } else {
      selectedVehicleIds = [id];
    }
    update();
  }

  void selectVehicle(String id) {
    selectedVehicleIds = [id];
    update();
  }

  // ─── Update Profile (Save all 6 steps) ────────────────────────────────────
  Future<void> updateProfile() async {
    isUpdating = true;
    update();

    Map<String, String> fields = {};

    // Step 0: Personal
    fields['driver_name'] = fullNameController.text.trim();
    fields['driver_mobile'] = phoneNumberController.text.trim();
    fields['email'] = emailController.text.trim();
    fields['dob'] = dobController.text.trim();
    fields['gender'] = selectedGender;
    fields['address'] = addressController.text.trim();
    if (selectedState != null && selectedState!.isNotEmpty) fields['state'] = selectedState!;
    if (selectedCity != null && selectedCity!.isNotEmpty) fields['city'] = selectedCity!;
    fields['zip_code'] = pinCodeController.text.trim();

    // Step 1: DL & Skills
    fields['DL_number'] = dlNumberController.text.trim().toUpperCase();
    fields['DL_issue_date'] = dlIssueController.text.trim();
    fields['DL_expiry_date'] = dlExpiryController.text.trim();
    if (selectedLanguageIds.isNotEmpty) fields['language_known'] = jsonEncode(selectedLanguageIds);
    if (selectedVehicleIds.isNotEmpty) fields['vehicales_drive'] = jsonEncode(selectedVehicleIds);

    // Step 2: KYC
    if (aadharController.text.isNotEmpty) fields['aadhar_number'] = aadharController.text.trim().replaceAll(' ', '');
    if (panController.text.isNotEmpty) fields['pan_number'] = panController.text.trim().toUpperCase();
    if (gstNumberController.text.isNotEmpty) fields['gst_number'] = gstNumberController.text.trim().toUpperCase();
    if (addressProofDocumentPath != null || addressProofNumberController.text.trim().isNotEmpty || addressProofDocumentUrl.isNotEmpty) {
      fields['address_proof_type'] = selectedAddressProofType;
    }
    if (addressProofNumberController.text.isNotEmpty) fields['address_proof_number'] = addressProofNumberController.text.trim();
    if (pccNumberController.text.isNotEmpty) fields['pcc_number'] = pccNumberController.text.trim();

    // Step 3: Bank
    fields['account_holder_name'] = accountHolderNameController.text.trim();
    fields['bank_name'] = bankNameController.text.trim();
    fields['branch_name'] = branchNameController.text.trim();
    fields['account_number'] = accountNumberController.text.trim();
    fields['ifsc_code'] = ifscCodeController.text.trim().toUpperCase();
    fields['upi_id'] = upiIdController.text.trim();

    // Step 4: Vehicle & Statutory
    fields['brand_name'] = brandNameController.text.trim();
    final vNum = (vehicleNumberController.text.isNotEmpty ? vehicleNumberController.text : rcNumberController.text).trim().toUpperCase();
    fields['vehicle_number'] = vNum;
    fields['rc_number'] = vNum;
    fields['vehicle_make_year'] = makeYearController.text.trim();
    if (selectedVehicleType != null) fields['vehicle_type'] = selectedVehicleType!;
    if (selectedFuelType != null) fields['fuel_type'] = selectedFuelType!;
    fields['sourcing'] = selectedSourcing;
    fields['pet_friendly'] = petFriendly;
    fields['luggage_carrier'] = luggageCarrier;
    fields['working_rear_seat_belts'] = rearSeatBelts;
    fields['permit_type'] = selectedPermitType;
    if (insuranceExpiryController.text.isNotEmpty) fields['insurance_expiry'] = insuranceExpiryController.text.trim();
    if (fitnessExpiryController.text.isNotEmpty) fields['fitness_expiry'] = fitnessExpiryController.text.trim();
    if (permitExpiryController.text.isNotEmpty) fields['permit_expiry'] = permitExpiryController.text.trim();

    if (profile != null && profile!['_id'] != null) {
      fields['driverId'] = profile!['_id'].toString();
    }

    // File paths map
    final filePaths = <String, String?>{
      'driver_photo': driverPhotoPath,
      'DL_photo': dlPhotoPath,
      'DL_back_photo': dlBackPhotoPath,
      'aadhar_photo': aadharFrontPath,
      'aadhar_back_photo': aadharBackPath,
      'pan_photo': panPhotoPath,
      'gst_certificate': gstCertificatePhotoPath,
      'visiting_card': visitingCardPhotoPath,
      'address_proof_document': addressProofDocumentPath,
      'pcc_certificate': pccCertificatePath,
      'passbook_photo': passbookPhotoPath,
      'rc_photo': rcPhotoPath,
      'insurance_document': insuranceDocumentPath,
      'fitness_document': fitnessDocumentPath,
      'permit_document': permitDocumentPath,
      'puc_document': pucDocumentPath,
      'rented_vehicle_agreement': rentedAgreementPath,
      'vehicle_front_photo': vehicleFrontPhotoPath,
      'vehicle_back_photo': vehicleBackPhotoPath,
      'vehicle_left_photo': vehicleLeftPhotoPath,
      'vehicle_right_photo': vehicleRightPhotoPath,
      'vehicle_interior_photo': vehicleInteriorPhotoPath,
      'vehicle_number_plate_photo': vehicleNumberPlatePhotoPath,
      'vehicle_dicky_photo': vehicleDickyPhotoPath,
      'vehicle_carrier_photo': vehicleCarrierPhotoPath,
    };

    final res = await profilePresenter.updateProfile(fields: fields, filePaths: filePaths);
    isUpdating = false;

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        final msg = body['Message'] ?? body['message'] ?? 'Failed to update profile';
        Utility.showMessage(msg.toString(), MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to update profile', MessageType.error, null, 'OK');
      }
      update();
      return;
    }

    final bool isIndividualNewOrRejected = !isCompanyDriver &&
        (profile?['approval_status'] != 'approved' || profile?['is_profile_completed'] != true);

    await fetchProfile();
    currentStep = 0;
    update();

    if (isIndividualNewOrRejected) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 36),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Registration Submitted!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Your profile details and vehicle documents have been submitted to BamBam Cabs Admin for verification. Once approved, you will be notified and can turn Online to receive rides.",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsValue.appColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Get.back();
                      RouteManagement.gotoHomeScreen();
                    },
                    child: const Text("Go to Home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } else {
      Utility.showMessage('Profile updated successfully!', MessageType.success, null, 'OK');
      RouteManagement.gotoHomeScreen();
    }
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
