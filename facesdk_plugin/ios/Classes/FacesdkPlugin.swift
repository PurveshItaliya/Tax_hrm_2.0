import Flutter
import UIKit

public class FacesdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "facesdk_plugin", binaryMessenger: registrar.messenger())
    let instance = FacesdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    registrar.register(FaceDetectionViewFactory(registrar: registrar), withId: "facedetectionview")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments
    let myArgs = args as? [String: Any]

    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "setActivation":
      if let license = myArgs?["license"] as? String, !license.isEmpty {
        _ = FaceSDK.setActivation(license)
      }
      result(0)

    case "init":
      let ret = FaceSDK.initSDK()
      result(ret)

    case "setParam":
      result(0)

    case "extractFaces":
      guard let imagePath = myArgs?["imagePath"] as? String, !imagePath.isEmpty else {
        result([])
        return
      }
      if !FileManager.default.fileExists(atPath: imagePath) {
        result([])
        return
      }
      guard let image = UIImage(contentsOfFile: imagePath)?.fixOrientation() else {
        result([])
        return
      }
      let faceBoxes = processImage(image)
      result(faceBoxes)

    case "extractFacesFromBytes":
      guard let byteData = myArgs?["imageBytes"] as? FlutterStandardTypedData else {
        result([])
        return
      }
      guard let image = UIImage(data: byteData.data)?.fixOrientation() else {
        result([])
        return
      }
      let faceBoxes = processImage(image)
      result(faceBoxes)

    case "extractFacesFromYuv":
      result([])

    case "similarityCalculation":
      guard let t1 = myArgs?["templates1"] as? FlutterStandardTypedData,
            let t2 = myArgs?["templates2"] as? FlutterStandardTypedData else {
        result(0.0)
        return
      }
      let data1 = t1.data
      let data2 = t2.data

      if data1.isEmpty || data2.isEmpty {
        result(0.0)
        return
      }

      // Check if these are 768-byte MobileFaceNet float embeddings
      if data1.count == 768 && data2.count == 768 {
        let count = 768 / MemoryLayout<Float>.size
        let floats1 = data1.withUnsafeBytes { ptr in
          Array(UnsafeBufferPointer(start: ptr.baseAddress!.assumingMemoryBound(to: Float.self), count: count))
        }
        let floats2 = data2.withUnsafeBytes { ptr in
          Array(UnsafeBufferPointer(start: ptr.baseAddress!.assumingMemoryBound(to: Float.self), count: count))
        }

        var dot: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        for i in 0..<count {
          let v1 = floats1[i]
          let v2 = floats2[i]
          dot += v1 * v2
          norm1 += v1 * v1
          norm2 += v2 * v2
        }

        if norm1 == 0.0 || norm2 == 0.0 {
          result(0.0)
        } else {
          let sim = dot / (sqrt(norm1) * sqrt(norm2))
          result(Double(max(0.0, min(1.0, sim))))
        }
      } else {
        let similarity = FaceSDK.similarityCalculation(data1, templates2: data2)
        result(Double(similarity))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func processImage(_ image: UIImage) -> [[String: Any]] {
    guard let faceBoxes = FaceSDK.faceDetection(image) as? [FaceBox], !faceBoxes.isEmpty else {
      return []
    }

    var resultList: [[String: Any]] = []
    for face in faceBoxes {
      let templates = FaceSDK.templateExtraction(image, faceBox: face) ?? Data()
      let faceImage = image.cropFace(faceBox: face)
      let faceJpg = faceImage?.jpegData(compressionQuality: 1.0) ?? Data()

      var faceDic: [String: Any] = [:]
      faceDic["x1"] = face.x1
      faceDic["y1"] = face.y1
      faceDic["x2"] = face.x2
      faceDic["y2"] = face.y2
      faceDic["liveness"] = face.liveness
      faceDic["yaw"] = face.yaw
      faceDic["roll"] = face.roll
      faceDic["pitch"] = face.pitch
      faceDic["templates"] = templates
      faceDic["faceJpg"] = faceJpg
      faceDic["frameWidth"] = Int(image.size.width)
      faceDic["frameHeight"] = Int(image.size.height)

      resultList.append(faceDic)
    }
    return resultList
  }
}

