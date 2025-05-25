/*
* Created by Shane
* */

import 'package:camera_module/camera_module.dart';

class CameraBuilder {
  late String _resolution;
  late String _orientation;
  late bool _boundingBoxEnabled;

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

  CameraConfig build() {
    return CameraConfig(
        resolution: _resolution,
        orientation: _orientation,
        boundingBoxEnabled: _boundingBoxEnabled
    );
  }
}
