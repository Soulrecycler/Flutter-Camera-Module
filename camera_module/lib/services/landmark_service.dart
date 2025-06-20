import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LandmarkService {
  final ImageLabeler _labeler = ImageLabeler(options: ImageLabelerOptions());

  Future<String?> detectLandmark(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labels = await _labeler.processImage(inputImage);
    for (final label in labels) {
      if (label.confidence > 0.7) {
        return label.label;
      }
    }
    return null;
  }

  Future<String?> fetchWikipediaSummary(String query) async {
    final url = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query)}',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['extract'];
    }
    return null;
  }

  Future<String?> detectLandmarkCloud(File imageFile, [String? apiKey]) async {
    final key = apiKey ?? 'AIzaSyD7qR9poyOskJPuz4uU-ur9c65CRTBaelA';
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$key';
    final body = jsonEncode({
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "LANDMARK_DETECTION", "maxResults": 1}
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final landmark = data['responses'][0]['landmarkAnnotations']?[0]?['description'];
      return landmark;
    } else {
      print('Error: \\${response.body}');
      return null;
    }
  }

  void dispose() {
    _labeler.close();
  }
} 