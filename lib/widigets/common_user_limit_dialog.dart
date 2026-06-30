import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

void showUserLimitDialog(BuildContext context, size, permitUsers, totalUser) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cancel,
              color: Colors.red,
              size: 50,
            ),
            const SizedBox(height: 10),
            const Text(
              "User Limit Exceeded",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            RichText(textAlign: TextAlign.center, text: TextSpan(
              children: [
                const TextSpan(text: 'Permitted: ', style: TextStyle(color: ColorConst.black)),
                TextSpan(text: '$permitUsers, ', style: normalHeadingText(size)),
                const TextSpan(text: 'Current: ', style: TextStyle(color: ColorConst.black)),
                TextSpan(text: '$totalUser.', style: normalHeadingText(size)),
                const TextSpan(text: 'Please Contact Customer Care For Assistance.', style: TextStyle(color: ColorConst.black)),
              ],
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: ColorConst.themeColor,
              ),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const Divider(),
            const Text(
              "IVR NO: 95100 56789 / 9510156789",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    },
  );
}