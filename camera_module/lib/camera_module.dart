/*
* Created by Shane
* */


// This File holds all imports and maintains clean imports for other screens


//add any import here and call this file


library camera_module;

// Internal screens
export 'UI/screens/camera_screen.dart';
export 'UI/CameraBuilder.dart';
export 'constants/strings.dart';
export 'utils/CameraConfig.dart';
export 'UI/screens/image_preview_screen.dart';

//External Plugins
export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:camera/camera.dart';
export 'package:permission_handler/permission_handler.dart';
export 'dart:io';
