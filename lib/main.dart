import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'internet_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/cardapio_screen.dart';
import 'screens/news_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/unidades_screen.dart';
import 'screens/sobre_screen.dart';
import 'services/push_service.dart';
import 'models/unidade.dart';

// Handler de mensagens em segundo plano (push com app fechado ou em background)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔙 Notificação recebida em segundo plano: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Registrar handler para notificações em segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar notificações locais
  await PushService.init();

  // Inicializar Hive (cache local)
  await Hive.initFlutter();
  Hive.registerAdapter(UnidadeAdapter()); // importante pro cache das unidades

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
