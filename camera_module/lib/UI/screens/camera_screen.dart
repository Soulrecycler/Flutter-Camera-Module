import 'package:camera_module/camera_module.dart';
import 'package:image/image.dart' as img;

const platform = MethodChannel('camera_module/image_channel');

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

  // On create method all inititialization done here
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _config = CameraBuilder()
        .setResolution('high') // default set to high
        .setOrientation('portrait') // default set to portrait
        .enableBoundingBox(false) // default set to false
        .build();
    _initializeCamera().then((_) {
      // Only set the method handler AFTER camera is initialized
      platform.setMethodCallHandler(_handleMethodCall);
    });
  }

  // handles the method call "sendCameraConfig which sends the user related data
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'sendCameraConfig':
        if (call.arguments != null && call.arguments is Map) {
          final Map<dynamic, dynamic> args = call.arguments;
          final permissionStatus = await Permission.camera.request();
          if (permissionStatus == PermissionStatus.granted) {
            _config = CameraBuilder()
                .setResolution(args['resolution'] ?? 'high') // default set to high
                .setOrientation(args['orientation'] ?? 'portrait') // default set to portrait
                .enableBoundingBox(args['boundingBoxEnabled'] ?? false) // default set to false
                .build();
            await _initializeCamera();
          } else {
            _showNoPermissionsDialog();
          }
        }
        break;
      default:
    }
  }

  // when permissions are denied this error dialogue will be shown
  Future<void> _showNoPermissionsDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('No camera permissions granted'),
        content: Text('Please grant camera permissions to use the camera.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              platform.invokeMethod("noCameraPermissionsEncountered");
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
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
          config.orientation.toLowerCase() == 'portrait'
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
      case 'low':
        return ResolutionPreset.low;
      case 'medium':
        return ResolutionPreset.medium;
      case 'high':
        return ResolutionPreset.high;
      case 'veryhigh':
        return ResolutionPreset.veryHigh;
      case 'ultrahigh':
        return ResolutionPreset.ultraHigh;
      case 'max':
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
          await platform.invokeMethod('onImageCaptured', {
            'imagePath': confirmedImage.path,
          });
        } catch (e) {
          // Silent fail if running standalone
        }
      } else {
        await _deleteImageIfExists(imageFile);
      }
    } catch (e) {
      _showCameraError("Failed to capture image.");
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

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraReady
          ? Column(
              children: [
                cameraPreviewUi(),
                // CAMERA BUTTON at bottom-center
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton(
                        onPressed: _takePicture,
                        child: Icon(Icons.camera),
                      ),
                    ),
                  ),
                )
              ],
            )

          //Loader is shown when the camera isnt ready
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget cameraPreviewUi() {
    return Stack(
      children: [
        if (_controller != null && _controller!.value.isInitialized)
          CameraPreview(_controller!),
        if (_config.boundingBoxEnabled == true)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}
