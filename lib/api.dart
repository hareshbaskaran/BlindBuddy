import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String> postImage(String url, File imageFile) async {
  var request = http.MultipartRequest('POST', Uri.parse(url));
  request.files.add(http.MultipartFile.fromBytes('image', imageFile.readAsBytesSync())); // Assuming JPEG format

  var response = await request.send();

  if (response.statusCode == 200) {
    // Successful upload
    var responseString = await response.stream.transform(utf8.decoder).join();
    return responseString;
  } else {
    // Handle error
    print('Error uploading image: ${response.statusCode}');
    throw Exception('Failed to upload image');
  }
}
