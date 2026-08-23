// coverage:ignore-file

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';

class TranslationsFile extends Translations {
  /// List of locales used in the application
  static const listOfLocales = <Locale>[Locale('en')];

  @override
  Map<String, Map<String, String>> get keys => {
    'en': {
      'appName': StringConstants.appName,

      'full_name': 'Full Name',
      'enter_full_name': 'Enter Full Name',
      'email': 'Email',
      'enter_email': 'Enter Email',
      'phone_no': 'Phone No.',
      'enter_phone_no': 'Enter Phone No.',
      'select_city': 'Select City',
      'your_city': 'Select your city',
      'zip_code': 'Zip Code',
      'enter_code': 'Enter Zip Code',
      'otp_very': 'OTP Verification',
      'enter_otp':
          'Enter OTP send to +91 6743****45 to continue login to your account',
      'otp': 'OTP',
      'verify': 'Verify',
      'where_to_go': 'Where to go?',
      'go_places_nearby': 'Go Places nearby with BUM BUM!',
      'why_choose': 'Why Choose Us?',
      'one_way': 'One Way',
      'round_Trip': 'Round Trip',
      'from': 'From',
      'current_location': 'Current Location',
      'p_c': 'Pickup Time',
      'p_d': 'Pickup Date',
      'exlpore_cabs': 'Explore Cabs',
      'modify_booking': 'Modify Booking',
      'choess_you_vehical': 'Choose your Vehicle',
      'select_car': 'Select Car',
      'inclusion': 'Inclusion',
      'exclusion': 'Exclusion',
      'facility': 'Facility',
      'T_c': 'T & C',
      'pickup_address': 'Pickup Address',
      'entrt_pickup_address': 'Enter Pickup Address',
      'name': 'Name',
      'mobile_no': 'Mobile No',
      'gst_number': 'GST Number',
      'fare_summary': 'Fare Summary',
      'base_free': 'Base Fare',
      'taxes_fees': 'Taxes & Fees',
      'ohter_charge': 'Other Charges',
      'coupan': 'Coupon (FIRST RIDE)',
      'total': 'Total',
      'payment_option': 'Payment Option',
      'pay_now': 'Pay Now',
      'search': 'Search',
      'cancel_booking': 'Cancel Booking',
      'bookingz_confrom': 'Booking Confirmed',
      'view_detiles': 'View Details',
      'book_agin': 'Book Again',
      'write_review': 'Write Review',
      'booking_cancelled': 'Booking Cancelled',
      'booking_complted': 'Booking Completed',
      'booking_history': 'Booking History',
      'booking_id': 'Booking ID',
      'traveler_detiles': 'Traveler Details',
      'pickup_adres': 'Pickup Address',
      'driver_detiles': 'Driver Details',
      'cancel_dep': 'Are you sure want to cancel booking!',
      'enter_here': 'Enter Here',
      'description': 'Description',
      'reasonfor_cancllation': 'Reason For Cancellation',
      'review01':
          'Driver John was punctual, polite, and drove very safely throughout the trip. The car was clean and well-maintained. He even helped with luggage and made sure I reached on time. Highly recommended!”',
      'personal_information': 'Personal Information',
      'privacy_policy': 'Privacy Policy',
      'terms_condition': 'Terms & Conditions',
      'support_feedback': 'Support & Feedback',
      'driver_login': 'Driver Login',
      'logain_account': 'Enter below details to login your account',
      'submit_support_ticket': 'Submit Support Ticket',
      'Individual': 'Individual',
      'Company': 'Company',
      'approval_pending': 'Approval Pending',
      'approval_pending_msg': 'Your account is currently under review. Please contact support if you have any questions.',
      'back_to_login': 'Back to Login',
    },
  };
}
