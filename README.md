# Kazux

Aplicativo iOS de controle financeiro pessoal, desenvolvido em Flutter para o TCC.

## Abrir e executar

Abra esta pasta no VS Code. Com um simulador de iPhone ligado, execute `flutter pub get` e depois `flutter run`, ou use **Run** no VS Code. Para a apresentacao, inicie o app pelo Flutter; abrir diretamente um artefato de depuracao sem o processo do Flutter conectado pode deixar a tela branca. Uma instalacao nova inclui uma conta ficticia para demonstracao local: e-mail `demo@kazux.example`, senha e PIN de demonstracao `123456`.

## Conferir

Execute `flutter analyze` e `flutter test`. Para testar cadastro, PIN, separacao de contas, transacoes, metas, graficos e navegacao no simulador, use `flutter test integration_test/fluxos_financeiros_test.dart -d ID_DO_SIMULADOR`.

O banco principal e SQLite local. O backup em nuvem usa Firebase Authentication e Firestore. Depois de conectar a conta em Perfil > Backup em nuvem, o backup automatico envia alteracoes de contas, transacoes, metas e limites. A IA usa o servidor local da pasta `servidor_ia`; para ativa-la, siga [GUIA_IA_OPENAI.md](GUIA_IA_OPENAI.md). Em iPhone fisico fora do Mac, a IA precisa de um servidor hospedado.

O aplicativo local roda sem configuracao externa. Para testar o backup em um clone novo, siga [CONFIGURAR_FIREBASE.md](CONFIGURAR_FIREBASE.md) e cadastre uma conta de teste. A configuracao do Firebase e a chave da OpenAI ficam fora do Git.
