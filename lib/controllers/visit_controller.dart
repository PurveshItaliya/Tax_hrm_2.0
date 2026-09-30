import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:tax_hrm/page/visit/visit_camera_screen.dart' as tax_cam;
import 'package:tax_hrm/api/visit_api.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/visit/party_list_model.dart';
import 'package:tax_hrm/utils/randomcguid.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';

class VisitController extends GetxController {
  final VisitApis _visitApis = VisitApis();
  final Employeeclass _employeeServices = Employeeclass();

  var isLoading = false.obs;
  var isSubmitting = false.obs;

  var partyList = <PartyListModel>[].obs;
  var selectedParty = Rxn<PartyListModel>();

  var employeesList = <Employeelists>[].obs;
  var selectedAssignTo = Rxn<Employeelists>();

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
                if (photo != null) attachedDocuments.add(File(photo.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.purple),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) attachedDocuments.add(File(image.path));
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
                    if (file.path != null) attachedDocuments.add(File(file.path!));
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
      
      var parties = await _visitApis.getPartyListDropdown(custId, companyId);
      partyList.assignAll(parties);

      if (curentUser['Role'] == 'Admin') {
        var employees = await _employeeServices.emppppapi();
        employeesList.assignAll(employees);
      }
      developer.log('fetchInitialData completed successfully', name: 'VisitController');
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
    selectedAssignTo.value = null;
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
    if (curentUser != null && curentUser['Role'] == 'Admin' && selectedAssignTo.value == null) {
      showtoastmessage('Please assign to an employee');
      return;
    }

    isSubmitting.value = true;
    try {
      String visitUkeyId = generateGuid();
      String assignTo = curentUser['Role'] == 'Admin' 
          ? selectedAssignTo.value!.id.toString() 
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

      await _visitApis.createUpdateVisit(visitData, flag: 'A');

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
        "VisitAssignTo": assignTo,
      };

      developer.log('Starting visit: $visitUkeyId', name: 'VisitController');
      await _visitApis.createUpdateVisit(updateData, flag: 'U');

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

      showtoastmessage('Visit completed successfully');
    } catch (e) {
      developer.log('Error completing visit: $e', name: 'VisitController', error: e);
      showtoastmessage('Failed to complete visit: $e');
    } finally {
      isSubmitting.value = false;
    }
  }
}
