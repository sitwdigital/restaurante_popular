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
    PriceInfo('Café da Manhã', 'R\$ 0,50'),
    PriceInfo('Almoço', 'R\$ 1,00'),
    PriceInfo('Jantar', 'R\$ 1,00'),
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
            // AppBar customizada com sombra
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                    const SizedBox(height: 16),

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
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: noticias.length,
                        itemBuilder: (context, i) {
                          final item = noticias[i];
                          final data = "16/04/2025";

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              width: screenWidth * 0.6,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    child: Image.asset(
                                      item.imageUrl,
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE30613),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      data,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
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
                    const SizedBox(height: 4),
                    Text(
                      'Veja os valores acessíveis das refeições.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: valores.map((v) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43B649), // verde
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Valor: ${v.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Funcionamento
                    Text('Funcionamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF204181),
                            )),
                    const SizedBox(height: 4),
                    Text(
                      'Confira os dias e horários de funcionamento.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _buildHorarioItem(Icons.check_circle, Colors.green, 'Segunda à Sexta'),
                        _buildHorarioItem(Icons.check_circle, Colors.green, 'Café da Manhã: 06h30 às 08h'),
                        _buildHorarioItem(Icons.check_circle, Colors.green, 'Almoço: 11h às 14h'),
                        _buildHorarioItem(Icons.check_circle, Colors.green, 'Jantar: 16h30 às 19h'),
                        _buildHorarioItem(Icons.cancel, Colors.red, 'Sábado, Domingo e Feriados'),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorarioItem(IconData icon, Color iconColor, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
