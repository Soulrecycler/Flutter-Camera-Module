class AppStrings {

  // General Messages or Titles
  static const String okButton = 'OK';
  static const String cancelButton = 'Cancel';
  static const String cameraErrorTitle = 'Camera Error';
  static const String cameraErrorMessage = 'No camera found on this device.';
  static const String failedToLoadCameraMessage = 'Failed to initialize the camera.';
  static const String heroTitleImagePreviewCancelButton = 'imagePreviewCancelButton';
  static const String heroTitleImagePreviewConfirmButton = 'imagePreviewConfirmButton';
  static const String imageNotFoundErrorTitle= 'Image not found';
  static const String discardAndGoBackText='Are you sure you want to discard and go back?';
  static const String discardImageText='Discard image?';
  static const String cameraModuleTitle='Camera Module';
  static const String defaultResolution='high';
  static const String defaultOrientation='portrait';
  static const String imagePathText='imagePath';
  static const String imageBase64Text='imageBase64';
  static const String failedToCaptureImageErrorMessage='Failed to capture image.';
  static const String resolutionArgs='resolution';
  static const String orientationArgs='orientation';
  static const String boundingBoxEnabledArgs='boundingBoxEnabled';
  static const String returnImageAsBase64Args='returnImageAsBase64';
  static const String retakeButton='Retake';
  static const String usePhotoButton='Use Photo';


  // Resolution values
  static const String resolutionLow='low';
  static const String resolutionMedium='medium';
  static const String resolutionHigh='high';
  static const String resolutionVeryhigh='veryhigh';
  static const String resolutionUltrahigh='ultrahigh';
  static const String resolutionMax='max';


  // Channel Name
  static const String cameraMethodChannelName='camera_module/image_channel';

  //Method Call Names
  static const String cameraConfigMethodCall='sendCameraConfig';
  static const String onImageCapturedMethodCall='onImageCaptured';
}