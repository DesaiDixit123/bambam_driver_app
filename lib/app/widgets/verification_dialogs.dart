import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── Color constants ──────────────────────────────────────────────────────────
const Color _kGreen = Color(0xFF12724A);
const Color _kOrange = Color(0xFFFF6B00);

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF555555),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF222222)),
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _dialogDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );

// ─────────────────────────────────────────────────────────────────────────────
// 1. PAN Details Dialog
// ─────────────────────────────────────────────────────────────────────────────

void showPanDetailsDialog(
    BuildContext context, Map<String, dynamic> panData, {Color themeColor = _kGreen}) {
  String name =
      (panData['name'] ?? panData['registered_name'] ?? panData['full_name'] ?? panData['name_as_per_pan'] ?? '').toString().trim();
  String panNumber = (panData['pan_number'] ?? panData['pan'] ?? '').toString().trim();
  String category = (panData['category'] ?? '').toString().trim();

  if (name.isEmpty || name == 'null') {
    name = "—";
  }
  if (panNumber.isEmpty || panNumber == 'null') {
    panNumber = "—";
  }
  if (category.isEmpty || category == 'null') {
    category = "Individual";
  }

  Get.dialog(
    Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: themeColor == _kGreen ? const Color(0xFFE6F4ED) : themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  color: themeColor, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'PAN Verification Successful',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: themeColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Name', name),
            _infoRow('PAN Number', panNumber),
            _infoRow('Category', category),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Close',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. GST Details Dialog
// ─────────────────────────────────────────────────────────────────────────────

void showGstDetailsDialog(
    BuildContext context, Map<String, dynamic> gstData, {Color themeColor = _kGreen}) {
  String tradeName = (gstData['trade_name'] ?? gstData['tradeNam'] ?? gstData['tradeName'] ?? '').toString().trim();
  String legalName = (gstData['legal_name'] ?? gstData['lgnm'] ?? gstData['legalName'] ?? '').toString().trim();
  String gstin =
      (gstData['gstin'] ?? gstData['gst_number'] ?? '').toString().trim();
  String status = (gstData['status'] ?? gstData['sts'] ?? '').toString().trim();
  String taxpayerType =
      (gstData['taxpayer_type'] ?? gstData['dty'] ?? gstData['taxpayerType'] ?? '').toString().trim();
  
  String stateJurisdiction = '';
  if (gstData['state_jurisdiction'] != null) {
    stateJurisdiction = gstData['state_jurisdiction'].toString().trim();
  } else if (gstData['stj'] != null) {
    stateJurisdiction = gstData['stj'].toString().trim();
  } else if (gstData['state'] != null) {
    stateJurisdiction = gstData['state'].toString().trim();
  } else if (gstData['pradr'] is Map && gstData['pradr']['addr'] is Map) {
    stateJurisdiction = (gstData['pradr']['addr']['stcd'] ?? '').toString().trim();
  }

  if (tradeName.isEmpty || tradeName == 'null') {
    tradeName = "—";
  }
  if (legalName.isEmpty || legalName == 'null') {
    legalName = "—";
  }
  if (gstin.isEmpty || gstin == 'null') {
    gstin = "—";
  }
  if (status.isEmpty || status == 'null') {
    status = "Active";
  }
  if (taxpayerType.isEmpty || taxpayerType == 'null') {
    taxpayerType = "Regular";
  }
  if (stateJurisdiction.isEmpty || stateJurisdiction == 'null') {
    stateJurisdiction = "—";
  }

  final bool isActive =
      status.toLowerCase() == 'active';

  Get.dialog(
    Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive
                    ? (themeColor == _kGreen ? const Color(0xFFE6F4ED) : themeColor.withOpacity(0.1))
                    : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.verified : Icons.warning_amber_rounded,
                color: isActive ? themeColor : Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isActive
                  ? 'GST Verification Successful'
                  : 'GST Status: $status',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isActive ? themeColor : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Trade Name', tradeName),
            _infoRow('Legal Name', legalName),
            _infoRow('GSTIN', gstin),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Status',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF555555)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (themeColor == _kGreen ? const Color(0xFFE6F4ED) : themeColor.withOpacity(0.1))
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? themeColor : Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _infoRow('Taxpayer Type', taxpayerType),
            _infoRow('State Jurisdiction', stateJurisdiction),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? themeColor : _kOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Close',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. DL Details Dialog
// ─────────────────────────────────────────────────────────────────────────────

void showDlDetailsDialog(
    BuildContext context, Map<String, dynamic> dlData) {
  final String holderName =
      (dlData['holder_name'] ?? dlData['name'] ?? '—').toString();
  final String dlNumber = (dlData['dl_number'] ?? '—').toString();
  final String dob = (dlData['dob'] ?? '—').toString();
  final String issueDate =
      (dlData['issue_date'] ?? dlData['dl_issue_date'] ?? '—').toString();
  final String expiryDate =
      (dlData['expiry_date'] ?? dlData['dl_expiry_date'] ?? '—').toString();
  final dynamic vcRaw = dlData['vehicle_classes'];
  final String vehicleClasses = vcRaw is List
      ? vcRaw.join(', ')
      : (vcRaw ?? '—').toString();

  Get.dialog(
    Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: _kGreen, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'DL Verification Successful',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _kGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Holder Name', holderName),
            _infoRow('DL Number', dlNumber),
            _infoRow('Date of Birth', dob),
            _infoRow('Issue Date', issueDate),
            _infoRow('Expiry Date', expiryDate),
            _infoRow('Vehicle Classes', vehicleClasses),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Close',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3.1 RC Details Dialog
// ─────────────────────────────────────────────────────────────────────────────

void showRcDetailsDialog(
    BuildContext context, Map<String, dynamic> rcData, {Color themeColor = _kGreen}) {
  final String ownerName = (rcData['owner_name'] ?? rcData['registered_owner'] ?? rcData['name'] ?? '—').toString().trim();
  final String rcNumber = (rcData['rc_number'] ?? rcData['registration_number'] ?? '—').toString().trim();
  final String makerModel = (rcData['maker_model'] ?? rcData['brand_name'] ?? rcData['maker_description'] ?? '—').toString().trim();
  final String fuelType = (rcData['fuel_type'] ?? '—').toString().trim();
  final String vehicleClass = (rcData['vehicle_category'] ?? rcData['vehicle_class'] ?? '—').toString().trim();
  final String regDate = (rcData['registration_date'] ?? '—').toString().trim();
  final String fitnessUpto = (rcData['fit_up_to'] ?? rcData['fitness_upto'] ?? '—').toString().trim();
  final String insuranceUpto = (rcData['insurance_upto'] ?? rcData['insurance_expiry'] ?? '—').toString().trim();
  final String insuranceCompany = (rcData['insurance_company'] ?? '').toString().trim();
  final String status = (rcData['status'] ?? rcData['rc_status'] ?? 'ACTIVE').toString().trim();

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _dialogDecoration(),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_car_rounded, color: themeColor, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'RC Verification Successful',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: themeColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _infoRow('RC Number', rcNumber),
              _infoRow('Owner Name', ownerName),
              _infoRow('Maker / Model', makerModel),
              _infoRow('Fuel Type', fuelType),
              _infoRow('Vehicle Class', vehicleClass),
              _infoRow('Reg. Date', regDate),
              _infoRow('Fitness Upto', fitnessUpto),
              _infoRow('Insurance Upto', insuranceUpto),
              if (insuranceCompany.isNotEmpty && insuranceCompany != 'N/A')
                _infoRow('Insurance Co.', insuranceCompany),
              _infoRow('RC Status', status),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Aadhaar Details Dialog (after successful OTP verification)
// ─────────────────────────────────────────────────────────────────────────────

void showAadhaarDetailsDialog(
    BuildContext context, Map<String, dynamic> aadhaarData) {
  final Map<dynamic, dynamic> d = aadhaarData['data'] is Map
      ? aadhaarData['data']
      : aadhaarData['Data'] is Map
          ? aadhaarData['Data']
          : aadhaarData;

  final String name =
      (d['full_name'] ?? d['name'] ?? '—').toString().trim();
  final String dob =
      (d['date_of_birth'] ?? d['dob'] ?? '—').toString().trim();
  final String gender =
      (d['gender'] ?? '—').toString().trim();
  final dynamic addrRaw = d['full_address'] ?? d['address'];
  final String address = addrRaw is Map
      ? [
          addrRaw['house'],
          addrRaw['street'],
          addrRaw['loc'],
          addrRaw['vtc'],
          addrRaw['dist'],
          addrRaw['state'],
          addrRaw['pincode'] ?? addrRaw['pc'],
        ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ')
      : (addrRaw ?? '—').toString().trim();

  Get.dialog(
    Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user,
                  color: _kGreen, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aadhaar Verified Successfully',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _kGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Name', name),
            _infoRow('Date of Birth', dob),
            _infoRow('Gender', gender),
            if (address.isNotEmpty && address != '—')
              _infoRow('Address', address),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Close',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Aadhaar OTP Dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the Aadhaar OTP dialog using Get.dialog.
void showAadhaarOtpDialog({
  required String aadhaarNumber,
  required Future<void> Function(String otp) onVerify,
  required Future<void> Function() onResend,
  required bool isVerifying,
  required bool isResending,
}) {
  Get.dialog(
    AadhaarOtpDialog(
      aadhaarNumber: aadhaarNumber,
      onVerify: onVerify,
      onResend: onResend,
      isVerifying: isVerifying,
      isResending: isResending,
    ),
    barrierDismissible: false,
  );
}

class AadhaarOtpDialog extends StatefulWidget {
  const AadhaarOtpDialog({
    super.key,
    required this.aadhaarNumber,
    required this.onVerify,
    required this.onResend,
    required this.isVerifying,
    required this.isResending,
  });

  final String aadhaarNumber;
  final Future<void> Function(String otp) onVerify;
  final Future<void> Function() onResend;
  final bool isVerifying;
  final bool isResending;

  @override
  State<AadhaarOtpDialog> createState() => _AadhaarOtpDialogState();
}

class _AadhaarOtpDialogState extends State<AadhaarOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 30;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _isVerifying = widget.isVerifying;
    _isResending = widget.isResending;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.trim().length != 6) return;
    setState(() => _isVerifying = true);
    try {
      await widget.onVerify(_otpController.text.trim());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    setState(() => _isResending = true);
    try {
      await widget.onResend();
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
        _startTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: _kOrange, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aadhaar OTP Verification',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'An OTP has been sent to the mobile number linked with Aadhaar ending in '
              '${widget.aadhaarNumber.length >= 4 ? widget.aadhaarNumber.substring(widget.aadhaarNumber.length - 4) : widget.aadhaarNumber}.',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF777777)),
            ),
            const SizedBox(height: 20),
            // OTP field
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                hintStyle: const TextStyle(
                    color: Color(0xFFCCCCCC), letterSpacing: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _kOrange, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
              ),
            ),
            const SizedBox(height: 20),
            // Verify button
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isVerifying ? null : _handleVerify,
                child: _isVerifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Verify',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            // Resend row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive OTP? ",
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF777777)),
                ),
                _canResend
                    ? GestureDetector(
                        onTap: _isResending ? null : _handleResend,
                        child: _isResending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: _kOrange, strokeWidth: 2),
                              )
                            : const Text(
                                'Resend',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kOrange,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                      )
                    : Text(
                        'Resend in ${_secondsLeft}s',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFAAAAAA)),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            // Cancel
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Color(0xFF777777), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
