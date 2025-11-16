import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'map_search_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MapSearchPage(),
  ));
}