/*
* Created by Shane
* */


// This File holds all imports and maintains clean imports for other screens


//add any import here and call this file


library camera_module;

// Internal screens
export 'UI/screens/camera_screen.dart';
export 'UI/camera_builder.dart';
export 'constants/AppStrings.dart';
export 'utils/camera_config.dart';
export 'UI/screens/image_preview_screen.dart';

//External Plugins
export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:camera/camera.dart';
export 'dart:io';
