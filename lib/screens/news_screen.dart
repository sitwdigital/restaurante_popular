import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class NewsItem {
  final String title;
  final String imageUrl;
  final String date;

  NewsItem(this.title, this.imageUrl, this.date);
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsItem> todasNoticias = [];
  bool isLoading = true;

  final int noticiasPorPagina = 5;
  int paginaAtual = 1;
  String busca = '';

  @override
  void initState() {
    super.initState();
    fetchNoticias();
  }

  Future<void> fetchNoticias() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.15.12:1337/api/noticias?populate=*'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final attributes = data['data'][0]['attributes'];

        List<NewsItem> newsList = [];

        for (int i = 1; i <= 7; i++) {
          final noticia = attributes['noticias$i'];
          if (noticia != null) {
            final titulo = noticia['titulo'] ?? 'Sem título';
            final dataNoticia = noticia['data'] ?? '';
            String imageUrl = '';

            if (noticia['imagem'] != null && noticia['imagem']['data'] != null) {
              final url = noticia['imagem']['data']['attributes']['url'];
              imageUrl = 'http://192.168.15.12:1337$url';
            }

            newsList.add(NewsItem(titulo, imageUrl, dataNoticia));
          }
        }

        setState(() {
          todasNoticias = newsList;
          isLoading = false;
        });
      } else {
        print('Erro ao carregar notícias: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  List<NewsItem> getNoticiasFiltradas() {
    if (busca.isEmpty) return todasNoticias;
    return todasNoticias
        .where((noticia) => noticia.title.toLowerCase().contains(busca.toLowerCase()))
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // AppBar
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

                          // Barra de busca
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF204181)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF204181)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF204181),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.search, color: Colors.white),
                              )
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
                                      child: Image.network(
                                        noticia.imageUrl,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey[300],
                                          height: 140,
                                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            noticia.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE30613),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            noticia.date,
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
