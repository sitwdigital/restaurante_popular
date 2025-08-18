import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CardapioScreen extends StatefulWidget {
  const CardapioScreen({super.key});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> with TickerProviderStateMixin {
  final List<String> _diasBase = const ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'];

  String? diaSelecionado;
  bool expandedCafe = false;
  bool expandedAlmoco = false;
  bool expandedJantar = false;

  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> cardapioData = {};
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool notificacoesAtivadas = false;

  late final int _indexHoje;
  late final bool _ehDiaUtil;

  @override
  void initState() {
    super.initState();
    _initNotification();

    final int weekday = DateTime.now().weekday; // 1=Mon..7=Sun
    _ehDiaUtil = weekday >= 1 && weekday <= 5;
    _indexHoje = _ehDiaUtil ? (weekday - 1) : 0;

    diaSelecionado = _diasBase[_indexHoje];

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scrollToDay(_indexHoje);
    });

    fetchCardapio();
  }

  void _scrollToDay(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double targetPosition = index * 120.0 - (screenWidth / 2) + 60;

    _scrollController.animateTo(
      targetPosition < 0 ? 0 : targetPosition,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initNotification() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _ativarNotificacoes() async {
    for (int i = 1; i <= 5; i++) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        i,
        'Confira o cardápio de hoje!',
        'Veja o que será servido no Restaurante Popular MA.',
        _nextInstanceOfTime(i),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cardapio_channel_id',
            'Cardápio Notificações',
            channelDescription: 'Notificações sobre atualizações do cardápio',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
    setState(() => notificacoesAtivadas = true);
  }

  Future<void> _desativarNotificacoes() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    setState(() => notificacoesAtivadas = false);
  }

  tz.TZDateTime _nextInstanceOfTime(int weekday) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  Future<void> fetchCardapio() async {
    try {
      final response = await http.get(Uri.parse('https://sitw.com.br/restaurante_popular/wp-json/wp/v2/cardapio'));
      if (response.statusCode == 200) {
        final List items = json.decode(response.body);
        Map<String, dynamic> parsed = {};

        for (var item in items) {
          final acf = item['acf'] ?? {};
          final dias = acf['diasemana'] ?? [];

          if (dias.isNotEmpty) {
            final dia = dias[0];
            parsed[dia] = {
              'cafe': _splitByCategoria(_extractHtml(acf['cafe'] ?? '')),
              'almoco': _splitByCategoria(_extractHtml(acf['almoco'] ?? '')),
              'jantar': _splitByCategoria(_extractHtml(acf['jantar'] ?? '')),
            };
          }
        }

        setState(() => cardapioData = parsed);
      } else {
        print('Erro ao carregar cardápio: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  String _extractHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
  }

  Map<String, String> _splitByCategoria(String raw) {
    final Map<String, String> categorias = {};
    final regex = RegExp(r'(Prato principal|Acompanhamento|Cereal|Salada|Sobremesa):', caseSensitive: false);
    final matches = regex.allMatches(raw);

    for (int i = 0; i < matches.length; i++) {
      final start = matches.elementAt(i).end;
      final end = i + 1 < matches.length ? matches.elementAt(i + 1).start : raw.length;
      final key = matches.elementAt(i).group(0)!.replaceAll(':', '').trim();
      final value = raw.substring(start, end).trim();
      categorias[key] = value;
    }

    return categorias;
  }

  Map<String, String> getDetalhes(String refeicao) {
    final diaData = cardapioData[diaSelecionado];
    if (diaData != null && diaData[refeicao] != null) {
      final detalhes = diaData[refeicao] as Map<String, dynamic>;
      return detalhes.map((key, value) => MapEntry(key, value.toString()));
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
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
                  SvgPicture.asset('assets/images/logo.svg', height: 40,),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: cardapioData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Cardápio do Dia',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF046596)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecione um dia e consulte o cardápio do café, almoço e jantar.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(_diasBase.length, (i) {
                                final String diaBase = _diasBase[i];
                                final String label = (_ehDiaUtil && i == _indexHoje) ? 'Hoje' : diaBase;
                                final bool isSelected = diaBase == diaSelecionado;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        diaSelecionado = diaBase;
                                        expandedCafe = false;
                                        expandedAlmoco = false;
                                        expandedJantar = false;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF046596) : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF046596) : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Seções com animação 100% vertical
                          _buildCardapioSection(
                            'Café da Manhã',
                            expandedCafe,
                            () => setState(() => expandedCafe = !expandedCafe),
                            getDetalhes('cafe'),
                            'cafe.png',
                          ),
                          const SizedBox(height: 12),
                          _buildCardapioSection(
                            'Almoço',
                            expandedAlmoco,
                            () => setState(() => expandedAlmoco = !expandedAlmoco),
                            getDetalhes('almoco'),
                            'almoco.png',
                          ),
                          const SizedBox(height: 12),
                          _buildCardapioSection(
                            'Jantar',
                            expandedJantar,
                            () => setState(() => expandedJantar = !expandedJantar),
                            getDetalhes('jantar'),
                            'jantar.png',
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

  // ---------- EXPANDABLE VERTICAL LIMPO (sem "abrir para os lados") ----------
  Widget _expandable(bool expanded, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: expanded ? 1 : 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return ClipRect( // corta só no eixo vertical
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: value, // controla APENAS a altura
            child: Opacity(
              opacity: value, // opcional: dá um leve fade-in
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildCardapioSection(
    String label,
    bool expanded,
    VoidCallback onTap,
    Map<String, String> detalhes,
    String imageAsset,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage('assets/images/$imageAsset'),
                fit: BoxFit.cover,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 1))],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ),
              ],
            ),
          ),

          // <<< AQUI trocamos a animação
          _expandable(
            expanded,
            detalhes.isNotEmpty
                ? Container(
                    key: ValueKey(label),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: detalhes.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${entry.key}: ',
                                  style: const TextStyle(
                                    color: Color(0xFFE30613),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: entry.value,
                                  style: const TextStyle(color: Color(0xFF1E1E1E)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
