import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CardapioScreen extends StatefulWidget {
  const CardapioScreen({super.key});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> with TickerProviderStateMixin {
  final List<String> diasSemana = [
    '13/05/2025',
    '14/05/2025',
    '15/05/2025',
    '16/05/2025',
    '17/05/2025',
  ];

  String? diaSelecionado;

  bool expandedCafe = false;
  bool expandedAlmoco = false;
  bool expandedJantar = false;

  @override
  void initState() {
    super.initState();
    diaSelecionado = diasSemana.last;
  }

  Map<String, String> getCardapio(String dia, String refeicao) {
    return {
      'Prato principal': 'Almoço',
      'Acompanhamento': 'Purê de macaxeira',
      'Cereal': 'Arroz branco e feijão verde',
      'Salada': 'Alface crespa, cenoura ralada e beterraba',
      'Sobremesa': 'Melancia',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
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

            Expanded(
              child: SingleChildScrollView(
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
                      'Selecione uma data e consulte o cardápio do café, almoço e jantar.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown azul
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
                        items: diasSemana.map((String value) {
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
                      setState(() {
                        expandedCafe = !expandedCafe;
                      });
                    }, getCardapio(diaSelecionado!, 'cafe')),

                    const SizedBox(height: 12),

                    _buildCardapioSection('Almoço', expandedAlmoco, () {
                      setState(() {
                        expandedAlmoco = !expandedAlmoco;
                      });
                    }, getCardapio(diaSelecionado!, 'almoco')),

                    const SizedBox(height: 12),

                    _buildCardapioSection('Jantar', expandedJantar, () {
                      setState(() {
                        expandedJantar = !expandedJantar;
                      });
                    }, getCardapio(diaSelecionado!, 'jantar')),

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
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Cabeçalho verde com ícone animado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF43B649),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ),
              ],
            ),
          ),

          // Conteúdo animado
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
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
