import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';

class TelaEditarMeta extends StatefulWidget {
  const TelaEditarMeta({super.key, this.meta});

  final Map<String, dynamic>? meta;

  @override
  State<TelaEditarMeta> createState() => _TelaEditarMetaState();
}

class _TelaEditarMetaState extends State<TelaEditarMeta> {
  late final TextEditingController nomeController;
  late final TextEditingController alvoController;
  late final TextEditingController atualController;
  bool salvando = false;
  late DateTime prazo;

  bool get editando => widget.meta != null;

  @override
  void initState() {
    super.initState();
    final meta = widget.meta;
    nomeController = TextEditingController(
      text: meta?['nome'] as String? ?? '',
    );
    alvoController = TextEditingController(
      text: meta == null
          ? ''
          : formatarMilharCampo(
              ((meta['valorAlvo'] as num).toDouble()).toStringAsFixed(0),
            ),
    );
    atualController = TextEditingController(
      text: meta == null
          ? ''
          : formatarMilharCampo(
              ((meta['valorAtual'] as num).toDouble()).toStringAsFixed(0),
            ),
    );
    prazo =
        DateTime.tryParse((meta?['prazo'] as String?) ?? '') ??
        DateTime.now().add(const Duration(days: 180));
  }

  @override
  void dispose() {
    nomeController.dispose();
    alvoController.dispose();
    atualController.dispose();
    super.dispose();
  }

  double? _parseMoney(String valor) {
    final texto = valor.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (texto.contains(',')) {
      return double.tryParse(texto.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(texto.replaceAll('.', ''));
  }

  Future<void> _selecionarPrazo() async {
    final hoje = DateTime.now();
    final dataInicial = prazo.isBefore(hoje) ? hoje : prazo;
    final selecionada = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 3650)),
    );

    if (selecionada != null) {
      setState(() => prazo = selecionada);
    }
  }

  Future<void> _salvar() async {
    final alvo = _parseMoney(alvoController.text);
    final atual = _parseMoney(atualController.text) ?? 0;

    if (nomeController.text.trim().isEmpty || alvo == null || alvo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e valor alvo válidos.')),
      );
      return;
    }

    setState(() => salvando = true);
    final metaAtual = widget.meta;
    final data = {
      'nome': nomeController.text.trim(),
      'valorAlvo': alvo,
      'valorAtual': atual < 0 ? 0.0 : atual,
      'prazo': prazo.toIso8601String(),
      'icone': (metaAtual?['icone'] as String?) ?? 'shield',
      'cor': (metaAtual?['cor'] as String?) ?? 'teal',
    };

    if (editando) {
      await ServicoBancoDados.atualizarMeta(
        id: metaAtual!['id'] as int,
        meta: data,
      );
    } else {
      await ServicoBancoDados.inserirMeta(data);
    }

    if (!mounted) {
      return;
    }
    setState(() => salvando = false);
    Navigator.pop(context, true);
  }

  Future<void> _apagar() async {
    final meta = widget.meta;
    if (meta == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar meta?'),
        content: Text('A meta "${meta['nome']}" será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ServicoBancoDados.removerMeta(meta['id'] as int);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CabecalhoKazux(
            title: editando ? 'Editar meta' : 'Nova meta',
            subtitle: 'Defina o objetivo e acompanhe o progresso.',
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
                            labelText: 'Nome da meta',
                            prefixIcon: Icon(Icons.flag_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: alvoController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [FormatadorMilharKazux()],
                          decoration: const InputDecoration(
                            labelText: 'Valor alvo',
                            prefixText: 'R\$ ',
                            suffixText: ',00',
                            prefixIcon: Icon(Icons.savings_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: atualController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [FormatadorMilharKazux()],
                          decoration: const InputDecoration(
                            labelText: 'Valor atual',
                            prefixText: 'R\$ ',
                            suffixText: ',00',
                            prefixIcon: Icon(Icons.trending_up_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _selecionarPrazo,
                          icon: const Icon(Icons.event_rounded),
                          label: Text(
                            'Data da meta: ${formatarDataCurta(prazo)}',
                          ),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: TemaAplicativo.teal,
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
                    label: Text(editando ? 'Salvar alterações' : 'Salvar meta'),
                  ),
                  if (editando) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: salvando ? null : _apagar,
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Apagar meta'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: TemaAplicativo.danger,
                        side: const BorderSide(color: TemaAplicativo.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
