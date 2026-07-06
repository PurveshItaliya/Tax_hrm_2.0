// ignore_for_file: strict_top_level_inference, empty_catches

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tax_hrm/api/notesapi.dart';
import 'package:tax_hrm/models/notes/getnotes.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';

class NotesProviders extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  TextEditingController txtNotesController = TextEditingController();
  TextEditingController txtNotesDecController = TextEditingController();
  final userNotesFormKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  File? images;

  List<GetNotes>  mainUserNotesList = [];
  List<GetNotes>  showUserNotesList = [];

  loadingData() async {
    try {  
      showUserNotesList = [];
      txtNotesController.clear();
      setloading(true);
      await getAllNotes();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  getAllNotes() async {
    try {
      await NotesApisServices().getNotesData().then((value) {
        mainUserNotesList = value;
        showUserNotesList = value;
    }).onError((error, stackTrace) {
      setloading(false);
    },);
    } catch (e) { /* ignored */ }
  }

  // search all events
  void searchAllNotesData(String inputText) {
    final query = inputText.toLowerCase();
    showUserNotesList = mainUserNotesList.where((element) {return element.message.toString().toLowerCase().contains(query);}).toList();
    notifyListeners(); // ✅ ONLY HERE
  }

  notesHandleSubmit(context,size) {
    images = null;
    txtNotesDecController.clear();
    showAddNotesDialog(context,size: size);
  }

  submitNotImage() {
    images = null;
    notifyListeners();
  }

  addNotesHandleSubmit(context) {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      if (userNotesFormKey.currentState!.validate()) {
        Navigator.pop(context);
        setloading(true);
        NotesApisServices().createNewNotes(files: images,messages: txtNotesDecController.text,listenRes: (val) {
          if (val['Success'] == true) {
            txtNotesDecController.clear(); images = null; loadingData();
          }
        });
        autovalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
    }
  }

  Future<void> getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage != null) {
      images = File(pickedImage.path);
      notifyListeners();
    }
  }
}
