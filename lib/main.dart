import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'internet_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/cardapio_screen.dart';
import 'screens/news_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/unidades_screen.dart';
import 'screens/sobre_screen.dart';

import 'services/push_notifications_service.dart'; // ✅ novo serviço
import 'models/unidade.dart';

// navigatorKey para navegação por notificações (deep link)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp();

  // Hive (cache local)
  await Hive.initFlutter();
  Hive.registerAdapter(UnidadeAdapter()); // importante pro cache das unidades
  await Hive.openBox('home_cache_box');   // box usada pelo app (e pelas notificações)

  // Inicializa push + listeners (salva no Hive, atualiza badge e deep link)
  await PushNotificationsService.initialize(navigatorKey: navigatorKey);

  runApp(const RestaurantePopularApp());
}

class RestaurantePopularApp extends StatelessWidget {
  const RestaurantePopularApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ necessário pro deep link das notificações
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF046596),
          elevation: 0,
        ),
      ),
      // SplashScreen já protegida
      home: const InternetWrapper(
        child: SplashScreen(),
      ),
      routes: {
        '/home': (context) => const InternetWrapper(child: HomeScreen()),
        '/cardapio': (context) => const InternetWrapper(child: CardapioScreen()),
        '/noticias': (context) => const InternetWrapper(child: NewsScreen()),
        '/navegacao': (context) => const InternetWrapper(child: MainNavigation()),
        '/sobre': (context) => const InternetWrapper(child: SobreScreen()),
        '/unidades': (context) => const InternetWrapper(child: UnidadesScreen()),
      },
    );
  }
}
