import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class CardapioScreen extends StatefulWidget {
  const CardapioScreen({super.key});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> with TickerProviderStateMixin {
  final List<String> diasemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'];
  String? diaSelecionado;
  bool expandedCafe = false;
  bool expandedAlmoco = false;
  bool expandedJantar = false;

  Map<String, dynamic> cardapioData = {};

  @override
  void initState() {
    super.initState();
    diaSelecionado = diasemana.first;
    fetchCardapio();
  }

  Future<void> fetchCardapio() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.15.11:1337/api/cardapio-do-dias'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['data'];
        Map<String, dynamic> parsed = {};

        for (var item in items) {
          String dia = item['diasemana'];

          String extractText(List<dynamic> blocks) {
            return blocks.map((block) {
              if (block['children'] != null && block['children'].isNotEmpty) {
                return block['children'][0]['text'];
              }
              return '';
            }).join('\n');
          }

          parsed[dia] = {
            'cafe': {'Prato': extractText(item['cafe'] ?? [])},
            'almoco': {'Prato': extractText(item['almoco'] ?? [])},
            'jantar': {'Prato': extractText(item['jantar'] ?? [])},
          };
        }

        setState(() => cardapioData = parsed);
      } else {
        print('Erro ao carregar cardápio: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF204181)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecione um dia e consulte o cardápio do café, almoço e jantar.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF204181),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: diaSelecionado,
                              dropdownColor: const Color(0xFF204181),
                              isExpanded: true,
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(color: Colors.white),
                              underline: const SizedBox(),
                              items: diasemana.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  diaSelecionado = value;
                                  expandedCafe = false;
                                  expandedAlmoco = false;
                                  expandedJantar = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCardapioSection('Café da Manhã', expandedCafe, () {
                            setState(() => expandedCafe = !expandedCafe);
                          }, getDetalhes('cafe'), 'cafe.png'),
                          const SizedBox(height: 12),
                          _buildCardapioSection('Almoço', expandedAlmoco, () {
                            setState(() => expandedAlmoco = !expandedAlmoco);
                          }, getDetalhes('almoco'), 'almoco.png'),
                          const SizedBox(height: 12),
                          _buildCardapioSection('Jantar', expandedJantar, () {
                            setState(() => expandedJantar = !expandedJantar);
                          }, getDetalhes('jantar'), 'jantar.png'),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded && detalhes.isNotEmpty
                ? Container(
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
                                  style: const TextStyle(
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
