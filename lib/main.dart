import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/home_screen.dart';
import 'screens/cardapio_screen.dart';
import 'screens/news_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/unidades_screen.dart';
import 'screens/sobre_screen.dart';


void main() {
  runApp(const RestaurantePopularApp());
}

class RestaurantePopularApp extends StatelessWidget {
  const RestaurantePopularApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante Popular',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}