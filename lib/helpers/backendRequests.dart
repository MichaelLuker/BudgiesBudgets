// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
Future<Map<String, dynamic>> generateRequestComponents(
    String path, Map<String, dynamic>? params) async {
  // Read the authority and apiKey from the secret file
  String fileContent = await rootBundle.loadString('assets/secret.json');
  Map<String, dynamic> secrets = await json.decode(fileContent);
  String authority = secrets["backendLocation"];
  String apiKey = secrets["apiKey"];
  Uri uri = Uri.https(authority, path, params);
  Map<String, String> headers = {"apikey": apiKey};
  return {"uri": uri, "headers": headers};
}

// Request the transactions in a range
Future<FinancialData> getAllFinancialData(DateTimeRange range) async {
  // Generate request components
  var requestComponents =
      await generateRequestComponents("/getAllFinancialData", {
    "startDate":
        "${range.start.year}-${range.start.month.toString().padLeft(2, "0")}-${range.start.day.toString().padLeft(2, "0")}",
    "endDate":
        "${range.end.year}-${range.end.month.toString().padLeft(2, "0")}-${range.end.day.toString().padLeft(2, "0")}"
  });
  // Make the request
  http.Response response = await http.get(requestComponents["uri"],
      headers: requestComponents["headers"]);
  // Decompress the response
  var temp = decompressData(response.body);
  // Create the object and return it
  FinancialData d = FinancialData.fromJson(temp, range);
  return d;
}

Future<void> uploadMemoImage(Transaction t) async {
  // Read the file bytes
  File(t.memoImagePath!).readAsBytes().then((imageBytes) async {
    // Create a new request for uploading the image
    var requestComponents =
        await generateRequestComponents("/uploadMemoImage", {'guid': t.guid});
    // Send the image bytes to the backend in a compressed way
    String data = compressData({'imageBytes': base64Encode(imageBytes)});
    http.post(requestComponents['uri'],
        headers: requestComponents['headers'], body: data);
  });
}

Future<Uint8List> getMemoImage(String guid) async {
  // Create a new request for uploading the image
  var requestComponents =
      await generateRequestComponents("/getMemoImage", {'guid': guid});
  http.Response response = await http.get(requestComponents['uri'],
      headers: requestComponents['headers']);
  var data = decompressData(response.body);
  return base64Decode(data['imageBytes']);
}

Future<void> deleteMemoImage(String guid) async {
  // Create a new request for uploading the image
  var requestComponents =
      await generateRequestComponents("/deleteMemoImage", {'guid': guid});
  http.post(requestComponents['uri'], headers: requestComponents['headers']);
}

Future<void> writeNewTransaction(Transaction t) async {
  // Generate the request components
  var requestComponents =
      await generateRequestComponents("/writeNewTransaction", {});
  // Send the request off to the backend, compressing the transaction for the body
  http.post(requestComponents["uri"],
      headers: requestComponents["headers"], body: compressData(t.toJson()));
  // If the transaction has a memoImage then upload that too
  if (t.hasMemoImage) {
    uploadMemoImage(t);
  }
}

Future<void> deleteTransaction(Transaction t) async {
  // Generate the request components
  var requestComponents =
      await generateRequestComponents("/deleteTransaction", {});
  // Send the request off to the backend, compressing the transaction for the body
  http.post(requestComponents["uri"],
      headers: requestComponents["headers"], body: compressData(t.toJson()));
}

Future<void> modifyTransaction(Transaction t) async {
  // Generate the request components
  var requestComponents =
      await generateRequestComponents("/modifyTransaction", {});
  // Send the request off to the backend, compressing the transaction for the body
  http.post(requestComponents["uri"],
      headers: requestComponents["headers"], body: compressData(t.toJson()));
  // If the transaction has a memoImage then upload that too
  if (t.hasMemoImage) {
    uploadMemoImage(t);
  }
}
