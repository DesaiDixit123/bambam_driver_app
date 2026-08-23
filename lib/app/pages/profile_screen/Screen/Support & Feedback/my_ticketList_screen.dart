
import 'package:bam_bam_driver/app/navigators/routes_management.dart';
import 'package:bam_bam_driver/app/pages/profile_screen/profile_presenter.dart';
import 'package:bam_bam_driver/app/utils/utility.dart';
import 'package:bam_bam_driver/app/widgets/custom_button.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/usecases/profile_usecases.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:bam_bam_driver/app/pages/profile_screen/profile_controller.dart';
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:bam_bam_driver/app/theme/dimens.dart';
import 'package:bam_bam_driver/app/theme/styles.dart';
import 'package:bam_bam_driver/app/utils/asset_constants.dart';
import 'package:bam_bam_driver/app/widgets/app_bar_widgets.dart';



class MyTicketlistScreen extends StatefulWidget {
  const MyTicketlistScreen({super.key});

  @override
  State<MyTicketlistScreen> createState() => _MyTicketlistScreenState();
}

class _MyTicketlistScreenState extends State<MyTicketlistScreen> {
 

 late final ProfileController controller;

@override
void initState() {
  super.initState();

  if (Get.isRegistered<ProfileController>()) {
    controller = Get.find<ProfileController>();
  } else {
    controller = Get.put(
      ProfileController(
        ProfilePresenter(
          ProfileUsecases(Get.find()),
        ),
      ),
    );
  }

  controller.fetchTicketsWithoutPagination();
}


  String _statusLabel(Map<String, dynamic> ticket) {
    final status = (ticket['status'] ?? '').toString();
    if (status.isEmpty) return 'Pending';
    return status;
  }

  String _ticketId(Map<String, dynamic> ticket) {
    // prefer ticket_no, then _id
    return ticket['ticket_no']?.toString() ?? ticket['_id']?.toString() ?? '—';
  }

  

  String _issueType(Map<String, dynamic> ticket) {
    return ticket['issue_type']?.toString() ?? '—';
  }

  String _description(Map<String, dynamic> ticket) {
    return ticket['description']?.toString() ?? '—';
  }





  // choose badge asset by status — keep same assets you had in UI
  String _statusAsset(String status) {
    status = status.toLowerCase();
    if (status.contains('resolved')) {
      return AssetConstants.Green_CN;
    } else if (status.contains('pending')) {
      return AssetConstants.Red_CN;
    } else if (status.contains('progress') || status.contains('in progress')) {
      return AssetConstants.yello_CN;
    } else {
      return AssetConstants.yello_CN;
    }
  }
  
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final ticketNo = _ticketId(ticket);
    final status = _statusLabel(ticket);
    final issue = _issueType(ticket);
  
    final desc = _description(ticket);

 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      
        InkWell(
          borderRadius: BorderRadius.circular(Dimens.twelve),
          onTap: () async {
            final id = ticket['_id']?.toString() ?? ticket['ticket_id']?.toString() ?? '';
            if (id.isNotEmpty) {
              await controller.fetchTicketDetails(id);
              RouteManagement.gotoTicketDetilesScreen();
            } else {
              // if no id, just show toast
              Utility.showMessage('Ticket id not available', MessageType.error, null, 'ok');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: ColorsValue.l4CB,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(Dimens.twelve),
            ),
            child: Padding(
              padding: Dimens.edgeInsets20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ticket ID #$ticketNo",
                        style: Styles.appcolorsBold16.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                  Dimens.boxHeight25,
                  Text(issue, style: Styles.txtBlackColorW50016),
                  Dimens.boxHeight8,
                  Text(
                    desc,
                    style: Styles.txtG7Colors40014,
                  ),
                
                ],
              ),
            ),
          ),
        ),
        Dimens.boxHeight16,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        onTapBack: () {
          Get.back();
        },
        title: "My Tickets",
      ),
      backgroundColor: ColorsValue.appBg,
      bottomSheet: Padding(
        padding: Dimens.edgeInsets20_30_20_30,
        child: CustomButton(
          text: "Add Ticket",
          textStyle: Styles.txtBlackColorW50016,
          backgroundColor: ColorsValue.appColor,
          onPressed: () {
            RouteManagement.gotoCreatTicketScreen();
          },
        ),
      ),
      body: GetBuilder<ProfileController>(
        builder: (pc) {
          final tickets = pc.tickets;
          if (pc.tickets.isEmpty) {
            // show placeholder / empty state while loading or if empty
            return ListView(
              padding: Dimens.edgeInsets20,
              children: [
                Center(
                  child: pc.tickets.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Dimens.boxHeight40,
                            Text('No tickets found', style: Styles.txtG7Colors40014),
                            Dimens.boxHeight8,
                            Text(
                              'Create a new support ticket using the button below.',
                              style: Styles.txtG7Colors40014,
                              textAlign: TextAlign.center,
                            ),
                            Dimens.boxHeight100,
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          }

      return ListView(
  padding: Dimens.edgeInsets20,
  children: [
    for (var t in tickets)
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tickets.indexOf(t) == 0) ...[
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: Styles.txtBlackColorW70018,
            ),
            Dimens.boxHeight16,
          ],
          _buildTicketCard(Map<String, dynamic>.from(t)),
        ],
      ),
    Dimens.boxHeight100,
  ],
);

        },
      ),
    );
  }
}
