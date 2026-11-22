import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../servicos/servico_banco_dados.dart';

class TelaEditarConta extends StatefulWidget {
  const TelaEditarConta({super.key, required this.conta});

  final Map<String, dynamic> conta;

  @override
  State<TelaEditarConta> createState() => _TelaEditarContaState();
}

class _TelaEditarContaState extends State<TelaEditarConta> {
  late final TextEditingController nomeController;
  late final TextEditingController tipoController;
  late final TextEditingController saldoController;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(
      text: widget.conta['nome'] as String,
    );
    tipoController = TextEditingController(
      text: widget.conta['tipo'] as String,
    );
    saldoController = TextEditingController(
      text: ((widget.conta['saldoInicial'] as num).toDouble()).toStringAsFixed(
        2,
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    tipoController.dispose();
    saldoController.dispose();
    super.dispose();
  }

  double? _lerSaldo() {
    final texto = saldoController.text
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '');
    if (texto.contains(',')) {
      return double.tryParse(texto.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(texto.replaceAll('.', ''));
  }

  Future<void> _salvar() async {
    final saldo = _lerSaldo();
    if (nomeController.text.trim().isEmpty ||
        tipoController.text.trim().isEmpty ||
        saldo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os dados da conta.')),
      );
      return;
    }

    setState(() => salvando = true);
    try {
      await ServicoBancoDados.atualizarConta(
        id: widget.conta['id'] as int,
        nome: nomeController.text.trim(),
        tipo: tipoController.text.trim(),
        saldoInicial: saldo,
      );
    } on StateError catch (erro) {
      if (mounted) {
        setState(() => salvando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(erro.message)));
      }
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => salvando = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CabecalhoKazux(
            title: 'Editar conta',
            subtitle: 'Altere o nome, tipo ou saldo inicial.',
            leading: BotaoIconeKazux(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CartaoKazux(
                    child: Column(
                      children: [
                        TextField(
                          controller: nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da conta',
                            prefixIcon: Icon(Icons.account_balance_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: tipoController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo da conta',
                            prefixIcon: Icon(Icons.label_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: saldoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Saldo inicial',
                            prefixText: 'R\$ ',
                            prefixIcon: Icon(Icons.savings_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: salvando ? null : _salvar,
                    icon: salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Salvar alterações'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
