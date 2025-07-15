import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NewsItem {
  final String title;
  final String imageUrl;
  final String date;
  final String link;

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.link,
  });
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool isLoading = true;
  List<NewsItem> todasNoticias = [];
  String busca = '';
  int paginaAtual = 1;
  final int noticiasPorPagina = 5;

  final TextEditingController _buscaController = TextEditingController();

  static const _baseUrl = 'http://192.168.15.21:1337';

  @override
  void initState() {
    super.initState();
    fetchNoticias();
  }

  Future<void> fetchNoticias() async {
    final uri = Uri.parse('$_baseUrl/api/noticias?populate=imagem');
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Status ${res.statusCode}');
      }

      final body = json.decode(res.body);
      final dataList = (body['data'] as List<dynamic>);

      final loaded = <NewsItem>[];
      for (var raw in dataList) {
        final item = Map<String, dynamic>.from(raw);

        final title = item['titulo'] ?? 'Sem título';
        final date = item['data'] ?? '';
        final link = item['link'] ?? '';
        String imageUrl = '';

        // Imagem
        final imgField = item['imagem'];
        if (imgField is Map) {
          final url = imgField['url'] as String?;
          if (url != null && url.isNotEmpty) {
            imageUrl = '$_baseUrl$url';
          }
        }

        loaded.add(NewsItem(
          title: title,
          date: date,
          link: link,
          imageUrl: imageUrl,
        ));
      }

      setState(() {
        todasNoticias = loaded;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar notícias: $e');
      setState(() => isLoading = false);
    }
  }

  List<NewsItem> getNoticiasFiltradas() {
    if (busca.isEmpty) return todasNoticias;
    return todasNoticias
        .where((n) => n.title.toLowerCase().contains(busca.toLowerCase()))
        .toList();
  }

  Future<void> _launchLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o link');
    }
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
                        SvgPicture.asset('assets/images/logo.svg', height: 40),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_none, size: 28, color: Colors.red),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Título e subtítulo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notícias',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Acompanhe inaugurações, manutenções e outras notícias dos restaurantes populares.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Busca
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buscaController,
                            onChanged: (v) {
                              setState(() {
                                busca = v;
                                paginaAtual = 1;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar por notícia',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              busca = _buscaController.text;
                              paginaAtual = 1;
                            });
                          },
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF204181),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.search, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...noticiasPagina.map((noticia) {
                            return GestureDetector(
                              onTap: () {
                                if (noticia.link.isNotEmpty) {
                                  _launchLink(noticia.link);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (noticia.imageUrl.isNotEmpty)
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
                              ),
                            );
                          }).toList(),

                          // Paginação
                          if (totalPaginas > 1) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPaginationButton(Icons.first_page, () {
                                  setState(() => paginaAtual = 1);
                                }),
                                _buildPaginationButton(Icons.chevron_left, () {
                                  if (paginaAtual > 1) setState(() => paginaAtual--);
                                }),
                                ...List.generate(totalPaginas, (i) {
                                  final page = i + 1;
                                  final isCurrent = page == paginaAtual;
                                  return GestureDetector(
                                    onTap: () => setState(() => paginaAtual = page),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCurrent ? const Color(0xFF204181) : const Color(0xFFF2F3F5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$page',
                                        style: TextStyle(
                                          color: isCurrent ? Colors.white : Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                _buildPaginationButton(Icons.chevron_right, () {
                                  if (paginaAtual < totalPaginas) setState(() => paginaAtual++);
                                }),
                                _buildPaginationButton(Icons.last_page, () {
                                  setState(() => paginaAtual = totalPaginas);
                                }),
                              ],
                            ),
                          ],
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
}
