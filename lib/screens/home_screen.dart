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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> destaqueImages = [];
  List<NewsItem> noticias = [];
  bool isLoading = true;

  String status = 'Fechado';
  String dias = '';
  String cafe = '';
  String almoco = '';
  String jantar = '';
  String valorCafe = '';
  String valorAlmoco = '';
  String valorJantar = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
        'http://192.168.15.12:1337/api/home-screens?populate[noticias][populate]=imagem&populate[destaque1]=*&populate[destaque2]=*',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final attributes = data['data'][0]['attributes'];

        // Destaques
        List<String> destaques = [];
        if (attributes['destaque1'] != null &&
            attributes['destaque1']['data'] != null &&
            attributes['destaque1']['data']['attributes']['url'] != null) {
          final url = attributes['destaque1']['data']['attributes']['url'];
          destaques.add('http://192.168.15.12:1337$url');
        }
        if (attributes['destaque2'] != null &&
            attributes['destaque2']['data'] != null &&
            attributes['destaque2']['data']['attributes']['url'] != null) {
          final url = attributes['destaque2']['data']['attributes']['url'];
          destaques.add('http://192.168.15.12:1337$url');
        }

        // Notícias
        List<NewsItem> newsList = [];
        if (attributes['noticias'] != null && attributes['noticias']['data'] != null) {
          for (var n in attributes['noticias']['data'].take(3)) {
            final attrs = n['attributes'];
            final title = attrs['titulo'] ?? 'Sem título';
            final date = attrs['data'] ?? '';
            String imageUrl = '';

            if (attrs['imagem'] != null &&
                attrs['imagem']['data'] != null &&
                attrs['imagem']['data']['attributes']['url'] != null) {
              final imgUrl = attrs['imagem']['data']['attributes']['url'];
              imageUrl = 'http://192.168.15.12:1337$imgUrl';
            }

            newsList.add(NewsItem(title, imageUrl, date));
          }
        }

        // Funcionamento e valores
        final statusFuncionamento = attributes['status'] ?? 'Fechado';
        final diasFuncionamento = attributes['dias'] ?? '';
        final cafeHorario = attributes['cafe'] ?? '';
        final almocoHorario = attributes['almoco'] ?? '';
        final jantarHorario = attributes['jantar'] ?? '';
        final valorCafeApi = attributes['valor_cafe'] ?? '';
        final valorAlmocoApi = attributes['valor_almoco'] ?? '';
        final valorJantarApi = attributes['valor_jantar'] ?? '';

        setState(() {
          destaqueImages = destaques;
          noticias = newsList;

          status = statusFuncionamento;
          dias = diasFuncionamento;
          cafe = cafeHorario;
          almoco = almocoHorario;
          jantar = jantarHorario;
          valorCafe = valorCafeApi;
          valorAlmoco = valorAlmocoApi;
          valorJantar = valorJantarApi;

          isLoading = false;
        });
      } else {
        print('Erro ao carregar dados: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

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

                  // Conteúdo
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Destaques
                          _buildSectionTitle('Destaques', 'Veja o prato do dia, avisos e novidades.', context),
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
                                    child: Image.network(
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

                          // Funcionamento
                          Text(
                            'Funcionamento',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confira os dias, horários e valores de funcionamento.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              _buildHorarioItem(Icons.info, status == 'Aberto' ? Colors.green : Colors.red, 'Status: $status'),
                              _buildHorarioItem(Icons.calendar_today, Colors.green, 'Dias: $dias'),
                              _buildHorarioItem(Icons.breakfast_dining, Colors.green, 'Café: $cafe (R\$ $valorCafe)'),
                              _buildHorarioItem(Icons.lunch_dining, Colors.green, 'Almoço: $almoco (R\$ $valorAlmoco)'),
                              _buildHorarioItem(Icons.dinner_dining, Colors.green, 'Jantar: $jantar (R\$ $valorJantar)'),
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
