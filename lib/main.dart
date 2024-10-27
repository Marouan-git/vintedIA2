import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart'; 
import 'screens/home_page.dart';
import 'services/onnx_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the ONNX model
  final onnxService = OnnxService();
  await onnxService.initializeModel();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VintedIA2',
      theme: ThemeData(
        primaryColor: Colors.lightBlue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.lightBlue,
        ).copyWith(
          secondary: Colors.lightBlueAccent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.lightBlue,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
