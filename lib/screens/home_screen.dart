import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

// Localização / mapas
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Cache
import 'package:hive/hive.dart';

// Modelos/telas/serviços
import 'package:restaurante_popular/models/unidade.dart';
import 'package:restaurante_popular/models/news_item.dart';
import 'package:restaurante_popular/models/app_notification.dart';
import 'package:restaurante_popular/screens/news_detail_screen.dart';
import 'package:restaurante_popular/screens/notifications_screen.dart';
import 'package:restaurante_popular/services/push_notifications_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------- Chaves de cache ----------
  static const _homeBox = 'home_cache_box';
  static const _newsKey = 'news_list';
  static const _homeKey = 'home_map';
  static const _nearestKey = 'nearest_info';
  static const _notifListKey = 'notifications_list';
  static const _lastUnitsKey = 'last_unidades_ids';
  static const _lastNewsKey = 'last_news_ids';

  // ---------- Banner Lottie ----------
  double? _bannerAspect;
  static const double _defaultBannerAspect = 382 / 300;
  String? _animacaoUrl;

  // ---------- Notícias ----------
  List<NewsItem> noticias = [];
  bool isLoading = true;

  // ---------- Textos/Home ----------
  String dias = '';
  String horarioCafe = '';
  String horarioAlmoco = '';
  String horarioJantar = '';
  String diasFechado = '';
  String valorCafe = '';
  String valorAlmoco = '';
  String valorJantar = '';

  // Link do destaque
  String linkAnimacao = '';

  // Carrossel
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentSlide = 0;
  static const int _slidesCount = 3;

  int get _effectiveSlidesCount =>
      (_animacaoUrl ?? '').trim().isNotEmpty ? _slidesCount : 1;

  final String _wpBaseUrl =
      'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/home';

  // ---------- Unidade mais próxima ----------
  static const double _fatorRotaAprox = 1.25;
  bool _locatingNearest = false;
  double? _nearestKmAprox;
  double? _nearestLat;
  double? _nearestLng;
  String? _nearestNome;

  final String _unidadesEndpointBase =
      'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/unidade';

  // ---------- Badge local (fallback) ----------
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationsFromCache(); // badge inicial
    _loadFromCache();              // home/news/nearest
    _refreshFromApi();             // atualiza e cria notificações internas
    _startAutoScroll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  // ---------- Helpers NewsItem <-> Map ----------
  Map<String, dynamic> _newsToMap(NewsItem n) => {
        'id': n.id,
        'title': n.title,
        'imageUrl': n.imageUrl,
        'date': n.date,
        'link': n.link,
      };

  NewsItem _newsFromMap(Map m) => NewsItem(
        id: (m['id'] is int) ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
        title: (m['title'] ?? '').toString(),
        imageUrl: (m['imageUrl'] ?? '').toString(),
        date: (m['date'] ?? '').toString(),
        link: (m['link'] ?? '').toString(),
      );

  // ---------- Carregamento de cache ----------
  Future<void> _loadFromCache() async {
    try {
      final box = await Hive.openBox(_homeBox);

      // Home
      final Map? homeMap = box.get(_homeKey);
      if (homeMap != null) _applyHomeMap(homeMap, fromCache: true);

      // Notícias
      final List? newsList = box.get(_newsKey);
      if (newsList != null && newsList.isNotEmpty) {
        final cachedNews = newsList.whereType<Map>().map(_newsFromMap).toList();
        if (mounted) setState(() => noticias = cachedNews);
      }

      // Unidade mais próxima
      final Map? nearest = box.get(_nearestKey);
      if (nearest != null) {
        if (mounted) {
          setState(() {
            _locatingNearest = false;
            _nearestKmAprox = (nearest['km'] as num?)?.toDouble();
            _nearestLat     = (nearest['lat'] as num?)?.toDouble();
            _nearestLng     = (nearest['lng'] as num?)?.toDouble();
            _nearestNome    = (nearest['nome'] ?? '') as String?;
          });
        }
      } else {
        if (mounted) setState(() => _locatingNearest = true);
        _initNearestDistance(); // calcula e salva 1x
      }

      if ((homeMap != null || (newsList != null && newsList.isNotEmpty)) && mounted) {
        setState(() => isLoading = false);
      }
    } catch (_) {}
  }

  // ---------- Refresh (API + notificações internas) ----------
  Future<void> _refreshFromApi() async {
    try {
      await _fetchHomeFromApi();
      await _fetchNoticiasFromApi();
      await _checkNewUnidades();   // cria notificação interna se novas unidades
      await _checkNewNoticias();   // cria notificação interna se novas notícias
      await _loadNotificationsFromCache(); // atualiza badge
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------- Home (acf) ----------
  Future<void> _fetchHomeFromApi() async {
    try {
      final response =
          await http.get(Uri.parse(_wpBaseUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data is! List || data.isEmpty) return;

      final acf = data[0]['acf'] ?? {};
      final map = _extractHomeMapFromAcf(acf);

      _applyHomeMap(map);

      final box = await Hive.openBox(_homeBox);
      await box.put(_homeKey, map);
    } catch (_) {}
  }

  Map<String, dynamic> _extractHomeMapFromAcf(Map acf) {
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

    final d1 = acf['destaque1'];
    String? animUrl = _isJson(d1) ? _url(d1) : _url(acf['animacao_destaque']);

    return {
      'animacaoUrl': animUrl ?? '',
      'linkAnimacao':
          (acf['link_destaque1'] ?? acf['link_animacao_destaque'] ?? '').toString(),
      'valorCafe': acf['cafe_da_manha'] ?? '',
      'valorAlmoco': acf['almoco'] ?? '',
      'valorJantar': acf['jantar'] ?? '',
      'dias': acf['dias_funcionamento'] ?? '',
      'diasFechado': acf['dias_fechado'] ?? '',
      'horarioCafe': acf['horario_cafe'] ?? '',
      'horarioAlmoco': acf['horario_almoco'] ?? '',
      'horarioJantar': acf['horario_jantar'] ?? '',
    };
  }

  void _applyHomeMap(Map map, {bool fromCache = false}) {
    final anim = (map['animacaoUrl'] ?? '').toString();
    final link = (map['linkAnimacao'] ?? '').toString();

    if (!mounted) return;
    setState(() {
      _animacaoUrl = anim.isEmpty ? null : anim;
      linkAnimacao = link;

      valorCafe = (map['valorCafe'] ?? '').toString();
      valorAlmoco = (map['valorAlmoco'] ?? '').toString();
      valorJantar = (map['valorJantar'] ?? '').toString();

      dias = (map['dias'] ?? '').toString();
      diasFechado = (map['diasFechado'] ?? '').toString();
      horarioCafe = (map['horarioCafe'] ?? '').toString();
      horarioAlmoco = (map['horarioAlmoco'] ?? '').toString();
      horarioJantar = (map['horarioJantar'] ?? '').toString();
    });
  }

  // ---------- Notícias (lista/top3) ----------
  Future<void> _fetchNoticiasFromApi() async {
    try {
      final response = await http
          .get(Uri.parse(
              'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/noticia?per_page=100&_fields=id,acf,date'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;

      final List<dynamic> data = json.decode(response.body);
      final List<NewsItem> loaded = [];

      for (var item in data) {
        final acf = item['acf'];
        if (acf == null) continue;

        final int id = (item['id'] ?? 0) is int
            ? item['id'] as int
            : int.tryParse('${item['id']}') ?? 0;

        final title = (acf['titulo'] ?? 'Sem título').toString();
        final rawDate = (acf['data'] ?? '').toString();
        final link = (acf['link'] ?? '').toString();

        final imageField = acf['imagem'];
        String imageUrl = '';
        if (imageField is String) {
          imageUrl = imageField;
        } else if (imageField is Map && imageField['url'] != null) {
          imageUrl = imageField['url'];
        }

        loaded.add(NewsItem(
          id: id, title: title, date: rawDate, link: link, imageUrl: imageUrl,
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

      final top3 = loaded.take(3).toList();

      if (mounted) setState(() => noticias = top3);

      final box = await Hive.openBox(_homeBox);
      await box.put(_newsKey, top3.map(_newsToMap).toList());
    } catch (_) {}
  }

  // ---------- Notificações (internas) ----------
  Future<void> _loadNotificationsFromCache() async {
    try {
      final box = await Hive.openBox(_homeBox);
      final raw = (box.get(_notifListKey) as List?)?.whereType<Map>().toList() ?? [];
      final list = raw.map(AppNotification.fromMap).toList();
      if (mounted) setState(() => _unreadCount = list.where((n) => !n.read).length);
    } catch (_) {}
  }

  Future<void> _saveNotifications(List<AppNotification> list) async {
    final box = await Hive.openBox(_homeBox);
    await box.put(_notifListKey, list.map((e) => e.toMap()).toList());
    if (mounted) setState(() => _unreadCount = list.where((n) => !n.read).length);
  }

  Future<void> _checkNewUnidades() async {
    try {
      final unidades = await _fetchUnidadesPaged();
      final currentIds = unidades.map((u) => u.id).whereType<int>().toSet();

      final box = await Hive.openBox(_homeBox);
      final lastIdsList = (box.get(_lastUnitsKey) as List?)?.whereType<int>().toList();

      // primeira execução: só cacheia ids
      if (lastIdsList == null) {
        await box.put(_lastUnitsKey, currentIds.toList());
        return;
      }

      final lastIds = lastIdsList.toSet();
      final newIds = currentIds.difference(lastIds);
      if (newIds.isEmpty) return;

      // notificações atuais
      final rawNotifs = (box.get(_notifListKey) as List?)?.whereType<Map>().toList() ?? [];
      final list = rawNotifs.map(AppNotification.fromMap).toList();

      final byId = {for (final u in unidades) u.id: u};
      final now = DateTime.now();

      for (final nid in newIds) {
        final u = byId[nid];
        list.insert(
          0,
          AppNotification(
            id: 'unidade_${nid}_$now',
            title: 'Novo Restaurante Popular',
            message: 'A unidade ${u?.nome ?? 'desconhecida'} foi adicionada.',
            createdAt: now,
            type: 'unidade_adicionada',
            read: false,
          ),
        );
      }

      await _saveNotifications(list);
      await box.put(_lastUnitsKey, currentIds.toList());
    } catch (_) {}
  }

  Future<void> _checkNewNoticias() async {
    try {
      final response = await http.get(Uri.parse(
        'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/noticia?per_page=100&_fields=id,acf,date'
      ));
      if (response.statusCode != 200) return;

      final List<dynamic> data = json.decode(response.body);
      final currentIds = data.map((n) => n['id'] as int).toSet();

      final box = await Hive.openBox(_homeBox);
      final lastIdsList = (box.get(_lastNewsKey) as List?)?.whereType<int>().toList();

      // primeira execução: só salva
      if (lastIdsList == null) {
        await box.put(_lastNewsKey, currentIds.toList());
        return;
      }

      final lastIds = lastIdsList.toSet();
      final newIds = currentIds.difference(lastIds);
      if (newIds.isEmpty) return;

      // notificações atuais
      final rawNotifs = (box.get(_notifListKey) as List?)?.whereType<Map>().toList() ?? [];
      final list = rawNotifs.map(AppNotification.fromMap).toList();

      final now = DateTime.now();
      for (var n in data) {
        if (!newIds.contains(n['id'])) continue;
        final acf = n['acf'] ?? {};
        final title = (acf['titulo'] ?? 'Nova notícia').toString();
        list.insert(
          0,
          AppNotification(
            id: 'noticia_${n['id']}_$now',
            title: 'Nova notícia',
            message: 'Uma nova notícia foi publicada: $title',
            createdAt: now,
            type: 'noticia_adicionada',
            read: false,
          ),
        );
      }

      await _saveNotifications(list);
      await box.put(_lastNewsKey, currentIds.toList());
    } catch (_) {}
  }

  // ---------- Localização + unidade mais próxima ----------
  Future<void> _initNearestDistance() async {
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) {
        if (mounted) {
          setState(() {
            _locatingNearest = false;
            _nearestKmAprox = null;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLoc = LatLng(pos.latitude, pos.longitude);

      final unidades = await _fetchUnidadesPaged();
      if (unidades.isEmpty) {
        if (mounted) {
          setState(() {
            _locatingNearest = false;
            _nearestKmAprox = null;
          });
        }
        return;
      }

      for (final u in unidades) {
        u.calcularDistancia(userLoc);
      }
      unidades.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
      final nearest = unidades.first;

      final kmReta = nearest.distanciaKm;
      final kmAprox = kmReta * _fatorRotaAprox;

      if (mounted) {
        setState(() {
          _locatingNearest = false;
          _nearestKmAprox = kmAprox;
          _nearestLat = nearest.latitude;
          _nearestLng = nearest.longitude;
          _nearestNome = nearest.nome;
        });
      }

      final box = await Hive.openBox(_homeBox);
      await box.put(_nearestKey, {
        'km': kmAprox,
        'lat': nearest.latitude,
        'lng': nearest.longitude,
        'nome': nearest.nome,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _locatingNearest = false;
          _nearestKmAprox = null;
        });
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;
    status = await Permission.location.request();
    return status.isGranted;
  }

  Future<List<Unidade>> _fetchUnidadesPaged() async {
    final List<Unidade> all = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final url = '$_unidadesEndpointBase?per_page=50&page=$page';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) break;

      final List data = jsonDecode(res.body) as List;
      if (data.isEmpty) {
        hasMore = false;
      } else {
        all.addAll(data.map((e) => Unidade.fromWpJson(e)).toList());
        page++;
      }
    }
    return all;
  }

  Future<void> _abrirRotaMaisProxima() async {
    if (_nearestLat == null || _nearestLng == null) return;
    final lat = _nearestLat!;
    final lng = _nearestLng!;
    final google =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(google)) {
      await launchUrl(google, mode: LaunchMode.externalApplication);
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
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    }
  }

  // ---------- Auto scroll ----------
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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header com logo + sininho
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
                  ValueListenableBuilder<int>(
                    valueListenable: PushNotificationsService.unreadCount,
                    builder: (_, unread, __) {
                      final show = unread > 0 ? unread : _unreadCount;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF046596),
                            ),
                            onPressed: () async {
                              await PushNotificationsService.markAllRead();

                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                              if (changed == true) {
                                // atualiza pelo serviço e por garantia local
                                _loadNotificationsFromCache();
                              }
                            },
                          ),
                          if (show > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB72B30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                child: Text(
                                  show > 9 ? '9+' : '$show',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
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
                            _buildNearestBanner(),
                            const SizedBox(height: 16),
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

  // ---------- Banner "Pertinho de você" ----------
  Widget _buildNearestBanner() {
    const green = Color(0xFF009C46);
    const primary = Color(0xFF046596);

    String distanciaText;
    if (_locatingNearest) {
      distanciaText = 'Localizando…';
    } else if (_nearestKmAprox != null) {
      final kmStr = _nearestKmAprox!.toStringAsFixed(1).replaceAll('.', ',');
      distanciaText = 'O mais próximo está a $kmStr km de você';
    } else {
      distanciaText = 'Ative a localização para ver a unidade mais próxima';
    }

    final baseStyle = const TextStyle(color: Colors.white, fontSize: 16);

    // Deixa apenas “X,X km” em negrito
    Widget distanciaWidget;
    if (_nearestKmAprox != null) {
      final kmChunk =
          '${_nearestKmAprox!.toStringAsFixed(1).replaceAll('.', ',')} km';
      final full = distanciaText;
      final idx = full.indexOf(kmChunk);

      distanciaWidget = (idx >= 0)
          ? RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: baseStyle,
                children: [
                  TextSpan(text: full.substring(0, idx)),
                  TextSpan(
                      text: kmChunk,
                      style: baseStyle.copyWith(fontWeight: FontWeight.w800)),
                  TextSpan(text: full.substring(idx + kmChunk.length)),
                ],
              ),
            )
          : Text(full, textAlign: TextAlign.center, style: baseStyle);
    } else {
      distanciaWidget =
          Text(distanciaText, textAlign: TextAlign.center, style: baseStyle);
    }

    VoidCallback? onPressed;
    String ctaLabel;
    IconData ctaIcon = Icons.arrow_forward_rounded;

    if (_locatingNearest) {
      onPressed = null;
      ctaLabel = 'Buscando...';
    } else if (_nearestKmAprox != null) {
      onPressed = _abrirRotaMaisProxima;
      ctaLabel = 'Saiba como chegar';
    } else {
      onPressed = () async {
        final ok = await _ensureLocationPermission();
        if (ok) {
          setState(() {
            _locatingNearest = true;
            _nearestKmAprox = null;
          });
          _initNearestDistance();
        }
      };
      ctaLabel = 'Ativar localização';
      ctaIcon = Icons.my_location;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Pertinho de você',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          distanciaWidget,
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              icon: Icon(ctaIcon, size: 18),
              label: Text(ctaLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Destaques ----------
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
    if (url.isEmpty) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Animação não disponível',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Lottie.network(
      url,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      repeat: true,
      frameRate: FrameRate.max,
      errorBuilder: (_, __, ___) => Container(color: Colors.white),
      onLoaded: (composition) {
        final b = composition.bounds;
        final ratio =
            (b.width == 0 || b.height == 0) ? _defaultBannerAspect : b.width / b.height;
        if (mounted &&
            (_bannerAspect == null || (ratio - _bannerAspect!).abs() > 0.005)) {
          setState(() => _bannerAspect = ratio);
        }
      },
    );
  }

  // ---------- Notícias (cards) ----------
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailScreen(item: item),
                      ),
                    );
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
                        Hero(
                          tag: 'news-${item.id}',
                          child: ClipRRect(
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

  // ---------- Valores ----------
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
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ---------- Funcionamento ----------
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
          'Confira as últimas informações de dias e horários',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
