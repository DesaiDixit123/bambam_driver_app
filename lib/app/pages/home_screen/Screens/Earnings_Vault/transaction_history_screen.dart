import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<HomeController>().fetchEarningsVaultData();
        });
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Transaction History",
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await controller.fetchEarningsVaultData();
            },
            child: ListView(
              padding: Dimens.edgeInsets20,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                if (controller.isEarningsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (controller.earningsData == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Text(
                        "No transaction history found",
                        style: GoogleFonts.poppins(
                          color: ColorsValue.txtG7Color,
                          fontSize: Dimens.fourteen,
                        ),
                      ),
                    ),
                  )
                else
                  ...(() {
                    final rawList = controller.earningsData!['wallet_history'] as List? ?? [];
                    final filteredList = rawList.where((item) {
                      if (item == null || item is! Map) return false;
                      final type = (item['type'] ?? '').toString().toLowerCase();
                      final status = (item['status'] ?? '').toString().toLowerCase();
                      if (type == 'credit') {
                        return status == 'paid';
                      } else if (type == 'debit') {
                        return status == 'success' || status == 'pending';
                      }
                      return true;
                    }).toList();

                    if (filteredList.isEmpty) {
                      return [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Text(
                              "No transaction history found",
                              style: GoogleFonts.poppins(
                                color: ColorsValue.txtG7Color,
                                fontSize: Dimens.fourteen,
                              ),
                            ),
                          ),
                        )
                      ];
                    }

                    return filteredList.map((item) {
                      final bool isCredit =
                          (item['type'] ?? '').toString().toLowerCase() == 'credit';
                      final String status = (item['status'] ?? '').toString();

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: (isCredit ? Colors.green : ColorsValue.redColor).withOpacity(0.1),
                              child: Icon(
                                isCredit ? Icons.add_rounded : Icons.remove_rounded,
                                color: isCredit ? Colors.green : ColorsValue.redColor,
                              ),
                            ),
                            title: Text(
                              "${item['description'] ?? 'Transaction'}",
                              style: GoogleFonts.poppins(
                                fontSize: Dimens.fourteen,
                                fontWeight: FontWeight.w600,
                                color: ColorsValue.txtBlackColor,
                              ),
                              maxLines: 2,
                            ),
                            subtitle: Text(
                              item['createdAt'] != null
                                  ? item['createdAt'].toString().substring(0, 10)
                                  : "Recently",
                              style: GoogleFonts.poppins(
                                fontSize: Dimens.twelve,
                                color: ColorsValue.txtG7Color,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isCredit ? '+' : '-'}₹${item['amount'] ?? 0}",
                                  style: GoogleFonts.poppins(
                                    fontSize: Dimens.sixteen,
                                    fontWeight: FontWeight.w700,
                                    color: isCredit ? Colors.green : ColorsValue.redColor,
                                  ),
                                ),
                                if (status.isNotEmpty && status.toLowerCase() != 'paid' && status.toLowerCase() != 'success')
                                  Text(
                                    status,
                                    style: GoogleFonts.poppins(
                                      fontSize: Dimens.eleven,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Divider(color: ColorsValue.borderColors.withOpacity(0.5)),
                        ],
                      );
                    }).toList();
                  })(),
              ],
            ),
          ),
        );
      },
    );
  }
}
