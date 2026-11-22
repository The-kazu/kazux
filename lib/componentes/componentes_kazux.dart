import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tema/tema_aplicativo.dart';

class CabecalhoKazux extends StatelessWidget {
  const CabecalhoKazux({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        color: TemaAplicativo.teal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class BotaoIconeKazux extends StatelessWidget {
  const BotaoIconeKazux({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background = const Color(0x22FFFFFF),
    this.foreground = Colors.white,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}

class CartaoKazux extends StatelessWidget {
  const CartaoKazux({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TituloSecao extends StatelessWidget {
  const TituloSecao(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: TemaAplicativo.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

DateTime inicioMes(DateTime data) => DateTime(data.year, data.month, 1);

DateTime fimMes(DateTime data) =>
    DateTime(data.year, data.month + 1, 0, 23, 59, 59);

DateTime somarMeses(DateTime data, int quantidade) {
  return DateTime(data.year, data.month + quantidade, 1);
}

bool mesmoMes(DateTime data, DateTime mes) {
  return data.year == mes.year && data.month == mes.month;
}

String nomeMesAno(DateTime data) {
  const meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${meses[data.month - 1]} ${data.year}';
}

class SeletorMesKazux extends StatelessWidget {
  const SeletorMesKazux({
    super.key,
    required this.mes,
    required this.onAnterior,
    required this.onProximo,
    this.podeVoltar = true,
    this.podeAvancar = true,
  });

  final DateTime mes;
  final VoidCallback onAnterior;
  final VoidCallback onProximo;
  final bool podeVoltar;
  final bool podeAvancar;

  @override
  Widget build(BuildContext context) {
    return CartaoKazux(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _BotaoMes(
            icon: Icons.chevron_left_rounded,
            onPressed: podeVoltar ? onAnterior : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  nomeMesAno(mes),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TemaAplicativo.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Consulta com limite de 12 meses',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TemaAplicativo.textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _BotaoMes(
            icon: Icons.chevron_right_rounded,
            onPressed: podeAvancar ? onProximo : null,
          ),
        ],
      ),
    );
  }
}

class _BotaoMes extends StatelessWidget {
  const _BotaoMes({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: TemaAplicativo.mint,
        foregroundColor: TemaAplicativo.teal,
        disabledBackgroundColor: TemaAplicativo.surfaceAlt,
        disabledForegroundColor: TemaAplicativo.textLight,
      ),
    );
  }
}

String formatarDataCurta(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

String formatarMilharCampo(String digits) {
  final limpo = digits.replaceAll(RegExp(r'\D'), '');
  if (limpo.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();
  for (var i = 0; i < limpo.length; i++) {
    final fromEnd = limpo.length - i;
    buffer.write(limpo[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

class FormatadorMilharKazux extends TextInputFormatter {
  const FormatadorMilharKazux();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = formatarMilharCampo(newValue.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

String formatarCampoMoeda(num valor) {
  final centavos = (valor * 100).round().toString().padLeft(3, '0');
  final reais = centavos.substring(0, centavos.length - 2);
  final decimais = centavos.substring(centavos.length - 2);
  final buffer = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    final fromEnd = reais.length - i;
    buffer.write(reais[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()},$decimais';
}

class FormatadorMoedaKazux extends TextInputFormatter {
  const FormatadorMoedaKazux();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final centavos = int.parse(digits);
    final texto = formatarCampoMoeda(centavos / 100);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

String formatarMoeda(num valor) {
  final fixed = valor.toStringAsFixed(2);
  final parts = fixed.split('.');
  final buffer = StringBuffer();
  final digits = parts.first;
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'R\$ ${buffer.toString()},${parts.last}';
}

IconData iconePorCategoria(String category) {
  switch (category.toLowerCase()) {
    case 'alimentação':
      return Icons.restaurant_rounded;
    case 'transporte':
      return Icons.directions_car_rounded;
    case 'saúde':
      return Icons.health_and_safety_rounded;
    case 'lazer':
      return Icons.sports_esports_rounded;
    case 'moradia':
      return Icons.home_rounded;
    case 'educação':
      return Icons.menu_book_rounded;
    case 'salário':
      return Icons.work_rounded;
    case 'freela':
      return Icons.laptop_mac_rounded;
    case 'investimento':
      return Icons.trending_up_rounded;
    case 'ajuste':
      return Icons.tune_rounded;
    default:
      return Icons.payments_rounded;
  }
}

Color corPorCategoria(String category) {
  switch (category.toLowerCase()) {
    case 'alimentação':
      return const Color(0xFF4A90D9);
    case 'transporte':
      return TemaAplicativo.teal;
    case 'saúde':
      return const Color(0xFFE05252);
    case 'lazer':
      return const Color(0xFF7B68EE);
    case 'moradia':
      return const Color(0xFFF0C040);
    case 'educação':
      return const Color(0xFF9B6A3E);
    case 'salário':
      return TemaAplicativo.tealLight;
    case 'freela':
      return const Color(0xFF2F80ED);
    case 'investimento':
      return const Color(0xFF27AE60);
    case 'ajuste':
      return TemaAplicativo.danger;
    default:
      return TemaAplicativo.textMid;
  }
}
