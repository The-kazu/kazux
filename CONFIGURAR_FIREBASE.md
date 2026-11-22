# Vincular o Firebase ao Kazux

O backup em nuvem é opcional. O Kazux usa o SQLite local normalmente sem configurar o Firebase. A conta de demonstração é apenas local.

## Etapa única no seu Mac

1. No Console Firebase, crie ou abra um projeto ao qual você tenha acesso.
2. Cadastre um aplicativo **iOS** com o Bundle ID `com.example.kazuxLimpo`.
3. Baixe o arquivo `GoogleService-Info.plist` e coloque-o em `ios/Runner/GoogleService-Info.plist`. O Xcode inclui o arquivo automaticamente quando ele existe. Não é necessário adicioná-lo manualmente ao alvo no Xcode.
4. Mantenha esse arquivo local e compile novamente. Ele não é incluído no Git.

## Ativar serviços no Console Firebase

Abra o projeto em https://console.firebase.google.com/ e ative:

1. **Authentication** > **Sign-in method** > habilite **Email/Password**.
2. **Firestore Database** > crie o banco em modo de produção.
3. Em **Firestore Database** > **Rules**, copie o conteúdo de `firebase/firestore.rules`, publique as regras e aguarde a confirmação.

## Usar no Kazux

1. Abra o aplicativo e entre em uma conta cadastrada por você.
2. Entre em **Perfil** > **Backup em nuvem**.
3. Toque em **Conectar conta Firebase**.
4. Toque em **Enviar backup agora**.

O Firebase Authentication usa o mesmo e-mail e senha cadastrados no Kazux. O backup no Firestore inclui contas, transações, metas e limites de gastos. Ele não inclui senha nem PIN.

Para recuperar em outro aparelho, entre no mesmo e-mail e senha, abra **Backup em nuvem** e toque em **Restaurar último backup**.
