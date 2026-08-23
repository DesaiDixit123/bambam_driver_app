import 'package:get/get.dart';
import 'package:bam_bam_driver/app/pages/pages.dart';

part 'app_routes.dart';

class AppPages {
  static var transitionDuration = const Duration(milliseconds: 300);

  static const initial = _Paths.splashScreen;
  static final pages = <GetPage>[
    GetPage<SplashScreen>(
      name: _Paths.splashScreen,
      transitionDuration: transitionDuration,
      page: SplashScreen.new,
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<InAppUpdateScreen>(
      name: _Paths.inAppUpdateScreen,
      transitionDuration: transitionDuration,
      page: InAppUpdateScreen.new,
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<HomeScreen>(
      name: _Paths.homeScreen,
      transitionDuration: transitionDuration,
      page: HomeScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<LoginScreen>(
      name: _Paths.loginScreen,
      transitionDuration: transitionDuration,
      page: LoginScreen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<SupportScreen>(
      name: _Paths.supportScreen,
      transitionDuration: transitionDuration,
      page: SupportScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),

    GetPage<OtpVerifyScreen>(
      name: _Paths.otpVerifyScreen,
      transitionDuration: transitionDuration,
      page: OtpVerifyScreen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<ProfileScreen>(
      name: _Paths.profileScreen,
      transitionDuration: transitionDuration,
      page: ProfileScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<PersonalDetilesScreen>(
      name: _Paths.personalDetilesScreen,
      transitionDuration: transitionDuration,
      page: PersonalDetilesScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<PrivcyPolicyScreen>(
      name: _Paths.privcyPolicyScreen,
      transitionDuration: transitionDuration,
      page: PrivcyPolicyScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<TermsConditionsScreen>(
      name: _Paths.termsConditionsScreen,
      transitionDuration: transitionDuration,
      page: TermsConditionsScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<MyTicketlistScreen>(
      name: _Paths.myTicketlistScreen,
      transitionDuration: transitionDuration,
      page: MyTicketlistScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<CreatTicketScreen>(
      name: _Paths.creatTicketScreen,
      transitionDuration: transitionDuration,
      page: CreatTicketScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<TicketDetilesScreen>(
      name: _Paths.ticketDetilesScreen,
      transitionDuration: transitionDuration,
      page: TicketDetilesScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<NotificationScreen>(
      name: _Paths.notificationScreen,
      transitionDuration: transitionDuration,
      page: NotificationScreen.new,
      binding: NotificationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<AssignedTripScreen>(
      name: _Paths.assignedTripScreen,
      transitionDuration: transitionDuration,
      page: AssignedTripScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<AssignedTripScreen>(
      name: _Paths.assignedTripScreen,
      transitionDuration: transitionDuration,
      page: AssignedTripScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<OngoingtripScreen>(
      name: _Paths.ongoingtripScreen,
      transitionDuration: transitionDuration,
      page: OngoingtripScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<CompletedtripsScreen>(
      name: _Paths.completedtripsScreen,
      transitionDuration: transitionDuration,
      page: CompletedtripsScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<RulesScreen>(
      name: _Paths.rulesScreen,
      transitionDuration: transitionDuration,
      page: RulesScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<ComplectTripScreen>(
      name: _Paths.complectTripScreen,
      transitionDuration: transitionDuration,
      page: ComplectTripScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<OtpScreen>(
      name: _Paths.otpScreen,
      transitionDuration: transitionDuration,
      page: OtpScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<TripDetilesScreen>(
      name: _Paths.tripDetilesScreen,
      transitionDuration: transitionDuration,
      page: TripDetilesScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<TriptrackingScreen>(
      name: _Paths.triptrackingScreen,
      transitionDuration: transitionDuration,
      page: TriptrackingScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<VehicalMiterScreen>(
      name: _Paths.vehicalMiterScreen,
      transitionDuration: transitionDuration,
      page: VehicalMiterScreen.new,
      binding: TripBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<IssuedFinesScreen>(
      name: _Paths.issuedFinesScreen,
      transitionDuration: transitionDuration,
      page: IssuedFinesScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<FineDetilesScreen>(
      name: _Paths.fineDetilesScreen,
      transitionDuration: transitionDuration,
      page: FineDetilesScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<AddFineScreen>(
      name: _Paths.addFineScreen,
      transitionDuration: transitionDuration,
      page: AddFineScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<ApprovalPendingScreen>(
      name: _Paths.approvalPendingScreen,
      transitionDuration: transitionDuration,
      page: ApprovalPendingScreen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<RegisterScreen>(
      name: _Paths.registerScreen,
      transitionDuration: transitionDuration,
      page: RegisterScreen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<RejectedRidesScreen>(
      name: _Paths.rejectedRidesScreen,
      transitionDuration: transitionDuration,
      page: RejectedRidesScreen.new,
      binding: RejectedRidesBinding(),
      transition: Transition.fadeIn,
    ),

  ];
}

