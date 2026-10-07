import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:tax_hrm/page/visit/visit_camera_screen.dart' as tax_cam;
import 'package:tax_hrm/api/visit_api.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/visit/party_list_model.dart';
import 'dart:convert';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/randomcguid.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/api/eventsapi.dart';
import 'package:intl/intl.dart';

class VisitController extends GetxController {
  final VisitApis _visitApis = VisitApis();
  final Employeeclass _employeeServices = Employeeclass();

  var isLoading = false.obs;
  var isSubmitting = false.obs;

  var partyList = <PartyListModel>[].obs;
  var selectedParty = Rxn<PartyListModel>();

  var employeesList = <Employeelists>[].obs;
  var selectedAssignTo = <Employeelists>[].obs;

  var selectedVisitTime = Rxn<DateTime>();
  var selectedStartTime = Rxn<DateTime>();
  var selectedEndTime = Rxn<DateTime>();

  var visitStatusList = ['Pending', 'In Progress', 'Complete'].obs;
  var selectedVisitStatus = 'Pending'.obs;

  var capturedImage = Rxn<File>();
  var currentLatitude = ''.obs;
  var currentLongitude = ''.obs;
  var currentAddress = ''.obs;

  var isNewParty = false.obs;
  final TextEditingController newPartyNameController = TextEditingController();
  final TextEditingController newPartyAdd1Controller = TextEditingController();
  final TextEditingController newPartyAdd2Controller = TextEditingController();
  final TextEditingController newPartyMobileController = TextEditingController();

  final TextEditingController visitNameController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  var attachedDocuments = <File>[].obs;

