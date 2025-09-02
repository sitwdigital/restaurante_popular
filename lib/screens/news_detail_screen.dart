import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // ⬅️ novo

import '../models/news_item.dart';

// Paleta
const _primary = Color(0xFF046596); // azul
const _dark    = Color(0xFF32384A);
const _bg      = Color(0xFFF5F6F8);

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.item});
  final NewsItem item;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  String? _contentHtml;
  bool _loading = true;
  String? _error;

  // ====== Fonte (zoom) ======
  double _fontScale = 1.0;         // 100%
  static const double _minScale = .8;   // -20%
  static const double _maxScale = 1.6;  // +60%

  void _incFont() {
    setState(() => _fontScale = (_fontScale + 0.1).clamp(_minScale, _maxScale));
  }

  void _decFont() {
    setState(() => _fontScale = (_fontScale - 0.1).clamp(_minScale, _maxScale));
  }

  // ====== Share ======
  void _shareNews() {
    final title = widget.item.title;
    final link  = (widget.item.link).toString().trim();
    final text  = link.isNotEmpty ? '$title\n$link' : title;
    Share.share(text, subject: title);
  }

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  Future<void> _loadFull() async {
    try {
      final uri = Uri.parse(
        'https://sitw.com.br/restaurante_popular/wp-json/wp/v2/noticia/${widget.item.id}?_fields=content,acf'
      );
      final r = await http.get(uri);
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final j = json.decode(r.body) as Map<String, dynamic>;

      String content = (j['content']?['rendered'] ?? '').toString();
      if (content.trim().isEmpty) {
        final acf = j['acf'];
        if (acf is Map) content = (acf['conteudo'] ?? acf['texto'] ?? '').toString();
      }

      setState(() {
        _contentHtml = _normalizeContentToHtml(content);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Falha ao carregar a notícia.';
        _loading = false;
      });
    }
  }

  // Texto puro -> HTML simples (parágrafos, <br>, **negrito**, *itálico*)
  String _normalizeContentToHtml(String input) {
    final s = input.replaceAll('\r\n', '\n').trim();
    final hasTags = RegExp(r'<[a-zA-Z!/]').hasMatch(s);
    if (s.isEmpty) return '';
    if (hasTags) return s;

    String esc = const HtmlEscape().convert(s);
    esc = esc.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<strong>${m.group(1)}</strong>');
    esc = esc.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => '<em>${m.group(1)}</em>');
    final paragraphs = esc.split(RegExp(r'\n{2,}')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    return paragraphs.map((p) => '<p>${p.replaceAll('\n', '<br/>')}</p>').join();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    const double imageH  = 300;
    const double overlap = 24; // quanto o card sobe na foto
    final hasImg = widget.item.imageUrl.isNotEmpty;

    // tamanhos proporcionais pela escala
    final bodySize = 14.0 * _fontScale;
    final h1Size   = 22.0 * _fontScale;
    final h2Size   = 20.0 * _fontScale;
    final h3Size   = 18.0 * _fontScale;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ===== Scroll =====
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Foto reta (sem radius)
                    if (hasImg)
                      SizedBox(
                        height: imageH,
                        width: double.infinity,
                        child: Hero(
                          tag: 'news-${widget.item.id}',
                          child: Image.network(
                            widget.item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.black12),
                          ),
                        ),
                      ),

                    // Card branco por cima da imagem
                    Padding(
                      padding: EdgeInsets.only(
                        top: hasImg ? (imageH - overlap) : 16,
                        left: 16,
                        right: 16,
                        bottom: 24,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // título fica só no card
                              Text(
                                widget.item.title,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.event, size: 16, color: _primary),
                                  const SizedBox(width: 6),
                                  Text(widget.item.date, style: const TextStyle(fontSize: 13, color: _dark)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_loading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_error != null)
                                Text(_error!, style: const TextStyle(color: _primary))
                              else
                                Html(
                                  data: _contentHtml ?? '',
                                  onLinkTap: (url, attributes, element) {
                                    if (url != null) _openLink(url);
                                  },
                                  style: {
                                    'body': Style(
                                      color: _dark,
                                      fontSize: FontSize(bodySize),
                                      lineHeight: LineHeight.number(1.6),
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                    ),
                                    'p': Style(margin: Margins.only(bottom: 12)),
                                    'h1': Style(fontSize: FontSize(h1Size), fontWeight: FontWeight.w700, margin: Margins.only(bottom: 12)),
                                    'h2': Style(fontSize: FontSize(h2Size), fontWeight: FontWeight.w700, margin: Margins.only(bottom: 10)),
                                    'h3': Style(fontSize: FontSize(h3Size), fontWeight: FontWeight.w700, margin: Margins.only(bottom: 8)),
                                    'a': Style(color: _primary, textDecoration: TextDecoration.underline),
                                    'ul': Style(margin: Margins.only(left: 18, bottom: 12)),
                                    'ol': Style(margin: Margins.only(left: 18, bottom: 12)),
                                    'blockquote': Style(
                                      backgroundColor: _bg,
                                      padding: HtmlPaddings.all(12),
                                      border: const Border(left: BorderSide(color: _primary, width: 3)),
                                      margin: Margins.only(bottom: 12),
                                    ),
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ===== Botão fixo de voltar (top-left) =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _RoundIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // ===== Top-right: A−/A+ e Share =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FontControls(onMinus: _decFont, onPlus: _incFont),
                    const SizedBox(width: 8),
                    _RoundIconButton(
                      icon: Icons.share,
                      onTap: _shareNews,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Widgets de topo ----------
class _FontControls extends StatelessWidget {
  const _FontControls({required this.onMinus, required this.onPlus});
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundTextButton(label: 'A−', onTap: onMinus),
            Container(width: 1, height: 24, color: Colors.black12),
            _RoundTextButton(label: 'A+', onTap: onPlus),
          ],
        ),
      ),
    );
  }
}

class _RoundTextButton extends StatelessWidget {
  const _RoundTextButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: _primary),
        ),
      ),
    );
  }
}
