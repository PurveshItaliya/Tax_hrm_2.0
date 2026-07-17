import 'package:get/get.dart';
import 'package:tax_hrm/models/fixeddat.dart';

class MainBottomBarController extends GetxController {
  // UI State
  var selectedIndex = 0.obs;
  var fabSelected = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Start background tasks
    _initializeBackgroundTasks();
  }

  void _initializeBackgroundTasks() {
    // These will call repository/service methods later
    // to preload Dashboard, Profile, Shift, etc.
  }

  void changeTab(int index) {
    if (fabSelected.value) {
      fabSelected.value = false;
    }
    selectedIndex.value = index;
  }

  void selectFab() {
    if (curentUser != null && curentUser['Role'] != 'Admin') {
      fabSelected.value = true;
    }
  }

  @override
  void onClose() {
    // Dispose any timers here
    super.onClose();
  }
}
