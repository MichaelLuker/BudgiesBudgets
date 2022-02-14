import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

// Takes a json object and converts it to a string, base64 encodes it, then gzip it
String compressData(Map<String, dynamic> jsonObject) {
  // Turn the json object into a string
  String stepOne = json.encode(jsonObject);
  // Base 64 encode the string
  List<int> stepOneIntList = utf8.encode(stepOne);
  String stepTwo = base64.encode(stepOneIntList);
  // Gzip the base64 encoded string
  List<int> stepTwoIntList = utf8.encode(stepTwo);
  List<int> stepThree = GZipEncoder().encode(stepTwoIntList)!;
  // Finally return the zipped up data as another base64 encoded string
  return base64.encode(stepThree);
}

// Takes a gziped, base64 encoded, string and converts it to a json object
Map<String, dynamic> decompressData(String data) {
  // First turn the string from b64 to the gzip bytes
  List<int> stepOne = base64.decode(data);
  // Then unzip the content
  List<int> stepTwo = GZipDecoder().decodeBytes(stepOne);
  String stepTwoString = utf8.decode(stepTwo);
  // Then do the other base64 decode
  List<int> stepThree = base64.decode(stepTwoString);
  String stepThreeString = utf8.decode(stepThree);
  // Then turn the string into a json object and return it
  return json.decode(stepThreeString);
}

// Function to wrap a request with the required authentication and compression
Future<Map<String, dynamic>> generateRequestComponents(String path) async {
  // Read the authority and apiKey from the secret file
  String fileContent = await rootBundle.loadString('assets/secret.json');
  Map<String, dynamic> secrets = await json.decode(fileContent);
  String authority = secrets["backendLocation"];
  String apiKey = secrets["apiKey"];
  Uri uri = Uri.https(authority, path);
  Map<String, String> headers = {"apiKey": apiKey};
  return {"uri": uri, "headers": headers};
}