  Future<void> pickAttachment(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    void addFile(File file) {
      if (attachedDocuments.length >= 3) {
        showtoastmessage('Maximum 3 items allowed');
        return;
      }
      if (file.lengthSync() > 10 * 1024 * 1024) {
        showtoastmessage('Maximum file size is 10MB');
        return;
      }
      attachedDocuments.add(file);
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Add Attachment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (photo != null) addFile(File(photo.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.purple),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) addFile(File(image.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.orange),
              title: const Text('Document / File'),
              onTap: () async {
                Navigator.pop(ctx);
                FilePickerResult? result = await FilePicker.pickFiles(allowMultiple: true);
                if (result != null) {
                  for (var file in result.files) {
                    if (file.path != null) addFile(File(file.path!));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      String custId = curentUser['CustId'] ?? 'TAY967';
      String companyId = selectedcurentcompany?.companyId.toString() ?? '1092';
      
      try {
        var parties = await _visitApis.getPartyListDropdown(custId, companyId);
        partyList.assignAll(parties);
      } catch (e) {
        developer.log('Error fetching parties: $e', name: 'VisitController', error: e);
      }

      developer.log('curentUser details: $curentUser', name: 'VisitController_AssignTo_Debug');
      final userRole = curentUser['Role'] ?? curentUser['role'] ?? 'UNKNOWN';
      developer.log('User Role is: $userRole', name: 'VisitController_AssignTo_Debug');

      if (userRole.toString().trim().toLowerCase() == 'admin' || userRole.toString().trim().toLowerCase() == 'superadmin') {
        developer.log('Role is Admin. Attempting to fetch employees list...', name: 'VisitController_AssignTo_Debug');
        try {
          var employees = await _employeeServices.emppppapi();
          developer.log('Raw employees response: $employees', name: 'VisitController_AssignTo_Debug');
          
          if (employees != null) {
            employeesList.assignAll(employees);
            developer.log('Successfully added ${employees.length} employees to employeesList.', name: 'VisitController_AssignTo_Debug');
          } else {
            developer.log('employees response is NULL.', name: 'VisitController_AssignTo_Debug');
          }
        } catch (e, stacktrace) {
          developer.log('Error fetching employees: $e', name: 'VisitController_AssignTo_Debug', error: e, stackTrace: stacktrace);
        }
      } else {
        developer.log('Role is NOT admin. Skipping employee fetch.', name: 'VisitController_AssignTo_Debug');
      }
      developer.log('fetchInitialData completed', name: 'VisitController');
    } catch (e) {
      developer.log('Error in fetchInitialData: $e', name: 'VisitController', error: e);
      showtoastmessage('Failed to fetch initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImageAndLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const tax_cam.VisitCameraScreen()),
    );

    if (result != null && result is Map) {
      capturedImage.value = result['file'];
      currentLatitude.value = result['latitude'];
      currentLongitude.value = result['longitude'];
      currentAddress.value = result['address'];
    }
  }

  Future<void> selectDateTime(BuildContext context, Rxn<DateTime> targetVariable) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: targetVariable.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(targetVariable.value ?? DateTime.now()),
      );

      if (pickedTime != null) {
        targetVariable.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  void resetForm() {
    visitNameController.clear();
    remarksController.clear();
    selectedParty.value = null;
    selectedAssignTo.clear();
    selectedVisitTime.value = null;
    selectedStartTime.value = null;
    selectedEndTime.value = null;
    selectedVisitStatus.value = 'Pending';
    capturedImage.value = null;
    currentLatitude.value = '';
    currentLongitude.value = '';
    currentAddress.value = '';
    isNewParty.value = false;
    newPartyNameController.clear();
    newPartyAdd1Controller.clear();
    newPartyAdd2Controller.clear();
    newPartyMobileController.clear();
    attachedDocuments.clear();
  }

  /// Called after any CreateUpdateVisit response.
  /// If TodayPunch == "No" the server is telling us this user has NO attendance
  /// punch today. Automatically fire a punch-in using the current user's own
  /// device so only THEIR attendance is added — not all assigned users.
  Future<void> _handleTodayPunch(dynamic apiResponse) async {
    try {
      final todayPunch = apiResponse?['TodayPunch']?.toString() ?? 'Yes';
      developer.log('[VisitController] TodayPunch: $todayPunch', name: 'VisitController');

      if (todayPunch.toLowerCase() != 'no') return;

      developer.log('[VisitController] TodayPunch=No → auto punch-in for assigned user', name: 'VisitController');

      final String cguid = generateGuid();
      final String remarks = 'Auto punch via Visit';
      final String lat = currentLatitude.value.isNotEmpty ? currentLatitude.value : (apiResponse?['customervisit']?['ImgLatitude']?.toString() ?? '');
      final String lng = currentLongitude.value.isNotEmpty ? currentLongitude.value : (apiResponse?['customervisit']?['ImgLogitude']?.toString() ?? '');
      final String location = currentAddress.value.isNotEmpty ? currentAddress.value : '';
      final String targetEmpId = apiResponse?['customervisit']?['VisitAssignTo']?.toString() ?? curentUser['Id']?.toString() ?? '0';

      developer.log('[VisitController] Auto-punch payload → EmpId: $targetEmpId, Cguid: $cguid', name: 'VisitController');

      final punchResult = await AttendanceApis().callPunch(
        sendCguid: cguid,
        setRemarks: remarks,
        weekoffStatus: false,
        empId: targetEmpId,
      );

      developer.log('[VisitController] Auto-punch response: success=${punchResult?.success}, flag=${punchResult?.flag}', name: 'VisitController');

      if (punchResult?.success == true) {
        final status = punchResult?.attendenceLog?.isNotEmpty == true
            ? punchResult!.attendenceLog!.last.status ?? ''
            : '';
        developer.log('[VisitController] Auto-punch successful, status: $status', name: 'VisitController');
        
        // Upload image and location logs to complete the punch (matching normal punch screen behavior)
        await AttendanceApis().callWithImgPunch(
          FILES: capturedImage.value,
          setCguid: cguid,
          setLongitude: lng,
          setLatitude: lat,
          setLocation: location,
          empId: targetEmpId,
          listenRes: (val) {
            developer.log('[VisitController] Auto-punch image upload response: $val', name: 'VisitController');
          },
        );

        // ── Explicitly log punch location to timeline batch ────────
        try {
          if (lat.isNotEmpty && lng.isNotEmpty) {
            await LocationBatchStorage.appendLocation(
              latitude: double.parse(lat),
              longitude: double.parse(lng),
              entryTime: DateTime.now(),
            );
          }
          final String userDataStr = await SaveUser().getUserDatas();
          if (userDataStr.isNotEmpty) {
            final dynamic userData = jsonDecode(userDataStr);
            await LocationBatchStorage.uploadPendingBatch(
              userData: userData,
              isMapScreen: false,
              isAppForeground: true,
            );
          }
        } catch (_) {}
        // ──────────────────────────────────────────────────────────
        
        showtoastmessage('Attendance punch added automatically ✓');
      } else {
        developer.log('[VisitController] Auto-punch response indicates failure, success=${punchResult?.success}', name: 'VisitController');
      }
    } catch (e, stackTrace) {
      developer.log('[VisitController] Auto-punch failed: $e', name: 'VisitController', error: e, stackTrace: stackTrace);
      // Don't show error toast — the visit itself succeeded, punch failure is secondary
    }
  }

  Future<void> submitVisit(BuildContext context) async {
    if (visitNameController.text.trim().isEmpty) {
      showtoastmessage('Please enter visit name');
      return;
    }
    
    if (isNewParty.value) {
      if (newPartyNameController.text.trim().isEmpty) {
        showtoastmessage('Please enter party name');
        return;
      }
      if (newPartyMobileController.text.trim().isEmpty) {
        showtoastmessage('Please enter party mobile number');
        return;
      }
      if (newPartyAdd1Controller.text.trim().isEmpty) {
        showtoastmessage('Please enter address 1');
        return;
      }
    } else {
      if (selectedParty.value == null) {
        showtoastmessage('Please select a party');
        return;
      }
    }

    if (selectedVisitTime.value == null) {
      showtoastmessage('Please select visit time');
      return;
    }
    if (curentUser != null && curentUser['Role'] == 'Admin' && selectedAssignTo.isEmpty) {
      showtoastmessage('Please assign to at least one employee');
      return;
    }

    isSubmitting.value = true;
    try {
      String visitUkeyId = generateGuid();
      String assignTo = curentUser['Role'] == 'Admin' 
          ? selectedAssignTo.map((e) => e.id.toString()).join(',')
          : curentUser['Id'].toString();

      Map<String, dynamic> visitData = {
        "CompanyId": selectedcurentcompany?.companyId ?? 1092,
        "VisitUkeyId": visitUkeyId,
        "VisitName": visitNameController.text.trim(),
        "VisitTime": selectedVisitTime.value!.toIso8601String(),
        "StartTime": selectedStartTime.value?.toIso8601String(),
        "EndTime": selectedEndTime.value?.toIso8601String(),
        "VisitStatus": selectedVisitStatus.value,
        "ImgLogitude": currentLongitude.value.isNotEmpty ? currentLongitude.value : null,
        "ImgLatitude": currentLatitude.value.isNotEmpty ? currentLatitude.value : null,
        "Remarks": remarksController.text,
        "VisitAssignTo": assignTo,
      };

      if (isNewParty.value) {
        visitData["PartyId"] = 0;
        visitData["PartyName"] = newPartyNameController.text.trim();
        visitData["Add1"] = newPartyAdd1Controller.text.trim();
        visitData["Add2"] = newPartyAdd2Controller.text.trim();
        visitData["Mobile"] = newPartyMobileController.text.trim();
      } else {
        visitData["PartyId"] = selectedParty.value!.partyId;
      }

      developer.log('[VisitController] Submitting new visit…', name: 'VisitController');
      final dynamic visitResponse = await _visitApis.createUpdateVisit(visitData, flag: 'A');
      developer.log('[VisitController] createUpdateVisit response: $visitResponse', name: 'VisitController');

      if (capturedImage.value != null) {
        await _visitApis.createTaskFileUpload(
          filename: [capturedImage.value!.path],
          cguid: visitUkeyId,
          companyId: selectedcurentcompany?.companyId.toString() ?? '',
          partyId: isNewParty.value ? '0' : (selectedParty.value?.partyId.toString() ?? '0'),
        );
      }

      if (attachedDocuments.isNotEmpty) {
        await _visitApis.createTaskFileUpload(
          filename: attachedDocuments.map((e) => e.path).toList(),
          cguid: visitUkeyId,
          companyId: selectedcurentcompany?.companyId.toString() ?? '',
          partyId: isNewParty.value ? '0' : (selectedParty.value?.partyId.toString() ?? '0'),
          category: 'VisitDoc',
        );
      }

      if (curentUser != null) {
        try {
          String custIdBase = curentUser['CustId']?.toString() ?? curentUser['custid']?.toString() ?? '';
          String companyId = selectedcurentcompany?.companyId?.toString() ?? '';
          
          String pName = isNewParty.value ? newPartyNameController.text.trim() : (selectedParty.value?.partyName ?? '');
          String vName = visitNameController.text.trim();
          String vDate = DateFormat('dd/MM/yyyy').format(selectedVisitTime.value!);
          String vTime = DateFormat('hh:mm a').format(selectedVisitTime.value!);

          if (curentUser['Role'] == 'Admin' && selectedAssignTo.isNotEmpty) {
            for (var emp in selectedAssignTo) {
              String targetTopic = '${custIdBase}_${companyId}_${emp.id}';
              String titleName = 'USER ${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim().toUpperCase();
              
              await EventsApiClass().sendPushNotification(
                title: 'Visit Assigned to You',
                description: 'A new visit has been assigned to you for $pName ($vName) on $vDate at $vTime.',
                topicOverride: targetTopic,
                custIdOverride: custIdBase,
                topicTitleOverride: titleName,
              );
            }
          } else if (curentUser['Role'] != 'Admin') {
            String fName = curentUser['FirstName']?.toString() ?? '';
            String lName = curentUser['LastName']?.toString() ?? '';
            String userName = '$fName $lName'.trim().toUpperCase();
            
            String targetTopic = 'ALL_ADMIN_${custIdBase}_$companyId';
            String fullCompanyName = selectedcurentcompany?.companyName?.toString() ?? 'COMPANY';
            String titleName = fullCompanyName.trim().split(' ').first;

            await EventsApiClass().sendPushNotification(
              title: 'New Visit Created by User',
              description: '$userName has created a new visit for $pName ($vName) scheduled on $vDate at $vTime. Please review the visit details.',
              topicOverride: targetTopic,
              custIdOverride: custIdBase,
              topicTitleOverride: titleName,
            );
          }
        } catch (e) {
          developer.log('[VisitController] Failed to send push notification: $e', name: 'VisitController');
        }
      }

      resetForm();
      showtoastmessage('Visit created successfully');
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showtoastmessage('Failed to create visit: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> startVisit(BuildContext context, Map<String, dynamic> visitData) async {
    isSubmitting.value = true;
    try {
      String visitUkeyId = visitData['VisitUkeyId']?.toString() ?? '';
      String companyId = visitData['CompanyId']?.toString() ?? selectedcurentcompany?.companyId.toString() ?? '';
      String partyId = visitData['PartyId']?.toString() ?? '';
      String assignTo = visitData['VisitAssignTo']?.toString() ?? '';
      if (assignTo.isEmpty || assignTo == '0' || assignTo == 'null') {
        assignTo = curentUser != null ? (curentUser['Id'] ?? curentUser['id'] ?? '0').toString() : '0';
      }

      // For update (Flag: U), always use the current user's own EmpId.
      // The server does not accept comma-separated IDs on update calls.
      final String selfId = curentUser != null
          ? (curentUser['Id'] ?? curentUser['id'] ?? '0').toString()
          : '0';

      Map<String, dynamic> updateData = {
        "CompanyId": visitData['CompanyId'],
        "VisitUkeyId": visitUkeyId,
        "VisitName": visitData['VisitName'],
        "PartyId": visitData['PartyId'],
        "VisitTime": visitData['VisitTime'],
        "StartTime": DateTime.now().toIso8601String(),
        "EndTime": visitData['EndTime'],
        "VisitStatus": 'In Progress',
        "ImgLogitude": currentLongitude.value.isNotEmpty ? currentLongitude.value : visitData['ImgLogitude'],
        "ImgLatitude": currentLatitude.value.isNotEmpty ? currentLatitude.value : visitData['ImgLatitude'],
        "Remarks": visitData['Remarks'],
        "VisitAssignTo": selfId,
      };

      developer.log('Starting visit: $visitUkeyId', name: 'VisitController');
      final dynamic startResponse = await _visitApis.createUpdateVisit(updateData, flag: 'U');
      developer.log('[VisitController] startVisit response: $startResponse', name: 'VisitController');

      // Auto-punch if TodayPunch == "No"
      await _handleTodayPunch(startResponse);

      if (capturedImage.value != null) {
        await _visitApis.createTaskFileUpload(
          filename: [capturedImage.value!.path],
          cguid: visitUkeyId,
          companyId: companyId,
          partyId: partyId,
        );
        capturedImage.value = null;
        currentLatitude.value = '';
        currentLongitude.value = '';
        currentAddress.value = '';
      }

      // ── Save Active Visit for Auto-Close Background Logic ────────
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_visit_data', jsonEncode(updateData));
        await prefs.setDouble('active_visit_lat', double.tryParse(updateData['ImgLatitude']?.toString() ?? '') ?? 0.0);
        await prefs.setDouble('active_visit_lng', double.tryParse(updateData['ImgLogitude']?.toString() ?? '') ?? 0.0);
      } catch (_) {}
      // ─────────────────────────────────────────────────────────────

      // ── Explicitly log and upload visit start location to timeline batch ────────
      try {
        if (updateData['ImgLatitude'] != null && updateData['ImgLogitude'] != null && updateData['ImgLatitude'].toString().isNotEmpty && updateData['ImgLogitude'].toString().isNotEmpty) {
          await LocationBatchStorage.appendLocation(
            latitude: double.parse(updateData['ImgLatitude'].toString()),
            longitude: double.parse(updateData['ImgLogitude'].toString()),
            entryTime: DateTime.now(),
          );
        }
        final String userDataStr = await SaveUser().getUserDatas();
        if (userDataStr.isNotEmpty) {
          final dynamic userData = jsonDecode(userDataStr);
          await LocationBatchStorage.uploadPendingBatch(
            userData: userData,
            isMapScreen: false,
            isAppForeground: true,
          );
        }
      } catch (_) {}
      // ──────────────────────────────────────────────────────────

      try {
        if (curentUser != null) {
          String custIdBase = curentUser['CustId']?.toString() ?? curentUser['custid']?.toString() ?? '';
          String companyId = visitData['CompanyId']?.toString() ?? selectedcurentcompany?.companyId.toString() ?? '';
          
          String fName = curentUser['FirstName']?.toString() ?? '';
          String lName = curentUser['LastName']?.toString() ?? '';
          String userName = '$fName $lName'.trim().toUpperCase();

          String pName = visitData['PartyName']?.toString() ?? '';
          String vName = visitData['VisitName']?.toString() ?? '';
          
          DateTime now = DateTime.now();
          String vTime = DateFormat('hh:mm a').format(now);

          String targetTopic = 'ALL_ADMIN_${custIdBase}_$companyId';
          String fullCompanyName = selectedcurentcompany?.companyName?.toString() ?? 'COMPANY';
          String titleName = fullCompanyName.trim().split(' ').first;

          await EventsApiClass().sendPushNotification(
            title: 'Visit Started',
            description: '$userName has started the visit for $pName ($vName) at $vTime.',
            topicOverride: targetTopic,
            custIdOverride: custIdBase,
            topicTitleOverride: titleName,
          );
        }
      } catch (e) {
        developer.log('[VisitController] Failed to send start push notification: $e', name: 'VisitController');
      }

      showtoastmessage('Visit started successfully');
    } catch (e) {
      developer.log('Error starting visit: $e', name: 'VisitController', error: e);
      showtoastmessage('Failed to start visit: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> completeVisit(BuildContext context, Map<String, dynamic> visitData) async {
    isSubmitting.value = true;
    try {
      String visitUkeyId = visitData['VisitUkeyId']?.toString() ?? '';

      Map<String, dynamic> updateData = {
        "CompanyId": visitData['CompanyId'],
        "VisitUkeyId": visitUkeyId,
        "VisitName": visitData['VisitName'],
        "PartyId": visitData['PartyId'],
        "VisitTime": visitData['VisitTime'],
        "StartTime": visitData['StartTime'],
        "EndTime": DateTime.now().toIso8601String(),
        "VisitStatus": 'Complete',
        "ImgLogitude": visitData['ImgLogitude'],
        "ImgLatitude": visitData['ImgLatitude'],
        "Remarks": visitData['Remarks'],
        "VisitAssignTo": visitData['VisitAssignTo'],
      };

      developer.log('Completing visit: $visitUkeyId', name: 'VisitController');
      await _visitApis.createUpdateVisit(updateData, flag: 'U');

      // ── Clear Active Visit from Auto-Close Logic ────────
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_visit_data');
        await prefs.remove('active_visit_lat');
        await prefs.remove('active_visit_lng');
      } catch (_) {}
      // ────────────────────────────────────────────────────

      // ── Explicitly log and upload visit complete location to timeline batch ────────
      try {
        if (updateData['ImgLatitude'] != null && updateData['ImgLogitude'] != null && updateData['ImgLatitude'].toString().isNotEmpty && updateData['ImgLogitude'].toString().isNotEmpty) {
          await LocationBatchStorage.appendLocation(
            latitude: double.parse(updateData['ImgLatitude'].toString()),
            longitude: double.parse(updateData['ImgLogitude'].toString()),
            entryTime: DateTime.now(),
          );
        }
        final String userDataStr = await SaveUser().getUserDatas();
        if (userDataStr.isNotEmpty) {
          final dynamic userData = jsonDecode(userDataStr);
          await LocationBatchStorage.uploadPendingBatch(
            userData: userData,
            isMapScreen: false,
            isAppForeground: true,
          );
        }
      } catch (_) {}
      // ──────────────────────────────────────────────────────────

      try {
        if (curentUser != null) {
          String custIdBase = curentUser['CustId']?.toString() ?? curentUser['custid']?.toString() ?? '';
          String companyId = visitData['CompanyId']?.toString() ?? selectedcurentcompany?.companyId.toString() ?? '';
          
          String fName = curentUser['FirstName']?.toString() ?? '';
          String lName = curentUser['LastName']?.toString() ?? '';
          String userName = '$fName $lName'.trim().toUpperCase();

          String pName = visitData['PartyName']?.toString() ?? '';
          String vName = visitData['VisitName']?.toString() ?? '';
          
          DateTime now = DateTime.now();
          String vDate = DateFormat('dd/MM/yyyy').format(now);
          String vTime = DateFormat('hh:mm a').format(now);

          String targetTopic = 'ALL_ADMIN_${custIdBase}_$companyId';
          String fullCompanyName = selectedcurentcompany?.companyName?.toString() ?? 'COMPANY';
          String titleName = fullCompanyName.trim().split(' ').first;

          await EventsApiClass().sendPushNotification(
            title: 'Visit Completed Successfully',
            description: '$userName has successfully completed the visit for $pName ($vName) on $vDate at $vTime.',
            topicOverride: targetTopic,
            custIdOverride: custIdBase,
            topicTitleOverride: titleName,
          );
        }
      } catch (e) {
        developer.log('[VisitController] Failed to send complete push notification: $e', name: 'VisitController');
      }

      showtoastmessage('Visit completed successfully');
    } catch (e) {
      developer.log('Error completing visit: $e', name: 'VisitController', error: e);
      showtoastmessage('Failed to complete visit: $e');
    } finally {
      isSubmitting.value = false;
    }
  }
}
