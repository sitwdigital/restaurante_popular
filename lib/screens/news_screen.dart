import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/news_item.dart';
import 'news_detail_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  static const _baseUrl = 'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/noticia';

  @override
  void initState() {
    super.initState();
    fetchNoticias();
  }

  String _normalizeMultiline(String s) {
    if (s.isEmpty) return s;
    String out = s
        .replaceAll('<br />', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br>', '\n')
        .replaceAll(r'\n', '\n');

    out = out.split('\n').map((l) => l.trimLeft()).join('\n');
    return out.trimLeft();
  }

  Future<void> fetchNoticias() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode != 200) throw Exception('Erro ${response.statusCode}');

      final List<dynamic> data = json.decode(response.body);
      final List<NewsItem> loaded = [];

      for (var item in data) {
        final acf = item['acf'];
        if (acf == null) continue;

        final int id = (item['id'] ?? 0) is int ? item['id'] as int : int.tryParse('${item['id']}') ?? 0;

        String title = (acf['titulo'] ?? 'Sem título').toString();
        title = _normalizeMultiline(title);

        final rawDate = (acf['data'] ?? '').toString().trim();
        final link = (acf['link'] ?? '').toString().trim();

        final imageField = acf['imagem'];
        String imageUrl = '';
        if (imageField is String) {
          imageUrl = imageField;
        } else if (imageField is Map && imageField['url'] != null) {
          imageUrl = imageField['url'];
        }

        loaded.add(NewsItem(
          id: id,
          title: title,
          date: rawDate,
          link: link,
          imageUrl: imageUrl,
        ));
      }

      loaded.sort((a, b) {
        try {
          final dateA = DateFormat('dd/MM/yyyy').parse(a.date);
          final dateB = DateFormat('dd/MM/yyyy').parse(b.date);
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
      });

      setState(() {
        todasNoticias = loaded;
        isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar notícias: $e');
      setState(() => isLoading = false);
    }
  }

  List<NewsItem> getNoticiasFiltradas() {
    if (busca.isEmpty) return todasNoticias;
    return todasNoticias.where((n) => n.title.toLowerCase().contains(busca.toLowerCase())).toList();
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

  void _irParaPagina(int novaPagina) {
    setState(() => paginaAtual = novaPagina);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final noticiasFiltradas = getNoticiasFiltradas();
    final totalPaginas = (noticiasFiltradas.length / noticiasPorPagina).ceil().clamp(1, 9999);
    final inicio = ((paginaAtual - 1) * noticiasPorPagina).clamp(0, noticiasFiltradas.length);
    final fim = (inicio + noticiasPorPagina).clamp(0, noticiasFiltradas.length);
    final noticiasPagina = noticiasFiltradas.sublist(inicio, fim);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // topo
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/images/logo.svg', height: 40),
                        const Spacer(),
                      ],
                    ),
                  ),
                  // título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notícias', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF046596))),
                        const SizedBox(height: 4),
                        Text(
                          'Acompanhe inaugurações, manutenções e outras notícias dos restaurantes populares',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // busca
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buscaController,
                            onChanged: (v) => setState(() { busca = v; paginaAtual = 1; }),
                            decoration: InputDecoration(
                              hintText: 'Buscar por notícia',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF046596)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF046596)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() { busca = _buscaController.text; paginaAtual = 1; }),
                          child: Container(
                            height: 48, width: 48,
                            decoration: BoxDecoration(color: const Color(0xFF046596), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.search, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // lista
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...noticiasPagina.map((noticia) => GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(item: noticia)));
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
                                        Hero(
                                          tag: 'news-${noticia.id}',
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                            child: Image.network(noticia.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(noticia.title,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE30613))),
                                            const SizedBox(height: 6),
                                            Text(noticia.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                          if (totalPaginas > 1) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPaginationButton(Icons.first_page, () => _irParaPagina(1)),
                                _buildPaginationButton(Icons.chevron_left, () { if (paginaAtual > 1) _irParaPagina(paginaAtual - 1); }),
                                ...List.generate(totalPaginas, (i) {
                                  final page = i + 1;
                                  final isCurrent = page == paginaAtual;
                                  return GestureDetector(
                                    onTap: () => _irParaPagina(page),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCurrent ? const Color(0xFF046596) : const Color(0xFFF2F3F5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('$page', style: TextStyle(color: isCurrent ? Colors.white : Colors.black, fontSize: 12)),
                                    ),
                                  );
                                }),
                                _buildPaginationButton(Icons.chevron_right, () { if (paginaAtual < totalPaginas) _irParaPagina(paginaAtual + 1); }),
                                _buildPaginationButton(Icons.last_page, () => _irParaPagina(totalPaginas)),
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
