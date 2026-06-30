// // ignore_for_file: strict_top_level_inference, unused_element, no_leading_underscores_for_local_identifiers

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:tax_hrm/widigets/localnotification.dart';

// void checknotification(context) {
//   FirebaseMessaging.instance.getInitialMessage().then((message) {
//     // if((message!.data['_id'])){
//     //    Navigator.of(context).push(
//     //       MaterialPageRoute(
//     //         builder: (context) => ViewNotification(
//     //           // id: message.data['_id'],
//     //         ),
//     //       ),
//     //     );

//     // }
//     if (message != null) {
//       // Provider.of<AuthProvider>(context,listen: false).ontapnotifictaion(context);
//     } else {
//       //    Provider.of<AuthProvider>(context, listen: false).getuserdata(context);
//       // tostmessage('No Id Found', blackcolor,whitcolor);
//     }
//   });

//   // 2. This method only call when App in forground it mean app must be opened
//   FirebaseMessaging.onMessage.listen((message) {
//     if (message.notification != null) {
//       LocalNotificationService.createanddisplaynotification(message);
//     }
//   });

//   // 3. This method only call when App in background and not terminated(not closed)
//   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//     if (message.notification != null) {
//       // Navigator.of(context).push(
//       //     MaterialPageRoute(
//       //       builder: (context) => ViewNotification(
//       //         // id: message.data['_id'],
//       //       ),
//       //     ),
//       //   );
//       LocalNotificationService.createanddisplaynotification(message);
//     }
//   });

//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   void _handleNotificationClick() async {
//     RemoteMessage? initialMessage = await _firebaseMessaging
//         .getInitialMessage();

//     if (initialMessage != null) {
//       // App was opened from a notification
//       // Navigate to the desired page based on the notification
//       // Navigator.push(
//       //   context,
//       //   MaterialPageRoute(
//       //     builder: (context) => ViewNotification(),
//       //   ),
//       // );
//     }
//   }
// }
