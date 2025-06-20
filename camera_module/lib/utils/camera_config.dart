/*
* Created by Shane
* */

class CameraConfig {
  final String resolution;
  final String orientation;
  final bool boundingBoxEnabled;
  final bool returnImageAsBase64;

  CameraConfig(
      {required this.resolution,
      required this.orientation,
      required this.boundingBoxEnabled,
      required this.returnImageAsBase64});
}
