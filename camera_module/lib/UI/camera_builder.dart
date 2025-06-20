/*
* Created by Shane
* */

import 'package:camera_module/camera_module.dart';

class CameraBuilder {
  late String _resolution;
  late String _orientation;
  late bool _boundingBoxEnabled;
  late bool _returnImageAsBase64;

  CameraBuilder setResolution(String resolution) {
    _resolution = resolution;
    return this;
  }

  CameraBuilder setOrientation(String orientation) {
    _orientation = orientation;
    return this;
  }

  CameraBuilder enableBoundingBox(bool boundingboxEnabled) {
    _boundingBoxEnabled = boundingboxEnabled;
    return this;
  }

  CameraBuilder returnImageAsBase64(bool returnImageAsBase64) {
    _returnImageAsBase64 = returnImageAsBase64;
    return this;
  }

  CameraConfig build() {
    return CameraConfig(
      resolution: _resolution,
      orientation: _orientation,
      boundingBoxEnabled: _boundingBoxEnabled,
      returnImageAsBase64: _returnImageAsBase64,
    );
  }
}
