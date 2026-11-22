# Ativar a IA do Kazux

O Kazux usa a API da OpenAI por um servidor local. A chave fica somente no arquivo `servidor_ia/.env` do Mac, nunca dentro do aplicativo Flutter. Em 19/11/2026, a conexao real foi testada no servidor e no simulador iOS com dados ficticios.

## Quando voce tiver a chave

1. Entre em https://platform.openai.com/ e crie uma chave de API em **API keys**. Se voce ja compartilhou uma chave em conversa ou imagem, revogue-a e crie outra.
2. Abra a pasta do projeto `kazux` e depois a pasta `servidor_ia`.
3. Abra o arquivo `.env`.
4. Cole a chave depois do sinal de igual, sem aspas:

```text
OPENAI_API_KEY=sua_chave_aqui
OPENAI_MODEL=gpt-5.4-mini
PORT=8787
```

5. Salve o arquivo.
6. Clique duas vezes em `iniciar_ia.command` na pasta principal do projeto.
7. Mantenha a janela aberta. Quando aparecer `IA do Kazux pronta`, abra o aplicativo. Essa mensagem confirma apenas que o servidor local iniciou.
8. Entre na aba **Assistente**, faça uma pergunta e confira se a resposta corresponde aos seus dados. Esse e o teste da conexao completa.

## Teste sugerido

Use a pergunta: `Me dê um resumo do mês e uma dica para economizar.`

## Alterações pelo assistente

O assistente também pode propor ações como registrar uma despesa, criar uma meta, criar um limite de gasto ou apagar uma transação recente. O Kazux sempre mostra uma tela de confirmação antes de fazer qualquer alteração.

Exemplos:

- `Registre uma despesa de 80 reais em Alimentação na conta Nubank hoje.`
- `Crie uma meta de 3.000 reais para uma viagem até dezembro.`
- `Defina um limite de 500 reais para Alimentação.`

## Importante

- Nunca cole a chave em arquivos dentro de `lib`, em mensagens ou em imagens. Nunca envie o arquivo `servidor_ia/.env` para outra pessoa. Ele esta no `.gitignore` e deve ter acesso restrito ao usuario do Mac.
- Para apresentar no Mac ou no simulador de iPhone, basta deixar o arquivo `iniciar_ia.command` aberto.
- O servidor atende apenas em `127.0.0.1`, no proprio Mac, e bloqueia requisicoes originadas de paginas web. Ele nao e um servidor publico, mas outros programas locais do Mac podem alcanca-lo. Para uso fora do simulador, sera necessario um backend HTTPS com autenticacao.
- A versao atual envia a OpenAI somente dados do usuario logado: saldo e ate 30 contas, receitas e despesas do mes por categoria, totais e categorias de 12 meses anteriores, mes atual e 12 meses seguintes, ate 24 parcelas futuras, 12 transacoes recentes ja lancadas, 30 metas, 30 limites e 10 alertas. Os totais indicam quando existem itens omitidos. Ela nao envia senha, PIN, email ou telefone.
- Para usar em iPhone físico fora do Mac, será necessário publicar o servidor em uma hospedagem segura. Para o TCC no Mac e simulador, a configuração atual funciona.
- Os testes e resultados estao em `RELATORIO_VERIFICACAO_IA.md`.
