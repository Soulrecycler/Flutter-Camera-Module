# Flutter-Camera-Module
A Flutter module designed to handle camera functionality across platforms with configuration support for resolution, flash, orientation, and bounding boxes.

---

## 🧩 Module Overview

The `camera_module` is a plug-and-play Flutter module that can be embedded into other apps (e.g., native iOS or Android apps) for camera-related tasks.

---

## ✨ Features

- Capture images using the device camera.
- Configurable camera settings via native method channels:
    - Resolution (low, medium, high)
    - Flash toggle
    - Orientation (portrait, landscape)
    - Bounding box overlays (for object detection or alignment)
- Callback support on image capture.
- iOS permission integration.

---

## 📦 Getting Started

### 1. Embed the Flutter module in Android

Refer to [Flutter's official documentation](https://docs.flutter.dev/add-to-app) for how to embed a module into your existing Android project.

# Step 1
    
    - Add this code in the settings.gradle
    
    dependencyResolutionManagement {
      maven {
      url = uri("https://storage.googleapis.com/download.flutter.io")
      }
    }
 
    // Replace "flutter_module" with whatever package_name you supplied when you ran:
    // `$ flutter create -t module [package_name]
    val filePath = settingsDir.parentFile.toString() + "/flutter_module/.android/include_flutter.groovy"
    apply(from = File(filePath))

# Step 2 

    - Add this in MyApp/app/build.gradle
    
    dependencies {
    implementation(project(":flutter"))
    }

# Step 3 

 - Create a Flutter Activity 

you can use this template code :


    class MyFlutterActivity: FlutterActivity() {
    private val CHANNEL = "camera_module/image_channel" // method channel name keep this as it is.
    
        class MyFlutterActivity: FlutterActivity() {
        private val CHANNEL = "camera_module/image_channel"
    
        override fun provideFlutterEngine(context: Context): FlutterEngine? {
            return FlutterEngineCache.getInstance().get("my_engine_id")
        }
    
        override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
            super.configureFlutterEngine(flutterEngine)
    
            val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    
            // Gets images from Flutter
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "onImageCaptured" -> {
                        val imagePath = call.argument<String>("imagePath")
                          // do somthing with the image once back like for example retun it to the button onclick
                              by using startActivityForResult
                        val intent = Intent().putExtra("imagePath", imagePath)
                        setResult(RESULT_OK, intent)
                        finish()
                    }
    
                    // returns to root if permissions are denied 
                    "noCameraPermissionsEncountered" -> {
                        finish()
                    }
    
                    else -> result.notImplemented()
                }
            }
    
            // Send initial config to Flutter
                methodChannel.invokeMethod("sendCameraConfig", mapOf(
                    "resolution" to "high", // values can be set to low,medium,high,very high,ultraHigh,max 
                    "flashEnabled" to false,
                    "orientation" to "portrait",
                    "boundingBoxEnabled" to true,
                ))
           
        }
      }
    }

- Add this to the Manifest 

            <activity
            android:name=".MyFlutterActivity" // change name here as per the activity
            android:configChanges="orientation"
            android:exported="true"/>
    
            <activity
                android:name="io.flutter.embedding.android.FlutterActivity"
                android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
                android:exported="true"
                android:hardwareAccelerated="true"
                android:windowSoftInputMode="adjustResize"
                />

---




