package com.kbyai.facesdk_plugin

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformViewRegistry
import android.util.Log
import com.kbyai.facesdk.FaceBox
import com.kbyai.facesdk.FaceSDK
import com.kbyai.facesdk.FaceDetectionParam
import com.kbyai.facesdk_plugin.*
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import java.io.File
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** FacesdkPlugin */
class FacesdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private lateinit var registry: PlatformViewRegistry
  private lateinit var dartExecutor: DartExecutor
  private lateinit var context: Context

  companion object {
    private const val TAG = "FacesdkPlugin"
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "facesdk_plugin")
    channel.setMethodCallHandler(this)

    context = flutterPluginBinding.applicationContext

    registry = flutterPluginBinding.flutterEngine.platformViewsController.registry
    dartExecutor = flutterPluginBinding.flutterEngine.dartExecutor
    FaceDetectionFlutterView.livenessDetectionLevel = 0
    Log.i(TAG, "[FacesdkPlugin] Attached to Flutter engine successfully.")
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "setActivation" -> {
        result.success(0)
      }
      "init" -> {
        Log.i(TAG, "[FacesdkPlugin] init called")
        try {
          val ret = FaceSDK.init(context.assets)
          Log.i(TAG, "[FacesdkPlugin] FaceSDK.init returned: $ret (0=SUCCESS)")
          result.success(ret)
        } catch (e: Throwable) {
          Log.e(TAG, "[FacesdkPlugin] FaceSDK.init exception: ${e.message}", e)
          result.success(-5)
        }
      }
      "setParam" -> {
        val checkLivenessLevel: Int? = call.argument("check_liveness_level")
        Log.i(TAG, "[FacesdkPlugin] setParam check_liveness_level: $checkLivenessLevel")
        if (checkLivenessLevel != null) {
          FaceDetectionFlutterView.livenessDetectionLevel = checkLivenessLevel
        }
        result.success(0)
      }
      "extractFaces" -> {
        val imagePath: String? = call.argument("imagePath")
        Log.i(TAG, "[FacesdkPlugin] extractFaces called for: $imagePath")

        if (imagePath.isNullOrEmpty()) {
          Log.w(TAG, "[FacesdkPlugin] extractFaces: imagePath is null or empty")
          result.success(ArrayList<HashMap<String, Any>>())
          return
        }

        val file = File(imagePath)
        if (!file.exists()) {
          Log.w(TAG, "[FacesdkPlugin] extractFaces: file does not exist at $imagePath")
          result.success(ArrayList<HashMap<String, Any>>())
          return
        }

        try {
          val bitmap: Bitmap? = BitmapFactory.decodeFile(imagePath)
          if (bitmap == null) {
            Log.e(TAG, "[FacesdkPlugin] extractFaces: failed to decode bitmap from $imagePath")
            result.success(ArrayList<HashMap<String, Any>>())
            return
          }
          val faceBoxesMap = processBitmap(bitmap)
          result.success(faceBoxesMap)
        } catch (e: Throwable) {
          Log.e(TAG, "[FacesdkPlugin] extractFaces error: ${e.message}", e)
          result.success(ArrayList<HashMap<String, Any>>())
        }
      }
      "extractFacesFromYuv" -> {
        // Native NV21/YUV → Bitmap using FaceSDK.yuv2Bitmap() — same path as reference SampleFrameProcessor
        val yuvBytes: ByteArray? = call.argument("yuvBytes")
        val width: Int = call.argument("width") ?: 0
        val height: Int = call.argument("height") ?: 0
        val cameraMode: Int = call.argument("cameraMode") ?: 7  // 7=front, 6=back

        Log.i(TAG, "[FacesdkPlugin] extractFacesFromYuv called (bytes=${yuvBytes?.size ?: 0}, ${width}x${height}, mode=$cameraMode)")

        if (yuvBytes == null || yuvBytes.isEmpty() || width <= 0 || height <= 0) {
          Log.w(TAG, "[FacesdkPlugin] extractFacesFromYuv: invalid args")
          result.success(ArrayList<HashMap<String, Any>>())
          return
        }

        try {
          // FaceSDK.yuv2Bitmap converts NV21 bytes to upright Bitmap natively (same as CameraBaseView)
          val bitmap: Bitmap = FaceSDK.yuv2Bitmap(yuvBytes, width, height, cameraMode)
          val faceBoxesMap = processBitmap(bitmap)
          bitmap.recycle()
          result.success(faceBoxesMap)
        } catch (e: Throwable) {
          Log.e(TAG, "[FacesdkPlugin] extractFacesFromYuv error: ${e.message}", e)
          result.success(ArrayList<HashMap<String, Any>>())
        }
      }
      "extractFacesFromBytes" -> {
        val imageBytes: ByteArray? = call.argument("imageBytes")
        Log.i(TAG, "[FacesdkPlugin] extractFacesFromBytes called (bytes: ${imageBytes?.size ?: 0})")

        if (imageBytes == null || imageBytes.isEmpty()) {
          Log.w(TAG, "[FacesdkPlugin] extractFacesFromBytes: bytes is null or empty")
          result.success(ArrayList<HashMap<String, Any>>())
          return
        }

        try {
          val bitmap: Bitmap? = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
          if (bitmap == null) {
            Log.e(TAG, "[FacesdkPlugin] extractFacesFromBytes: failed to decode bitmap from byte array")
            result.success(ArrayList<HashMap<String, Any>>())
            return
          }
          val faceBoxesMap = processBitmap(bitmap)
          result.success(faceBoxesMap)
        } catch (e: Throwable) {
          Log.e(TAG, "[FacesdkPlugin] extractFacesFromBytes error: ${e.message}", e)
          result.success(ArrayList<HashMap<String, Any>>())
        }
      }
      "similarityCalculation" -> {
        val templates1: ByteArray? = call.argument("templates1")
        val templates2: ByteArray? = call.argument("templates2")

        if (templates1 == null || templates2 == null || templates1.isEmpty() || templates2.isEmpty()) {
          Log.w(TAG, "[FacesdkPlugin] similarityCalculation: null or empty templates (t1=${templates1?.size ?: 0}, t2=${templates2?.size ?: 0})")
          result.success(0.0f)
          return
        }

        try {
          // Check if these are native FaceSDK templates or raw 768-byte MobileFaceNet float embeddings
          val isFloatVector1 = (templates1.size == 768)
          val isFloatVector2 = (templates2.size == 768)

          if (isFloatVector1 && isFloatVector2) {
            // Fallback: cosine similarity for raw float embeddings
            val bb1 = ByteBuffer.wrap(templates1).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
            val bb2 = ByteBuffer.wrap(templates2).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
            var dot = 0.0f
            var norm1 = 0.0f
            var norm2 = 0.0f
            val count = bb1.remaining()
            for (i in 0 until count) {
              val v1 = bb1.get()
              val v2 = bb2.get()
              dot += v1 * v2
              norm1 += v1 * v1
              norm2 += v2 * v2
            }
            if (norm1 == 0.0f || norm2 == 0.0f) {
              result.success(0.0f)
            } else {
              val sim = (dot / (Math.sqrt(norm1.toDouble()) * Math.sqrt(norm2.toDouble()))).toFloat()
              Log.i(TAG, "[FacesdkPlugin] similarityCalculation: float-vector similarity=$sim")
              result.success(sim.coerceIn(0.0f, 1.0f))
            }
          } else {
            // Official Native FaceSDK similarity calculation
            val similarity: Float = FaceSDK.similarityCalculation(templates1, templates2)
            Log.i(TAG, "[FacesdkPlugin] similarityCalculation: Native FaceSDK similarity=$similarity (t1 size=${templates1.size}, t2 size=${templates2.size})")
            result.success(similarity)
          }
        } catch (e: Throwable) {
          Log.e(TAG, "[FacesdkPlugin] similarityCalculation error: ${e.message}", e)
          result.success(0.0f)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun processBitmap(bitmap: Bitmap): ArrayList<HashMap<String, Any>> {
    val faceBoxesMap = ArrayList<HashMap<String, Any>>()
    val param = FaceDetectionParam()
    param.check_liveness = true
    param.check_liveness_level = FaceDetectionFlutterView.livenessDetectionLevel

    val faceBoxes: List<FaceBox>? = FaceSDK.faceDetection(bitmap, param)
    if (!faceBoxes.isNullOrEmpty()) {
      Log.i(TAG, "[FacesdkPlugin] processBitmap: detected ${faceBoxes.size} face(s)")
      for (face in faceBoxes) {
        val faceImage = Utils.cropFace(bitmap, face)
        val templates = FaceSDK.templateExtraction(bitmap, face)

        val byteArrayOutputStream = ByteArrayOutputStream()
        faceImage.compress(Bitmap.CompressFormat.JPEG, 90, byteArrayOutputStream)
        val faceJpg: ByteArray = byteArrayOutputStream.toByteArray()

        val e = HashMap<String, Any>()
        e["x1"] = face.x1
        e["y1"] = face.y1
        e["x2"] = face.x2
        e["y2"] = face.y2
        e["liveness"] = face.liveness.toDouble()
        e["yaw"] = face.yaw.toDouble()
        e["roll"] = face.roll.toDouble()
        e["pitch"] = face.pitch.toDouble()
        e["templates"] = templates
        e["faceJpg"] = faceJpg
        e["frameWidth"] = bitmap.width
        e["frameHeight"] = bitmap.height
        faceBoxesMap.add(e)

        Log.i(TAG, "[FacesdkPlugin] processBitmap: extracted face at [${face.x1}, ${face.y1}, ${face.x2}, ${face.y2}], " +
            "liveness=${face.liveness}, templateBytes=${templates?.size ?: 0}")
      }
    } else {
      Log.w(TAG, "[FacesdkPlugin] processBitmap: 0 faces detected in bitmap")
    }
    return faceBoxesMap
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(@NonNull binding: ActivityPluginBinding) {
    if (binding.activity != null) {
      registry.registerViewFactory(
        "facedetectionview",
        FaceDetectionViewFactory(binding, dartExecutor)
      )
      Log.i(TAG, "[FacesdkPlugin] Registered PlatformView 'facedetectionview'.")
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {}

  override fun onReattachedToActivityForConfigChanges(@NonNull binding: ActivityPluginBinding) {}

  override fun onDetachedFromActivity() {}
}
