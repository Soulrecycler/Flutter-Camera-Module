/*
* Created by Shane
* */
import 'package:camera_module/camera_module.dart';

class ImagePreviewScreen extends StatefulWidget {
  final File imageFile;

  const ImagePreviewScreen({Key? key, required this.imageFile})
      : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _imageConfirmed = false;

  // handles on back pressed
  Future<bool> _handleBackNavigation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.discardImageText),
            content: const Text(AppStrings.discardAndGoBackText),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancelButton),
              ),
              TextButton(
                onPressed: () async {
                  await _deleteImageIfExists();
                  Navigator.of(context).pop(true);
                },
                child: const Text(AppStrings.okButton),
              ),
            ],
          ),
        ) ??
        false;
  }

// validates the images
  void _confirmImage() async {
    _imageConfirmed = true;
    // Pop the current screen and pass the image file
    Navigator.pop(context, widget.imageFile);
  }

  // checks of image is in cache and deletes it
  void _discardImage() async {
    await _deleteImageIfExists();
    Navigator.pop(context);
  }

  // Dispose and cleanup
  Future<void> _cleanupImage() async {
    if (!_imageConfirmed &&
        widget.imageFile != null &&
        await widget.imageFile.exists()) {
      await _deleteImageIfExists();
    }
  }

  Future<void> _deleteImageIfExists() async {
    if (await widget.imageFile.exists()) {
      try {
        await widget.imageFile.delete();
      } catch (e) {}
    }
  }

// on destory method
  @override
  void dispose() {
    Future.delayed(
        Duration.zero,
        () =>
            _cleanupImage()); // here we put 0 so all synchronous code runs first and immediately runs the async call
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        // Top bar with back button so users can navigate back
        // and can handle the delete of the image when _handleBackNavigation() will trigger.
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              bool shouldPop = await _handleBackNavigation();
              if (shouldPop) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FutureBuilder<bool>(
                    future: widget.imageFile.exists(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(); // Show a loader while checking
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          !snapshot.data!) {
                        return const Text(AppStrings.imageNotFoundErrorTitle,
                            style: TextStyle(color: Colors.white));
                      } else {
                        return Image.file(widget.imageFile);
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131313),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _discardImage,
                        child: const Text(
                          AppStrings.retakeButton,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: _confirmImage,
                        child: const Text(
                          AppStrings.usePhotoButton,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
