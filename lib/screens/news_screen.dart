import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final List<Map<String, String>> todasNoticias = List.generate(20, (index) {
    return {
      'title': 'Notícia ${index + 1}: Conheça o programa do Governo do Maranhão',
      'image': 'assets/images/noticias1.jpg',
      'date': '18/04/2025',
    };
  });

  final int noticiasPorPagina = 5;
  int paginaAtual = 1;

  String busca = '';

  List<Map<String, String>> getNoticiasFiltradas() {
    if (busca.isEmpty) return todasNoticias;
    return todasNoticias
        .where((noticia) => noticia['title']!.toLowerCase().contains(busca.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final noticiasFiltradas = getNoticiasFiltradas();
    final totalPaginas = (noticiasFiltradas.length / noticiasPorPagina).ceil();
    final inicio = (paginaAtual - 1) * noticiasPorPagina;
    final fim = (inicio + noticiasPorPagina).clamp(0, noticiasFiltradas.length);

    final noticiasPagina = noticiasFiltradas.sublist(inicio, fim);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar com logo
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Notícias',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acompanhe inaugurações, manutenções e outras notícias dos restaurantes populares.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),

                    // Campo de busca
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                busca = value;
                                paginaAtual = 1;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar por notícia',
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF204181),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lista de notícias
                    Column(
                      children: noticiasPagina.map((noticia) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
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
                                  noticia['image']!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      noticia['title']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE30613),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      noticia['date']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Paginação
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPaginationButton(Icons.first_page, () {
                          setState(() {
                            paginaAtual = 1;
                          });
                        }),
                        _buildPaginationButton(Icons.chevron_left, () {
                          setState(() {
                            if (paginaAtual > 1) paginaAtual--;
                          });
                        }),
                        ...List.generate(totalPaginas, (index) {
                          final pageNumber = index + 1;
                          final isCurrent = pageNumber == paginaAtual;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                paginaAtual = pageNumber;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFF204181) : const Color(0xFFF2F3F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$pageNumber',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }),
                        _buildPaginationButton(Icons.chevron_right, () {
                          setState(() {
                            if (paginaAtual < totalPaginas) paginaAtual++;
                          });
                        }),
                        _buildPaginationButton(Icons.last_page, () {
                          setState(() {
                            paginaAtual = totalPaginas;
                          });
                        }),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16, color: Colors.black),
      ),
    );
  }
}
