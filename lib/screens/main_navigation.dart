import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'cardapio_screen.dart';
import 'news_screen.dart';
import 'unidades_screen.dart';
// import 'unidades_screen.dart';
// import 'sobre_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    CardapioScreen(),
    NewsScreen(),
    UnidadesScreen(),
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
