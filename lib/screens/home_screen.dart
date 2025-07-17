import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NewsItem {
  final String title;
  final String imageUrl;
  final String date;

  NewsItem(this.title, this.imageUrl, this.date);
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

  String status = 'Fechado';
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

  static const _baseUrl = 'http://192.168.15.11:1337';

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      fetchFuncionamento(),
      fetchDestaques(),
      fetchNoticias(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchFuncionamento() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/home-screens'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final homeData = data['data'][0];

        final aberto = homeData['aberto'] ?? false;

        setState(() {
          status = aberto ? 'Aberto' : 'Fechado';
          dias = homeData['dias_funcionamento'] ?? '';
          cafe = homeData['cafe_da_manha'] ?? '';
          almoco = homeData['almoco'] ?? '';
          jantar = homeData['jantar'] ?? '';
          horarioCafe = homeData['horario_cafe'] ?? '';
          horarioAlmoco = homeData['horario_almoco'] ?? '';
          horarioJantar = homeData['horario_jantar'] ?? '';
          diasFechado = homeData['dias_fechado'] ?? '';
          valorCafe = homeData['valor_cafe'] ?? '';
          valorAlmoco = homeData['valor_almoco'] ?? '';
          valorJantar = homeData['valor_jantar'] ?? '';
        });
      }
    } catch (e) {
      print('Erro ao carregar funcionamento: $e');
    }
  }

  Future<void> fetchDestaques() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/homes?populate=imagem'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data']);

        List<DestaqueItem> items = [];

        for (var item in list) {
          String imageUrl = '';
          final link = item['link'] ?? '';

          final imgField = item['imagem'];
          if (imgField is Map) {
            final url = imgField['url'] as String?;
            if (url != null && url.isNotEmpty) {
              imageUrl = '$_baseUrl$url';
            }
          }

          if (imageUrl.isNotEmpty && link.isNotEmpty) {
            items.add(DestaqueItem(imageUrl, link));
          }
        }

        setState(() {
          destaqueItems = items;
        });
      }
    } catch (e) {
      print('Erro ao carregar destaques: $e');
    }
  }

  Future<void> fetchNoticias() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/noticias?populate=imagem'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final noticiasData = List<Map<String, dynamic>>.from(data['data']);

        List<NewsItem> newsList = [];
        for (var n in noticiasData.take(3)) {
          final title = n['titulo'] ?? 'Sem título';
          final date = n['data'] ?? '';
          String imageUrl = '';

          final imgField = n['imagem'];
          if (imgField is Map) {
            final url = imgField['url'] as String?;
            if (url != null && url.isNotEmpty) {
              imageUrl = '$_baseUrl$url';
            }
          }

          newsList.add(NewsItem(title, imageUrl, date));
        }

        setState(() {
          noticias = newsList;
        });
      }
    } catch (e) {
      print('Erro ao carregar notícias: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Destaques', 'Veja o prato do dia, avisos e novidades.', context),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
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
                          const SizedBox(height: 24),
                          _buildSectionTitle('Notícias', 'Acompanhe inaugurações, manutenções e outras notícias.', context),
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
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Valores', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181))),
                          const SizedBox(height: 4),
                          Text('Veja os valores acessíveis das refeições.', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              _buildValorItem('Café da Manhã', valorCafe),
                              _buildValorItem('Almoço', valorAlmoco),
                              _buildValorItem('Jantar', valorJantar),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('Funcionamento', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181))),
                          const SizedBox(height: 4),
                          Text('Confira os dias e horários de funcionamento.', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              _buildHorarioItem(Icons.check, Colors.green, dias),
                              _buildHorarioItem(Icons.check, Colors.green, 'Café da Manhã: $horarioCafe'),
                              _buildHorarioItem(Icons.check, Colors.green, 'Almoço: $horarioAlmoco'),
                              _buildHorarioItem(Icons.check, Colors.green, 'Jantar: $horarioJantar'),
                              _buildHorarioItem(Icons.close, Colors.red, 'Dias fechado: $diasFechado'),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181))),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildValorItem(String title, String valor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor: R\$ $valor',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
