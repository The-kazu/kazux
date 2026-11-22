import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../servicos/servico_assistente_ia.dart';
import '../../tema/tema_aplicativo.dart';

class TelaAssistente extends StatefulWidget {
  const TelaAssistente({super.key});

  @override
  State<TelaAssistente> createState() => _TelaAssistenteState();
}

class _TelaAssistenteState extends State<TelaAssistente> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final mensagens = <_MensagemAssistente>[
    const _MensagemAssistente(
      texto:
          'Olá! Sou o Assistente Financeiro do Kazux. Posso analisar seus gastos e, com sua confirmação, registrar transações, metas e limites.',
      doUsuario: false,
    ),
  ];
  bool carregando = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? perguntaRapida]) async {
    final pergunta = (perguntaRapida ?? controller.text).trim();
    if (pergunta.isEmpty || carregando) {
      return;
    }

    setState(() {
      mensagens.add(_MensagemAssistente(texto: pergunta, doUsuario: true));
      carregando = true;
      controller.clear();
    });
    _rolarParaFim();

    try {
      final resposta = await ServicoAssistenteIA.perguntar(pergunta);
      if (!mounted) {
        return;
      }
      setState(() {
        mensagens.add(
          _MensagemAssistente(texto: resposta.texto, doUsuario: false),
        );
      });
      if (resposta.acao?.exigeConfirmacao == true) {
        final confirmou = await _confirmarAcao(resposta.acao!);
        if (confirmou && mounted) {
          try {
            final retorno = await ServicoAssistenteIA.executarAcao(
              resposta.acao!,
            );
            if (mounted) {
              setState(() {
                mensagens.add(
                  _MensagemAssistente(texto: retorno, doUsuario: false),
                );
              });
            }
          } catch (erro) {
            if (mounted) {
              setState(() {
                mensagens.add(
                  _MensagemAssistente(
                    texto:
                        'Não consegui concluir a alteração: ${erro.toString().replaceFirst('Exception: ', '')}',
                    doUsuario: false,
                    erro: true,
                  ),
                );
              });
            }
          }
        }
      }
    } catch (erro) {
      if (!mounted) {
        return;
      }
      setState(() {
        mensagens.add(
          _MensagemAssistente(
            texto: _mensagemDeErro(erro),
            doUsuario: false,
            erro: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => carregando = false);
        _rolarParaFim();
      }
    }
  }

  String _mensagemDeErro(Object erro) {
    final texto = erro.toString().replaceFirst('Exception: ', '');
    if (texto.contains('SocketException') ||
        texto.contains('Connection refused')) {
      return 'A IA ainda não está ligada. Abra o arquivo iniciar_ia.command e mantenha a janela dele aberta antes de perguntar.';
    }
    if (texto.contains('Chave não encontrada')) {
      return 'Cole sua chave no arquivo servidor_ia/.env, depois abra iniciar_ia.command novamente.';
    }
    return 'Não consegui responder agora. Verifique a chave da OpenAI, sua internet e tente novamente. Detalhe: $texto';
  }

  Future<bool> _confirmarAcao(AcaoAssistenteIA acao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar alteração'),
        content: Text(
          '${acao.descricao}\n\nNada será alterado sem a sua confirmação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return confirmar == true;
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const CabecalhoKazux(
            title: 'Assistente Kazux',
            subtitle: 'Análise inteligente das suas finanças',
            leading: CircleAvatar(
              backgroundColor: Color(0x22FFFFFF),
              child: Icon(Icons.smart_toy_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: mensagens.length + (carregando ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == mensagens.length) {
                  return const _IndicadorDigitando();
                }
                return _BolhaMensagem(mensagem: mensagens[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PerguntaRapida(
                  label: 'Resumo do mês',
                  onTap: carregando
                      ? null
                      : () => _enviar('Me dê um resumo do mês.'),
                ),
                _PerguntaRapida(
                  label: 'Onde economizar?',
                  onTap: carregando
                      ? null
                      : () => _enviar(
                          'Em quais gastos posso economizar este mês?',
                        ),
                ),
                _PerguntaRapida(
                  label: 'Minhas metas',
                  onTap: carregando
                      ? null
                      : () => _enviar('Como estão minhas metas financeiras?'),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              14,
              10,
              14,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            color: Colors.white,
            child: Column(
              children: [
                const Text(
                  'A IA usa somente um resumo financeiro do usuário logado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TemaAplicativo.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 600,
                        decoration: const InputDecoration(
                          hintText: 'Pergunte sobre suas finanças...',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _enviar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      onPressed: carregando ? null : _enviar,
                      child: carregando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BolhaMensagem extends StatelessWidget {
  const _BolhaMensagem({required this.mensagem});

  final _MensagemAssistente mensagem;

  @override
  Widget build(BuildContext context) {
    final doUsuario = mensagem.doUsuario;
    return Align(
      alignment: doUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: ValueKey(
          mensagem.erro
              ? 'mensagem_erro_assistente'
              : doUsuario
              ? 'mensagem_usuario'
              : 'mensagem_assistente',
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: doUsuario
              ? TemaAplicativo.teal
              : mensagem.erro
              ? const Color(0xFFFFECEC)
              : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: Radius.circular(doUsuario ? 18 : 5),
            bottomRight: Radius.circular(doUsuario ? 5 : 18),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          mensagem.texto,
          style: TextStyle(
            color: doUsuario
                ? Colors.white
                : mensagem.erro
                ? TemaAplicativo.danger
                : TemaAplicativo.textDark,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _IndicadorDigitando extends StatelessWidget {
  const _IndicadorDigitando();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Chip(
          avatar: SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text('Analisando suas finanças...'),
        ),
      ),
    );
  }
}

class _PerguntaRapida extends StatelessWidget {
  const _PerguntaRapida({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(
        color: TemaAplicativo.teal,
        fontWeight: FontWeight.w800,
      ),
      side: const BorderSide(color: TemaAplicativo.mint),
    );
  }
}

class _MensagemAssistente {
  const _MensagemAssistente({
    required this.texto,
    required this.doUsuario,
    this.erro = false,
  });

  final String texto;
  final bool doUsuario;
  final bool erro;
}
