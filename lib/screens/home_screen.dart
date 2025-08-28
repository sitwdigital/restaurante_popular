import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Proporção dinâmica (largura/altura) da animação
  double? _bannerAspect;
  static const double _defaultBannerAspect = 382 / 300; // fallback visual

  // URL da animação (ACF)
  String? _animacaoUrl;

  // Notícias
  List<NewsItem> noticias = [];
  bool isLoading = true;

  // Textos/Home
  String dias = '';
  String horarioCafe = '';
  String horarioAlmoco = '';
  String horarioJantar = '';
  String diasFechado = '';
  String valorCafe = '';
  String valorAlmoco = '';
  String valorJantar = '';

  // Link ao tocar no banner (opcional)
  String linkAnimacao = '';

  // Carrossel (até 3 slides usando a mesma animação)
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentSlide = 0;
  static const int _slidesCount = 3;

  int get _effectiveSlidesCount =>
      (_animacaoUrl ?? '').trim().isNotEmpty ? _slidesCount : 1;

  final String _wpBaseUrl =
      'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/home';

  @override
  void initState() {
    super.initState();
    fetchAllData();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_bannerController.hasClients) return;
      final total = _effectiveSlidesCount;
      if (total <= 1) return;
      final next = (_currentSlide + 1) % total;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(_wpBaseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final acf = data[0]['acf'] ?? {};

          // Helpers
          String? _url(dynamic field) {
            if (field == null) return null;
            if (field is String) {
              final u = field.trim();
              return u.isEmpty ? null : u;
            }
            if (field is Map && field['url'] is String) {
              final u = (field['url'] as String).trim();
              return u.isEmpty ? null : u;
            }
            return null;
          }

          bool _isJson(dynamic field) {
            if (field is String) return field.toLowerCase().endsWith('.json');
            if (field is Map) {
              final mime = (field['mime_type'] ?? '').toString().toLowerCase();
              final filename = (field['filename'] ?? '').toString().toLowerCase();
              return mime.contains('application/json') || filename.endsWith('.json');
            }
            return false;
          }

          // Sua API mostra 'acf.destaque1' como JSON (application/json)
          final d1 = acf['destaque1'];
          if (_isJson(d1)) {
            _animacaoUrl = _url(d1);
          } else {
            // fallback: se você criar no futuro um campo ACF 'animacao_destaque'
            _animacaoUrl = _url(acf['animacao_destaque']);
          }

          // Link ao tocar (opcional)
          linkAnimacao =
              (acf['link_destaque1'] ?? acf['link_animacao_destaque'] ?? '')
                  .toString();

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
      // ignore: avoid_print
      print('Erro ao carregar dados do WordPress: $e');
    }

    if (mounted) setState(() => isLoading = false);
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
          } catch (_) {
            return 0;
          }
        });

        if (mounted) {
          setState(() {
            noticias = loaded.take(3).toList();
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar notícias ordenadas: $e');
    }
  }

  Future<void> _handleDestaqueClick(String link) async {
    if (link.isEmpty) return;
    final Uri url = Uri.parse(link);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
          throw 'Erro ao tentar abrir o link: $link';
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao abrir o link: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
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
            // Header
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
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destaques',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: const Color(0xFF046596)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fique por dentro das novidades\ndo Restaurante Popular',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),

                            // ====== CARROSSEL LOTTIE (API only) ======
                            _buildDestaquesLottieCarousel(screenWidth),

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

  // ------------------ Widgets auxiliares ------------------

  Widget _buildDestaquesLottieCarousel(double screenWidth) {
    final aspect = _bannerAspect ?? _defaultBannerAspect;
    final radius = 12.0;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final hasAnim = (_animacaoUrl ?? '').trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        color: bg,
        child: AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _bannerController,
                itemCount: hasAnim ? _slidesCount : 1,
                onPageChanged: (i) => setState(() => _currentSlide = i),
                itemBuilder: (context, i) {
                  final child = _buildLottieFromApiOrPlaceholder();
                  return linkAnimacao.isEmpty
                      ? child
                      : GestureDetector(
                          onTap: () => _handleDestaqueClick(linkAnimacao),
                          child: child,
                        );
                },
              ),

              // Indicador interno (só mostra se tiver +1 slide)
              if (hasAnim)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_slidesCount, (i) {
                          final active = i == _currentSlide;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 28 : 18,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withOpacity(active ? 0.95 : 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLottieFromApiOrPlaceholder() {
    final url = (_animacaoUrl ?? '').trim();
    if (url.isEmpty) return _buildLottiePlaceholder();

    return Lottie.network(
      url,
      fit: BoxFit.contain, // sem cortes; AspectRatio controla o container
      alignment: Alignment.center,
      repeat: true,
      frameRate: FrameRate.max,
      errorBuilder: (context, error, stack) {
        // API-only: sem fallback local
        return _buildLottiePlaceholder();
      },
      onLoaded: (composition) {
        final b = composition.bounds; // Rectangle
        final ratio = (b.width == 0 || b.height == 0)
            ? _defaultBannerAspect
            : b.width / b.height;
        if (mounted &&
            (_bannerAspect == null ||
                (ratio - _bannerAspect!).abs() > 0.005)) {
          setState(() => _bannerAspect = ratio);
        }
      },
    );
  }

  Widget _buildLottiePlaceholder() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Animação não disponível',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiasSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notícias',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: const Color(0xFF046596)),
        ),
        const SizedBox(height: 4),
        Text(
          'Acompanhe as últimas ações e iniciativas\ndo Governo do Maranhão',
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
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse(item.link);
                    if (!await launchUrl(url,
                        mode: LaunchMode.externalApplication)) {
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8.0),
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
        Text(
          'Valores',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: const Color(0xFF046596)),
        ),
        const SizedBox(height: 4),
        Text(
          'Alimentação de qualidade por um\npreço que cabe no seu bolso',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
        Text(
          'Funcionamento',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: const Color(0xFF046596)),
        ),
        const SizedBox(height: 4),
        Text(
          'Confira os dias e horários em que\no Restaurante Popular está aberto',
          style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        _buildHorarioItem(Icons.check, Colors.green, dias),
        _buildHorarioItem(Icons.check, Colors.green, 'Café da Manhã: $horarioCafe'),
        _buildHorarioItem(Icons.check, Colors.green, 'Almoço: $horarioAlmoco'),
        _buildHorarioItem(Icons.check, Colors.green, 'Jantar: $horarioJantar'),
        _buildHorarioItem(Icons.close, Colors.red, 'Dias fechados: $diasFechado'),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
