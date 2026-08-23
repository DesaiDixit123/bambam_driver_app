import 'package:bam_bam_driver/app/pages/profile_screen/profile_controller.dart';
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:bam_bam_driver/app/theme/dimens.dart';
import 'package:bam_bam_driver/app/theme/styles.dart';
import 'package:bam_bam_driver/app/utils/asset_constants.dart';
import 'package:bam_bam_driver/app/widgets/app_bar_widgets.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TicketDetilesScreen extends StatelessWidget {
  const TicketDetilesScreen({super.key});

  String _statusAsset(String status) {
    final s = status.toLowerCase();
    if (s.contains('resolved')) return AssetConstants.Green_CN;
    if (s.contains('pending')) return AssetConstants.Red_CN;
    if (s.contains('progress') || s.contains('in progress')) return AssetConstants.yello_CN;
    return AssetConstants.yello_CN;
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _attachmentUrl(Map<String, dynamic> detail) {
    final att = (detail['attachment'] ?? '').toString();
    if (att.isEmpty) return '';
    if (att.startsWith('http')) return att;
    final base = ApiWrapper.imageUrl; // ensure this is correct for your storage
    return base + att;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        final Map<String, dynamic>? d =
            controller.ticketDetail != null ? Map<String, dynamic>.from(controller.ticketDetail!) : null;

        // Fallback to empty map to avoid many null checks in UI
        final detail = d ?? <String, dynamic>{};

        final ticketNo = (detail['ticket_no'] ?? detail['_id'] ?? 'TKTXXXX').toString();
        final status = (detail['status'] ?? 'Pending').toString();
        final issueType = (detail['issue_type'] ?? '—').toString();
        final bookingId = (detail['booking_id'] ?? '—').toString();
        final description = (detail['description'] ?? '—').toString();
        final createdAt = _formatDate(detail['createdAt']?.toString());
        final attachmentUrl = _attachmentUrl(detail);

        final supportResponses = <dynamic>[];
        if (detail.containsKey('support_response') && detail['support_response'] is List) {
          supportResponses.addAll(List.from(detail['support_response']));
        }

        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Ticket Details",
          ),
          body: ListView(
            padding: Dimens.edgeInsets20,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    spacing: Dimens.five,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Ticket ID", style: Styles.txtG7Colors40014),
                      Text(
                        ticketNo,
                        style: Styles.appcolorsBold16.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    spacing: Dimens.five,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Ticket Status", style: Styles.txtG7Colors40014),
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_statusAsset(status)),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Padding(
                          padding: Dimens.edgeInsets8,
                          child: Text(
                            status.tr,
                            style: status.toLowerCase().contains('resolved')
                                ? Styles.txtGreenColorW60014
                                : status.toLowerCase().contains('pending')
                                    ? Styles.txtRedColorW60014
                                    : Styles.txtG7Colors40014,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Dimens.boxHeight20,

              // Created date (if available)
              if (createdAt.isNotEmpty) ...[
                Text("Created At", style: Styles.txtG7Colors40014),
                Dimens.boxHeight2,
                Text(createdAt, style: Styles.txtBlackColorW50016),
                Dimens.boxHeight20,
              ],

              // Ticket Status (label + type)
              Text("Ticket Status", style: Styles.txtG7Colors40014),
              Dimens.boxHeight2,
              Text(issueType, style: Styles.txtBlackColorW50016),
              Dimens.boxHeight20,

              // Booking ID
              Text("Booking ID", style: Styles.txtG7Colors40014),
              Dimens.boxHeight2,
              Text(bookingId, style: Styles.txtBlackColorW50016),
              Dimens.boxHeight20,

              // Description
              Text("Description", style: Styles.txtG7Colors40014),
              Dimens.boxHeight2,
              Text(description, style: Styles.txtBlackColorW50016),
              Dimens.boxHeight20,

              // Attachment preview (if present)
              if (attachmentUrl.isNotEmpty) ...[
                Text("Attachment", style: Styles.txtG7Colors40014),
                Dimens.boxHeight8,
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      attachmentUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(child: Icon(Icons.broken_image)),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
                Dimens.boxHeight20,
              ],

              // Support Responses
              Text("🎧 Support Response", style: Styles.txtG7Colors40014),
              Dimens.boxHeight12,
              if (supportResponses.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimens.twelve),
                    color: ColorsValue.l4CB,
                  ),
                  child: Padding(
                    padding: Dimens.edgeInsets20,
                    child: Text(
                      "No responses yet.",
                      style: Styles.txtBlackColorW50016,
                    ),
                  ),
                )
              else
                Column(
                  children: supportResponses.map<Widget>((resp) {
                    // resp may be Map or String; handle both
                    String respText = '';
                    String respBy = '';
                    String respDate = '';
                    try {
                      if (resp is Map) {
                        respText = resp['message']?.toString() ?? resp['response']?.toString() ?? resp.toString();
                        respBy = resp['by']?.toString() ?? resp['responder']?.toString() ?? '';
                        respDate = _formatDate(resp['createdAt']?.toString() ?? resp['date']?.toString());
                      } else {
                        respText = resp.toString();
                      }
                    } catch (_) {
                      respText = resp.toString();
                    }

                    return Container(
                      width: double.infinity,
                      margin: Dimens.edgeInsets8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        color: ColorsValue.l4CB,
                      ),
                      child: Padding(
                        padding: Dimens.edgeInsets20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (respBy.isNotEmpty)
                              Text(
                                respBy,
                                style: Styles.txtBlackColorW50016.copyWith(fontWeight: FontWeight.w600),
                              ),
                            if (respDate.isNotEmpty) ...[
                              Dimens.boxHeight4,
                              Text(respDate, style: Styles.txtG7Colors40014.copyWith(fontSize: 12)),
                            ],
                            if (respBy.isNotEmpty || respDate.isNotEmpty) Dimens.boxHeight8,
                            Text(respText, style: Styles.txtBlackColorW50016),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              Dimens.boxHeight30,
            ],
          ),
        );
      },
    );
  }
}
