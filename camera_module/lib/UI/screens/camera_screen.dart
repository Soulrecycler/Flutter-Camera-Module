import 'dart:convert';

import 'package:camera_module/camera_module.dart';
import 'package:image/image.dart' as img;
import 'package:camera_module/services/landmark_service.dart';

const platform = MethodChannel(AppStrings.cameraMethodChannelName);

class CameraScreen extends StatefulWidget {
  final CameraConfig? config;

  const CameraScreen({
    Key? key,
    this.config,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraReady = false;
  List<CameraDescription> _cameras = [];
  late CameraConfig _config;

  // Landmark detection
  final LandmarkService _landmarkService = LandmarkService();
  String? _landmarkName;
  String? _landmarkDescription;
  bool _isDetecting = false;

  // On create method all inititialization done here
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _config = CameraBuilder()
        .setResolution(AppStrings.defaultResolution) // default set to high
        .setOrientation(
            AppStrings.defaultOrientation) // default set to portrait
        .enableBoundingBox(false) // default set to false
        .returnImageAsBase64(false)
        .build();
    _initializeCamera().then((_) {
      // Only set the method handler AFTER camera is initialized
      platform.setMethodCallHandler(_handleMethodCall);
    });
  }

  // handles the method call "sendCameraConfig which sends the user related data
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case AppStrings.cameraConfigMethodCall:
        if (call.arguments != null && call.arguments is Map) {
          final Map<dynamic, dynamic> args = call.arguments;
          _config = CameraBuilder()
              .setResolution(args[AppStrings.resolutionArgs] ??
                  AppStrings.defaultResolution) // default set to high
              .setOrientation(args[AppStrings.orientationArgs] ??
                  AppStrings.defaultOrientation) // default set to portrait
              .enableBoundingBox(
                  args[AppStrings.boundingBoxEnabledArgs] ?? false)
              .returnImageAsBase64(args[AppStrings.returnImageAsBase64Args] ??
                  false) // default set to false
              .build();
          await _initializeCamera();
        }
        break;
      default:
    }
  }

  // The main function that initializes the camera
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showCameraError(AppStrings.cameraErrorMessage);
        return;
      }

      final config = widget.config;
      final resolution = config != null
          ? _getResolutionPreset(config.resolution)
          : ResolutionPreset.high;

      _controller =
          CameraController(_cameras[0], resolution, enableAudio: false);
      await _controller!.initialize();

      if (config != null && config.orientation.isNotEmpty) {
        await _controller!.lockCaptureOrientation(
          config.orientation.toLowerCase() == AppStrings.defaultOrientation
              ? DeviceOrientation.portraitUp
              : DeviceOrientation.landscapeLeft,
        );
      }

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      _showCameraError(AppStrings.failedToLoadCameraMessage);
    }
  }

  //Gets user resolution and adds it in the initilization of the camera
  ResolutionPreset _getResolutionPreset(String value) {
    switch (value.toLowerCase()) {
      case AppStrings.resolutionLow:
        return ResolutionPreset.low;
      case AppStrings.resolutionMedium:
        return ResolutionPreset.medium;
      case AppStrings.resolutionHigh:
        return ResolutionPreset.high;
      case AppStrings.resolutionVeryhigh:
        return ResolutionPreset.veryHigh;
      case AppStrings.resolutionUltrahigh:
        return ResolutionPreset.ultraHigh;
      case AppStrings.resolutionMax:
        return ResolutionPreset.max;
      default:
        return ResolutionPreset.high;
    }
  }

  //takes picture and navigates to the next image preview screen
  //on callback -> we invoke the method call "onImageCaptured"
  // this retuns the image to the root app
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final xFile = await _controller!.takePicture();
      final correctedImage = await _rotateImageIfNeeded(xFile.path);
      final imageFile = File(correctedImage.path);

      final confirmedImage = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(imageFile: imageFile),
        ),
      );

      if (confirmedImage != null) {
        try {
          //Checks if User chooses to return the image as Base64 else returns imagePath as default
          if (_config.returnImageAsBase64) {
            final Uint8List bytes = await confirmedImage.readAsBytes();
            await _deleteImageIfExists(confirmedImage);
            final String base64String = base64Encode(bytes);
            await platform.invokeMethod(AppStrings.onImageCapturedMethodCall, {
              AppStrings.imageBase64Text: base64String,
            });
          } else {
            await platform.invokeMethod(AppStrings.onImageCapturedMethodCall, {
              AppStrings.imagePathText: confirmedImage.path,
            });
          }
        } catch (e) {
          // Silent fail if running standalone
        }
      } else {
        await _deleteImageIfExists(imageFile);
      }
    } catch (e) {
      _showCameraError(AppStrings.failedToCaptureImageErrorMessage);
    }
  }

  //This fixes an issue where images are saved in a landscape
  // DO NOT change the orientation of the image here
  Future<File> _rotateImageIfNeeded(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) return file;
    final rotatedImage = img.copyRotate(originalImage,
        angle: 0); // Do NOT change the angle value here
    await file.writeAsBytes(img.encodeJpg(rotatedImage));
    return file;
  }

  //Deletes the image when "X" is clicked or instance is destroyed
  Future<void> _deleteImageIfExists(File image) async {
    if (await image.exists()) {
      await image.delete();
    }
  }

  // Shows error when the camera inst available
  void _showCameraError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.cameraErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.okButton),
          )
        ],
      ),
    );
  }

  //on destroy
  @override
  void dispose() {
    _controller?.dispose();
    _landmarkService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _detectLandmark() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDetecting) return;
    setState(() {
      _isDetecting = true;
      _landmarkName = null;
      _landmarkDescription = null;
    });
    try {
      final xFile = await _controller!.takePicture();
      final file = File(xFile.path);
      final landmark = await _landmarkService.detectLandmark(file);
      if (landmark != null) {
        final description = await _landmarkService.fetchWikipediaSummary(landmark);
        setState(() {
          _landmarkName = landmark;
          _landmarkDescription = description ?? 'No description found.';
        });
      } else {
        setState(() {
          _landmarkName = 'No landmark detected.';
          _landmarkDescription = null;
        });
      }
    } catch (e) {
      setState(() {
        _landmarkName = 'Error detecting landmark.';
        _landmarkDescription = null;
      });
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraReady
          ? SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        cameraPreviewUi(),
                        if (_landmarkName != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 170,
                            child: Card(
                              color: Colors.black.withOpacity(0.7),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _landmarkName!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if (_landmarkDescription != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _landmarkDescription!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_isDetecting)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                  bottomCameraButtons(),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget cameraPreviewUi() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double boundingBoxSize = width - 30; // 10 padding on each side
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_controller != null && _controller!.value.isInitialized)
                CameraPreview(_controller!),
              if (_config.boundingBoxEnabled == true)
                Center(
                  child: Container(
                    height: boundingBoxSize,
                    width: boundingBoxSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget bottomCameraButtons() {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          //  Left: Cancel Button
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              backgroundColor: Colors.black.withAlpha(128),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => SystemNavigator.pop(),
              ),
            ),
          ),
          // Center: Camera Button
          Center(
            child: FloatingActionButton(
              onPressed: _takePicture,
              child: const Icon(Icons.camera),
            ),
          ),
          // Right: Landmark Detection Button
          Align(
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              backgroundColor: Colors.black.withAlpha(128),
              child: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: _detectLandmark,
                tooltip: 'Detect Landmark',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
