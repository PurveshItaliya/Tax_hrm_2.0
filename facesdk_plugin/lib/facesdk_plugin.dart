import 'dart:typed_data';

import 'facesdk_plugin_platform_interface.dart';

class FacesdkPlugin {
  Future<String?> getPlatformVersion() {
    return FacesdkPluginPlatform.instance.getPlatformVersion();
  }

  Future<int?> setActivation(String license) {
    return FacesdkPluginPlatform.instance.setActivation(license);
  }

  Future<int?> init() {
    return FacesdkPluginPlatform.instance.init();
  }

  Future<void> setParam(Map<String, Object> params) async {
    await FacesdkPluginPlatform.instance.setParam(params);
  }

  Future<dynamic> extractFaces(String imagePath) {
    return FacesdkPluginPlatform.instance.extractFaces(imagePath);
  }

  Future<dynamic> extractFacesFromBytes(Uint8List imageBytes) {
    return FacesdkPluginPlatform.instance.extractFacesFromBytes(imageBytes);
  }

  Future<dynamic> extractFacesFromYuv({
    required Uint8List yuvBytes,
    required int width,
    required int height,
    required int cameraMode,
  }) {
    return FacesdkPluginPlatform.instance.extractFacesFromYuv(
      yuvBytes: yuvBytes,
      width: width,
      height: height,
      cameraMode: cameraMode,
    );
  }

  Future<double?> similarityCalculation(
      Uint8List templates1, Uint8List templates2) {
    return FacesdkPluginPlatform.instance
        .similarityCalculation(templates1, templates2);
  }
}
