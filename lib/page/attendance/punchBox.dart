// ignore_for_file: unused_element, must_be_immutable, library_private_types_in_public_api, unused_local_variable, strict_top_level_inference

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/setTimeline.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class PunchBoxConfirmation extends StatefulWidget {
  File? userImage;
  String typeBox;
  dynamic setUserWeekoff;
  String currentLocation,setlatitude,setlongitude,postcode;

  PunchBoxConfirmation(this.userImage,this.typeBox,this.currentLocation,this.setlatitude,this.setlongitude,this.setUserWeekoff,this.postcode,{super.key});

  @override
  _PunchBoxConfirmationState createState() => _PunchBoxConfirmationState();
}

class _PunchBoxConfirmationState extends State<PunchBoxConfirmation> {
  late SelfiePunchProvider punchProvider;

  Future<void> callPunchData() async {
    punchProvider.setPunchLoader(true);   
    LocationTimeLineClass().setUserTimeLine(deviceName: 'Fore',deviceType:Platform.isAndroid ?'Android': 'IOS' , latitude: widget.setlatitude, logitude: widget.setlongitude, pincode: widget.postcode,  addres: widget.currentLocation);                      
    await punchProvider.punchNowCall(context,curentUser['Id'],widget.userImage!,widget.currentLocation,widget.setlatitude,widget.setlongitude,punchProvider.punchBoxNotesController.text,widget.setUserWeekoff);
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

onback(){

}
  @override
  Widget build(BuildContext context) {
    final issetKeyBoard = MediaQuery.of(context).viewInsets.bottom != 0;
    Size size = MediaQuery.of(context).size;
    Provider.of<LanguageProvider>(context);
    return WillPopScope(
      onWillPop: () =>onback(),
      child: Stack(
        children: [
      AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      titlePadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded dialog corners
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
            heightSpacer(size.height * 0.03),

            // --- HEADER SECTION (Title & Profile Image) ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.jm().format(DateTime.now()),
                          style: TextStyle(
                            fontSize: size.height * 0.016,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${LanguageProvider.translate("Confirm", "Confirm")} ${widget.typeBox}',
                          style: customeHeadingTextsize(size, size.height * 0.024),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${LanguageProvider.translate("Are You Ready to", "Are You Ready to")} ${widget.typeBox}?',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: size.height * 0.016,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  if (widget.userImage != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      height: size.height * 0.08,
                      width: size.height * 0.08, // Keep it square/circular ratio
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ColorConst.themeColor.withOpacity(0.2), width: 2),
                          image: DecorationImage(
                            image: FileImage(widget.userImage as File),
                            fit: BoxFit.cover,
                          )
                      ),
                    ),
                  ],
                ],
              ),
            ),

            heightSpacer(size.height * 0.025),

            // --- NOTES TEXTFIELD SECTION ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextField(
                  controller: punchProvider.punchBoxNotesController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: LanguageProvider.translate("Write notes here...", "Write notes here..."),
                    hintStyle: TextStyle(fontSize: size.height * 0.018, color: Colors.grey[500]),
                  ),
                  onChanged: (value) {
                    punchProvider.setPunchBoxNotes(value);
                  },
                ),
              ),
            ),

            heightSpacer(size.height * 0.025),

            // --- DYNAMIC BUTTONS & LOADING SECTION ---
            Consumer<SelfiePunchProvider>(
                builder: (context, provider, child) {
                  // Business Logic Conditions
                  final bool isConfirmDisabled = provider.isPrePunchChecksLoading || !provider.isPrePunchChecksSuccess;

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
                                child: CircularProgressIndicator(strokeWidth: 2, color: ColorConst.themeColor),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                provider.punchProcessStatus.value,
                                style: TextStyle(color: ColorConst.themeColor, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),

                      // Action Buttons Footer
                      Padding(
                        padding: EdgeInsets.only(
                            left: size.width * 0.05,
                            right: size.width * 0.05,
                            bottom: size.height * 0.025
                        ),
                        child: Row(
                          children: [
                            // Cancel Button
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[300]!),
                                  padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  provider.setPunchBoxOnTapStart(false);
                                  provider.setPunchLoader(false);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  cancelString,
                                  style: TextStyle(
                                      fontSize: size.height * 0.018,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600]
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Confirm Button
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isConfirmDisabled ? Colors.grey[200] : ColorConst.themeColor,
                                  foregroundColor: isConfirmDisabled ? Colors.grey[500] : Colors.white,
                                  elevation: isConfirmDisabled ? 0 : 2,
                                  padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isConfirmDisabled
                                    ? null
                                    : () async {
                                  if (provider.punchBoxOnTapStart == false) {
                                    provider.setPunchBoxOnTapStart(true);
                                    await callPunchData();
                                  }
                                },
                                child: provider.punchBoxOnTapStart
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: isConfirmDisabled ? Colors.grey : Colors.white
                                  ),
                                )
                                    : Text(
                                  LanguageProvider.translate("Confirm", "Confirm"),
                                  style: TextStyle(
                                    fontSize: size.height * 0.018,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
            ),
          ],
        ),
      ),
    )
      
      
    
       
        ],
      ),
    );
  }
}
