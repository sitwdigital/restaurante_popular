import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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

class DestaqueItem {
  final String imageUrl;
  final String link;

  DestaqueItem(this.imageUrl, this.link);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DestaqueItem> destaqueItems = [];
  List<NewsItem> noticias = [];
  bool isLoading = true;
  final PageController _destaqueController = PageController();
  Timer? _carouselTimer;

  String dias = '';
  String cafe = '';
  String almoco = '';
  String jantar = '';
  String horarioCafe = '';
  String horarioAlmoco = '';
  String horarioJantar = '';
  String diasFechado = '';
  String valorCafe = '';
  String valorAlmoco = '';
  String valorJantar = '';

  final String _wpBaseUrl = 'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/home';

  @override
  void initState() {
    super.initState();
    fetchAllData();
    _startCarouselAutoScroll();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _destaqueController.dispose();
    super.dispose();
  }

  void _startCarouselAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_destaqueController.hasClients && destaqueItems.isNotEmpty) {
        int nextPage = _destaqueController.page!.round() + 1;
        if (nextPage >= destaqueItems.length) nextPage = 0;
        _destaqueController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(_wpBaseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final acf = data[0]['acf'];

          destaqueItems = [
            if (acf['destaque1'] != null) DestaqueItem(acf['destaque1']['url'], acf['destaque1']['link'] ?? ''),
            if (acf['destaque2'] != null) DestaqueItem(acf['destaque2']['url'], acf['destaque2']['link'] ?? ''),
            if (acf['destaque3'] != null) DestaqueItem(acf['destaque3']['url'], acf['destaque3']['link'] ?? ''),
          ];

          valorCafe = acf['cafe_da_manha'] ?? '';
          valorAlmoco = acf['almoco'] ?? '';
          valorJantar = acf['jantar'] ?? '';
          dias = acf['dias_funcionamento'] ?? '';
          diasFechado = acf['dias_fechado'] ?? '';
          horarioCafe = acf['horario_cafe'] ?? '';
          horarioAlmoco = acf['horario_almoco'] ?? '';
          horarioJantar = acf['horario_jantar'] ?? '';
        }
      }

      await fetchNoticiasOrdenadas();
    } catch (e) {
      print('Erro ao carregar dados do WordPress: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchNoticiasOrdenadas() async {
    try {
      final response = await http.get(Uri.parse(
        'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/noticia?per_page=100&_fields=acf,date'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<NewsItem> loaded = [];

        for (var item in data) {
          final acf = item['acf'];
          if (acf == null) continue;

          final title = acf['titulo'] ?? 'Sem título';
          final rawDate = acf['data'] ?? '';
          final link = acf['link'] ?? '';
          final imageField = acf['imagem'];
          String imageUrl = '';

          if (imageField is String) {
            imageUrl = imageField;
          } else if (imageField is Map && imageField['url'] != null) {
            imageUrl = imageField['url'];
          }

          loaded.add(NewsItem(
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
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          noticias = loaded.take(3).toList();
        });
      }
    } catch (e) {
      print('Erro ao buscar notícias ordenadas: $e');
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
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Destaques', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181))),
                            const SizedBox(height: 4),
                            Text('Veja o prato do dia, avisos e novidades.', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 300,
                              child: PageView.builder(
                                controller: _destaqueController,
                                itemCount: destaqueItems.length,
                                itemBuilder: (context, i) {
                                  final item = destaqueItems[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final Uri url = Uri.parse(item.link);
                                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                          throw Exception('Não foi possível abrir o link');
                                        }
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: screenWidth * 0.9,
                                          child: Image.network(
                                            item.imageUrl,
                                            fit: BoxFit.fitWidth,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: SmoothPageIndicator(
                                controller: _destaqueController,
                                count: destaqueItems.length,
                                effect: WormEffect(
                                  dotColor: Colors.grey.shade300,
                                  activeDotColor: Color(0xFF204181),
                                  dotHeight: 8,
                                  dotWidth: 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildNoticiasSection(screenWidth),
                            const SizedBox(height: 24),
                            _buildValores(),
                            const SizedBox(height: 24),
                            _buildFuncionamento(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticiasSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notícias', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181))),
        const SizedBox(height: 4),
        Text('Acompanhe inaugurações, manutenções e outras notícias dos restaurantes populares.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: noticias.length,
            itemBuilder: (context, i) {
              final item = noticias[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse(item.link);
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      throw Exception('Não foi possível abrir o link da notícia');
                    }
                  },
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
                          child: Image.network(
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
                            item.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Valores', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181))),
        const SizedBox(height: 4),
        Text('Veja os valores acessíveis das refeições.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        _buildValorItem('Café da Manhã', valorCafe, 'cafe.png'),
        _buildValorItem('Almoço', valorAlmoco, 'almoco.png'),
        _buildValorItem('Jantar', valorJantar, 'jantar.png'),
      ],
    );
  }

  Widget _buildValorItem(String tipo, String valor, String imagem) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage('assets/images/$imagem'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tipo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor: R\$ $valor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuncionamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Funcionamento', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181))),
        const SizedBox(height: 4),
        Text('Confira os dias e horários de funcionamento.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        _buildHorarioItem(Icons.check, Colors.green, dias),
        _buildHorarioItem(Icons.check, Colors.green, 'Café da Manhã: $horarioCafe'),
        _buildHorarioItem(Icons.check, Colors.green, 'Almoço: $horarioAlmoco'),
        _buildHorarioItem(Icons.check, Colors.green, 'Jantar: $horarioJantar'),
        _buildHorarioItem(Icons.close, Colors.red, 'Dias fechado: $diasFechado'),
      ],
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
