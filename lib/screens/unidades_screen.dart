import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Unidade {
  final String nome;
  final String endereco;
  final String imagemUrl;
  final double avaliacao;
  final bool aberto;

  const Unidade({
    required this.nome,
    required this.endereco,
    required this.imagemUrl,
    required this.avaliacao,
    required this.aberto,
  });
}

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  int paginaAtual = 1;
  final int itensPorPagina = 5;

  final List<Unidade> todasUnidades = List.generate(
    20,
    (index) => Unidade(
      nome: "Restaurante Coroado",
      endereco: "Avenida dos Africanos, Nº 100 B",
      imagemUrl: "assets/images/coroado.jpg",
      avaliacao: 4.3,
      aberto: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final int inicio = (paginaAtual - 1) * itensPorPagina;
    final int fim = (inicio + itensPorPagina) > todasUnidades.length
        ? todasUnidades.length
        : inicio + itensPorPagina;
    final unidadesPagina = todasUnidades.sublist(inicio, fim);
    final totalPaginas = (todasUnidades.length / itensPorPagina).ceil();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SvgPicture.asset('assets/images/logo.svg', height: 40),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.red),
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
                    const Text(
                      'Unidades',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF204181)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Encontre todas as unidades por cidade ou bairro. Consulte endereço, contato e horário de cada uma.',
                    ),
                    const SizedBox(height: 12),

                    // Barra de busca
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por cidade ou bairro',
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF204181)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF204181)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF204181),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.search, color: Colors.white),
                        )
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Mapa com gradiente
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/mapa_fake.jpg',
                            height: 260,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.8), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ...unidadesPagina.map((u) => _buildUnidadeItem(u)).toList(),

                    const SizedBox(height: 16),
                    _buildPaginacao(totalPaginas),
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

  Widget _buildUnidadeItem(Unidade unidade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              unidade.imagemUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unidade.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("${unidade.avaliacao}", style: const TextStyle(fontSize: 14)),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const Text(" (505)", style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(unidade.endereco, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: unidade.aberto ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unidade.aberto ? "Aberto" : "Fechado",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginacao(int totalPaginas) {
    List<Widget> paginas = [];

    paginas.add(_pageButton('«', () => setState(() => paginaAtual = 1), disabled: paginaAtual == 1));
    paginas.add(_pageButton('<', () => setState(() => paginaAtual = (paginaAtual - 1).clamp(1, totalPaginas)), disabled: paginaAtual == 1));

    for (int i = 1; i <= totalPaginas; i++) {
      paginas.add(_pageButton(
        '$i',
        () => setState(() => paginaAtual = i),
        isCurrent: paginaAtual == i,
      ));
    }

    paginas.add(_pageButton('>', () => setState(() => paginaAtual = (paginaAtual + 1).clamp(1, totalPaginas)), disabled: paginaAtual == totalPaginas));
    paginas.add(_pageButton('»', () => setState(() => paginaAtual = totalPaginas), disabled: paginaAtual == totalPaginas));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: paginas,
    );
  }

  Widget _pageButton(String text, VoidCallback onPressed, {bool isCurrent = false, bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF204181)
              : const Color(0xFFF2F3F5),
          shape: BoxShape.circle,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
