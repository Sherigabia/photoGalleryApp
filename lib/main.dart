import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:photo_gallery_app/homeView.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhotoGallery',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
            elevation: 1,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.blue)),
      ),
      darkTheme: ThemeData.dark().copyWith(
          appBarTheme: const AppBarTheme(
              elevation: 1, iconTheme: IconThemeData(color: Colors.blue))),
      themeMode: ThemeMode.system,
      home: const HomeView(),
    );
  }
}
