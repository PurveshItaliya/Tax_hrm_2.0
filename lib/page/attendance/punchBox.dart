// ignore_for_file: use_build_context_synchronously, unused_element, must_be_immutable, library_private_types_in_public_api, unused_local_variable, strict_top_level_inference

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class PunchBoxConfirmation extends StatefulWidget {
  File? userImage;
  String typeBox;
  dynamic setUserWeekoff;
  String currentLocation, setlatitude, setlongitude, postcode;
  bool isFromWidget;

  PunchBoxConfirmation(
    this.userImage,
    this.typeBox,
    this.currentLocation,
    this.setlatitude,
    this.setlongitude,
    this.setUserWeekoff,
    this.postcode, {
    this.isFromWidget = false,
    super.key,
  });

  @override
  _PunchBoxConfirmationState createState() => _PunchBoxConfirmationState();
}

class _PunchBoxConfirmationState extends State<PunchBoxConfirmation> {
  late SelfiePunchProvider punchProvider;

  Future<void> callPunchData() async {
    punchProvider.setPunchLoader(true);
    await LocationBatchStorage.appendLocation(
      latitude: double.parse(widget.setlatitude),
      longitude: double.parse(widget.setlongitude),
      entryTime: DateTime.now(),
    );
    final String userDataStr = await SaveUser().getUserDatas();
    if (userDataStr.isNotEmpty) {
      final dynamic userData = jsonDecode(userDataStr);
      await LocationBatchStorage.uploadPendingBatch(
        userData: userData,
        isMapScreen: false,
        isAppForeground: true,
      );
    }
    await punchProvider.punchNowCall(
      context,
      curentUser['Id'],
      widget.userImage!,
      widget.currentLocation,
      widget.setlatitude,
      widget.setlongitude,
      punchProvider.punchBoxNotesController.text,
      widget.setUserWeekoff,
      widget.isFromWidget,
    );
  }

  @override
  void initState() {
    super.initState();
    punchProvider = Provider.of<SelfiePunchProvider>(context, listen: false);

    // Start background checks immediately after dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkKeyboardStatus();
      // Ensure we have current location first if not already available
      if (punchProvider.currentLocation != null) {
        punchProvider.processPrePunchChecks(context);
      }
    });
  }

  void _checkKeyboardStatus() {
    if (!mounted) return;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final EdgeInsets viewInsets = mediaQuery.viewInsets;
    final bool isKeyboardOpens = viewInsets.bottom > 0;
    punchProvider.setPunchBoxKeyboardOpen(isKeyboardOpens);
  }

  onback() {}
  @override
  Widget build(BuildContext context) {
    final issetKeyBoard = MediaQuery.of(context).viewInsets.bottom != 0;
    Size size = MediaQuery.of(context).size;
    Provider.of<LanguageProvider>(context);
    return WillPopScope(
      onWillPop: () => onback(),
      child: Stack(
        children: [
          AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            contentPadding: const EdgeInsets.all(0),
            titlePadding: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ), // Rounded dialog corners
            content: Container(
              width: size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ColorConst.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- CONFIRMATION TEXT ---
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.height * 0.015,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${LanguageProvider.translate("Confirm", "Confirm")} ${widget.typeBox}',
                            style: customeHeadingTextsize(
                              size,
                              size.height * 0.025,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            size: size.height * 0.03,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            punchProvider.setPunchBoxOnTapStart(false);
                            punchProvider.setPunchLoader(false);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // --- PHOTO, TIME & LOCATION SECTION ---
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.userImage != null) ...[
                          Container(
                            height: size.height * 0.18,
                            width: size.height * 0.18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ColorConst.themeColor.withOpacity(0.4),
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: FileImage(widget.userImage as File),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: size.height * 0.01),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('hh:mm a').format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: size.height * 0.030,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConst.black.withAlpha(180),
                                  ),
                                ),
                                Text(
                                  widget.currentLocation.isNotEmpty
                                      ? widget.currentLocation
                                      : LanguageProvider.translate(
                                          "Location not available",
                                          "Location not available",
                                        ),
                                  style: TextStyle(
                                    fontSize: size.height * 0.015,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                heightSpacer(size.height * 0.015),

                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        59,
                                        57,
                                        57,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  child: TextField(
                                    controller:
                                        punchProvider.punchBoxNotesController,
                                    maxLines: 2,
                                    minLines: 1,
                                    style: TextStyle(
                                      fontSize: size.height * 0.015,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                      border: InputBorder.none,
                                      hintText: "Add Remarks",
                                      hintStyle: TextStyle(
                                        fontSize: size.height * 0.014,
                                        color: Colors.grey[500],
                                      ),
                                      prefixIcon: Icon(
                                        Icons.comment_outlined,
                                        size: size.height * 0.018,
                                        color: Colors.grey[400],
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                    ),
                                    onChanged: (value) {
                                      punchProvider.setPunchBoxNotes(value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- REMARKS SECTION ---
                  heightSpacer(size.height * 0.015),

                  // --- DYNAMIC BUTTONS & LOADING SECTION ---
                  Consumer<SelfiePunchProvider>(
                    builder: (context, provider, child) {
                      // Business Logic Conditions
                      final bool isConfirmDisabled =
                          provider.isPrePunchChecksLoading ||
                          !provider.isPrePunchChecksSuccess;

                      return Column(
                        children: [
                          // Status Indicator for Pre-Punch Checks
                          if (provider.isPrePunchChecksLoading)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ColorConst.themeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    provider.punchProcessStatus.value,
                                    style: TextStyle(
                                      color: ColorConst.themeColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Action Buttons Footer
                          Padding(
                            padding: EdgeInsets.only(
                              left: size.width * 0.05,
                              right: size.width * 0.05,
                              bottom: size.height * 0.025,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                fixedSize: size.width * 0.9 < 400
                                    ? Size(size.width * 0.9, size.height * 0.055)
                                    : Size(400, size.height * 0.055),
                                backgroundColor: isConfirmDisabled
                                    ? Colors.grey[200]
                                    : ColorConst.themeColor,
                                foregroundColor: isConfirmDisabled
                                    ? Colors.grey[500]
                                    : Colors.white,
                                elevation: isConfirmDisabled ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isConfirmDisabled
                                  ? null
                                  : () async {
                                      if (provider.punchBoxOnTapStart ==
                                          false) {
                                        provider.setPunchBoxOnTapStart(
                                          true,
                                        );
                                        await callPunchData();
                                      }
                                    },
                              child: provider.punchBoxOnTapStart
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: isConfirmDisabled
                                            ? Colors.grey
                                            : Colors.white,
                                      ),
                                    )
                                  : Text(
                                      LanguageProvider.translate(
                                        "Confirm",
                                        "Confirm",
                                      ),
                                      style: TextStyle(
                                        fontSize: size.height * 0.018,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
