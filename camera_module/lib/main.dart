import 'camera_module.dart';

void main() {
  runApp(MyApp());
}

//Launches the Camera Screen
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Module',
      debugShowCheckedModeBanner: false,
      home: CameraScreen(
      ),
    );
  }
}
