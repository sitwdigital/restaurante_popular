import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SobreScreen extends StatelessWidget {
  const SobreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header com logo e ícone de notificação
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
                  SvgPicture.asset('assets/images/logo.svg', height: 40, colorFilter: null,),
                  const Spacer(),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre o Programa',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF046596)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Restaurante Popular do Maranhão! Trata-se de uma iniciativa do Governo do Estado, coordenada pela Secretaria de Estado do Desenvolvimento Social (Sedes), que oferece refeições balanceadas a preços simbólicos para a população em situação de vulnerabilidade social.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Image.asset('assets/images/sobre1.png'),
                    const SizedBox(height: 16),

                    // Texto com destaque
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black, height: 1.5),
                        children: const [
                          TextSpan(text: 'Atualmente, a rede conta com mais de '),
                          TextSpan(
                            text: '180 unidades',
                            style: TextStyle(color: Color(0xFFE30613), fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' distribuídas em 163 municípios maranhenses, sendo considerada '),
                          TextSpan(
                            text: 'a maior rede de segurança alimentar da América Latina.',
                            style: TextStyle(color: Color(0xFFE30613), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Image.asset('assets/images/sobre2.png'),
                    const SizedBox(height: 16),

                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black, height: 1.5),
                        children: const [
                          TextSpan(
                              text:
                                  'São oferecidos café da manhã por R\$ 0,50, almoço e jantar por R\$ 1,00 cada. '),
                          TextSpan(
                            text: 'O valor diário total para as três refeições é de R\$ 2,50.',
                            style: TextStyle(color: Color(0xFFE30613), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Image.asset('assets/images/sobre3.png'),
                    const SizedBox(height: 16),

                    Text(
                      'As unidades operam de segunda a sexta-feira, com almoço das 11h às 14h e jantar das 16h30 às 19h.\n\nCom o objetivo de combater a insegurança alimentar e reduzir a pobreza no estado, garantindo acesso a refeições de qualidade para quem mais precisa.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}