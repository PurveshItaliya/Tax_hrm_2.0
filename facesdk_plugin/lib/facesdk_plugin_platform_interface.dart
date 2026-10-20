import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'facesdk_plugin_method_channel.dart';

abstract class FacesdkPluginPlatform extends PlatformInterface {
  /// Constructs a FacesdkPluginPlatform.
  FacesdkPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static FacesdkPluginPlatform _instance = MethodChannelFacesdkPlugin();

  /// The default instance of [FacesdkPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelFacesdkPlugin].
  static FacesdkPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FacesdkPluginPlatform] when
  /// they register themselves.
  static set instance(FacesdkPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<int?> setActivation(String license) {
    throw UnimplementedError('setActivation() has not been implemented.');
  }

  Future<int?> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<void> setParam(Map<String, Object> params) {
    throw UnimplementedError('extractFaces() has not been implemented.');
  }

  Future<dynamic> extractFaces(String imagePath) {
    throw UnimplementedError('extractFaces() has not been implemented.');
  }

  Future<dynamic> extractFacesFromBytes(Uint8List imageBytes) {
    throw UnimplementedError('extractFacesFromBytes() has not been implemented.');
  }

  Future<dynamic> extractFacesFromYuv({
    required Uint8List yuvBytes,
    required int width,
    required int height,
    required int cameraMode,
  }) {
    throw UnimplementedError('extractFacesFromYuv() has not been implemented.');
  }

  Future<double?> similarityCalculation(
      Uint8List templates1, Uint8List templates2) {
    throw UnimplementedError(
        'similarityCalculation() has not been implemented.');
  }
}
