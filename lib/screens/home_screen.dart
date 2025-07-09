import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

// -----------------------------------------------------------------------------
// MODELS DE EXEMPLO
// -----------------------------------------------------------------------------
class NewsItem {
  final String title;
  final String imageUrl;
  const NewsItem(this.title, this.imageUrl);
}

class PriceInfo {
  final String label;
  final String value;
  const PriceInfo(this.label, this.value);
}

// -----------------------------------------------------------------------------
// HOME SCREEN
// -----------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final List<String> destaqueImages = const [
    'assets/images/destaque1.jpg',
    'assets/images/destaque2.jpg',
  ];

  final List<NewsItem> noticias = const [
    NewsItem('Inauguração em São Luís', 'assets/images/noticias1.jpg'),
    NewsItem('Manutenção programada', 'assets/images/noticias2.jpg'),
    NewsItem('Novos pratos da semana', 'assets/images/noticias3.jpg'),
  ];

  final List<PriceInfo> valores = const [
    PriceInfo('Almoço Popular', 'R\$ 1,00'),
    PriceInfo('Jantar Popular', 'R\$ 2,00'),
    PriceInfo('Prato Executivo', 'R\$ 5,00'),
  ];

  const HomeScreen({super.key});

  // Função para abrir o link
  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://maranhaolivredafome.ma.gov.br/#funciona');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar customizado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    height: 40,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 28, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Conteúdo scrollável
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destaques
                    Text('Destaques',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF204181),
                            )),
                    const SizedBox(height: 4),
                    Text(
                      'Veja o prato do dia, avisos e novidades.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: destaqueImages.length,
                        itemBuilder: (context, i) {
                          Widget imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: screenWidth * 0.9,
                              child: Image.asset(
                                destaqueImages[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );

                          // Adiciona GestureDetector no primeiro item
                          if (i == 0) {
                            imageWidget = GestureDetector(
                              onTap: _launchURL,
                              child: imageWidget,
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: imageWidget,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Notícias
                    Text('Notícias',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF204181),
                            )),
                    const SizedBox(height: 4),
                    Text(
                      'Acompanhe inaugurações, manutenções e outras notícias dos restaurantes populares.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: noticias.length,
                        itemBuilder: (context, i) {
                          final item = noticias[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: screenWidth * 0.6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        item.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Valores
                    Text('Valores',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF204181),
                            )),
                    const SizedBox(height: 12),
                    Column(
                      children: valores
                          .map((v) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(v.label),
                                trailing: Text(v.value,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    // Funcionamento
                    Text('Funcionamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF204181),
                            )),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Segunda a Sexta',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 4),
                            Text('11:00 – 14:00'),
                            Divider(height: 20),
                            Text('Sábado e Domingo',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 4),
                            Text('12:00 – 15:00'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
            BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu), label: 'Cardápio'),
            BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Notícias'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Unidades'),
            BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Sobre'),
          ],
          onTap: (i) {
            // implementar navegação
          },
        ),
      ),
    );
  }
}
