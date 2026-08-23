import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class FineDetilesScreen extends StatelessWidget {
  const FineDetilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments is Map) ? Map<String, dynamic>.from(Get.arguments) : <String, dynamic>{};
    final String? fineId = args['fine_id']?.toString() ?? args['id']?.toString();

    return GetBuilder<HomeController>(
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (fineId != null && fineId.isNotEmpty) {
            final ctrl = Get.find<HomeController>();
            ctrl.fetchFineDetails(fineId);
          }
        });
      },
      builder: (controller) {
        if (controller.isLoadingFineDetail) {
          return Scaffold(
            appBar: AppBarWidget(onTapBack: () => Get.back(), title: "Fine Detiles "),
            backgroundColor: ColorsValue.appBg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = controller.fineDetails ?? {};
        final bookingId = data['booking_id']?.toString() ?? '—';
        final status = data['penalty_status']?.toString() ?? '—';
        final vehicleNo = data['vehicle_no']?.toString() ?? '—';
        final amount = data['penalty_amount']?.toString() ?? '—';
        final description = data['penalty_description']?.toString() ?? '—';
        final attachment = data['penalty_photo']?.toString() ?? '';
        final createdDate = data['created_date']?.toString() ?? data['date']?.toString() ?? '';
        final createdTime = data['created_time']?.toString() ?? '';

        return Scaffold(
          appBar: AppBarWidget(onTapBack: () => Get.back(), title: "Fine Detiles "),
          backgroundColor: ColorsValue.appBg,
          body: Padding(
            padding: Dimens.edgeInsets20,
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Dimens.two,
                        children: [
                          Text("Booking ID", style: Styles.txtG7Colors40014),
                          Text(bookingId, style: Styles.appColorw50014),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Dimens.two,
                        children: [
                          Text("Status", style: Styles.txtG7Colors40014),
                          Row(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                      status.toLowerCase() == 'paid' ? AssetConstants.Green_CN : AssetConstants.Red_CN,
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Padding(
                                  padding: Dimens.edgeInsets14_8_14_8,
                                  child: Text(
                                    status,
                                    style: status.toLowerCase() == 'paid' ? Styles.txtGreenColorW60014 : Styles.txtRedColorW60014,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Dimens.boxHeight20,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimens.two,
                  children: [
                    Text("Vehicle No.", style: Styles.txtG7Colors40014),
                    Text(vehicleNo, style: Styles.txtBlackColorW50016),
                  ],
                ),
                Dimens.boxHeight20,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimens.two,
                  children: [
                    Text("Penalty Amount", style: Styles.txtG7Colors40014),
                    Text("₹$amount", style: Styles.txtBlackColorW50016),
                  ],
                ),
                Dimens.boxHeight20,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimens.two,
                  children: [
                    Text("Penalty Description", style: Styles.txtG7Colors40014),
                    Text(description, style: Styles.txtBlackColorW50016),
                  ],
                ),
                Dimens.boxHeight20,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimens.two,
                  children: [
                    Text("Attachment", style: Styles.txtG7Colors40014),
                    attachment.isEmpty
                        ? Text("No Attachment", style: Styles.txtBlackColorW50016)
                        : Builder(
                            builder: (context) {
                              final url = attachment.startsWith('http') ? attachment : ApiWrapper.imageUrl + attachment;
                              final isImage = attachment.toLowerCase().endsWith('.jpg') ||
                                  attachment.toLowerCase().endsWith('.jpeg') ||
                                  attachment.toLowerCase().endsWith('.png') ||
                                  attachment.toLowerCase().endsWith('.webp');

                              if (isImage) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Dimens.boxHeight8,
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Dimens.twelve),
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 180,
                                            width: double.infinity,
                                            color: ColorsValue.whiteColor,
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(child: CircularProgressIndicator());
                                              },
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => Dialog(
                                                      backgroundColor: Colors.transparent,
                                                      insetPadding: EdgeInsets.zero,
                                                      child: Stack(
                                                        alignment: Alignment.center,
                                                        children: [
                                                          InteractiveViewer(
                                                            child: Image.network(
                                                              url,
                                                              fit: BoxFit.contain,
                                                              loadingBuilder: (context, child, loadingProgress) {
                                                                if (loadingProgress == null) return child;
                                                                return const Center(
                                                                  child: CircularProgressIndicator(
                                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 40,
                                                            right: 20,
                                                            child: IconButton(
                                                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                                              onPressed: () => Navigator.of(context).pop(),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    final uri = Uri.tryParse(url);
                                    if (uri != null) await launchUrl(uri);
                                  },
                                  child: Text(
                                    attachment.split('/').last,
                                    style: Styles.txtBlackColorW50016.copyWith(decoration: TextDecoration.underline),
                                  ),
                                );
                              }
                            },
                          ),
                  ],
                ),
                if (createdDate.isNotEmpty || createdTime.isNotEmpty) ...[
                  Dimens.boxHeight20,
                  Text("Created", style: Styles.txtG7Colors40014),
                  Text('$createdDate $createdTime', style: Styles.txtBlackColorW50016),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
