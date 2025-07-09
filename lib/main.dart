import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/cardapio_screen.dart';
import 'screens/news_screen.dart';
// import 'screens/unidades_screen.dart';
// import 'screens/sobre_screen.dart';

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
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CardapioScreen(),
    NewsScreen(),
    // UnidadesScreen(),
    // SobreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Cardápio'),
            BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Notícias'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Unidades'),
            BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Sobre'),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
