# Manual do Usuário - Kazux

## 1. Objetivo

O Kazux é um aplicativo de organização financeira pessoal. Ele permite registrar receitas e despesas, acompanhar o saldo, planejar limites de gastos, criar metas financeiras, analisar relatórios e manter uma cópia de segurança na nuvem.

## 2. Acesso e segurança

1. Na tela de login, informe seu e-mail e senha.
2. Para criar uma conta, escolha um e-mail, senha e um PIN de seis números.
3. Cada usuário possui seus próprios dados e seu próprio PIN.
4. Em **Perfil > Segurança**, é possível alterar o PIN de seis números.
5. Em **Perfil > Aparência**, escolha o tema **Claro**, **Escuro** ou **Automático**. A escolha fica salva no aparelho e será aplicada novamente ao abrir o Kazux.

## 3. Tela inicial

A tela inicial apresenta o saldo total, receitas e despesas do mês selecionado. Use as setas do mês para consultar até doze meses anteriores ou posteriores. O botão `+` abre o formulário de nova transação.

## 4. Transações e contas

1. Toque em `+` e escolha **Receita** ou **Despesa**.
2. Informe valor, descrição, categoria, conta e data.
3. Para uma compra parcelada, ative **Compra parcelada** e selecione de 2 a 12 parcelas.
4. Para adicionar outro banco, toque no botão `+` ao lado da conta.
5. Na aba **Transações**, deslize um registro para a esquerda para apagá-lo.

## 5. Metas financeiras

Em **Perfil > Metas financeiras**, crie objetivos como viagem, reserva de emergência ou compra planejada. Informe o valor desejado, o valor já guardado e a data da meta. Toque em uma meta para editar ou use o menu para apagar.

## 6. Planejamento de gastos

Na tela **Metas**, toque em **Planejamento de gastos**. Crie um limite mensal para cada categoria, como Alimentação ou Lazer. O Kazux compara as despesas registradas com o limite definido e mostra o progresso por mês.

## 7. Alertas de excesso de gastos

Quando uma categoria alcançar 80% do limite mensal, o Kazux cria um aviso. Ao ultrapassar 100%, ele gera um alerta de limite excedido. Os avisos aparecem na central de notificações e também podem aparecer como notificação do aparelho, caso a permissão seja aceita.

## 8. Relatórios

Na aba **Relatórios**, escolha o mês e alterne entre os gráficos **Palitos** e **Pizza**. Os gráficos mostram a distribuição das despesas por categoria e indicam onde está o maior gasto do período.

## 9. Assistente inteligente

O Assistente Kazux pode ser aberto pela aba inferior ou em **Perfil > Assistente inteligente**. Na apresentação pelo simulador iOS, o servidor local no Mac precisa estar aberto pelo arquivo `iniciar_ia.command`. A conexão com a API da OpenAI e a conversa na tela foram testadas com dados fictícios em 19/11/2026. O assistente recebe apenas um resumo financeiro do usuário logado: saldo e contas, receitas e despesas por categoria, histórico mensal, parcelas futuras, metas, limites e alertas. Ele pode propor criar transações, metas ou limites e apagar transações recentes. O aplicativo confere se a conta bancária informada existe, se a transação a apagar pertence ao usuário ativo e se os valores são válidos. Nenhuma alteração é executada antes da confirmação na tela. O resumo limita a quantidade de detalhes individuais; para perguntas sobre registros não enviados, a IA deve informar que não tem dados suficientes. A chave da API fica somente no servidor local, nunca no aplicativo iOS. Consulte `RELATORIO_VERIFICACAO_IA.md` para as evidências e limitações.

## 10. Backup em nuvem

Em **Perfil > Backup em nuvem**, toque em **Conectar conta Firebase** ou ative **Backup automático**. Depois da conexão, alterações em contas, transações, metas e limites são enviadas automaticamente ao Firestore. A tela mostra quando o envio está pendente ou atualizado. O botão **Enviar backup agora** continua disponível. Se o envio falhar, o aplicativo tenta novamente enquanto estiver aberto ou ao voltar para ele. O banco em nuvem está localizado em São Paulo. A conexão usa o mesmo e-mail e senha da conta Kazux. Para recuperar dados, entre com a mesma conta, conecte-se à internet e use **Restaurar último backup**. A restauração substitui os dados financeiros locais dessa conta. Cada conta acessa somente o próprio backup. A senha é usada na autenticação do Firebase, mas não é salva no documento de backup; o PIN permanece apenas no aparelho.

O Firebase do Kazux possui autenticação por e-mail e senha para a versão iOS do aplicativo, além de regras que impedem um usuário de consultar ou alterar o backup de outro usuário. O Mac é utilizado somente para desenvolver e testar no simulador de iPhone.

## 11. Suporte

Se não houver internet, o Kazux continua funcionando com o banco local. O backup e o assistente inteligente dependem de internet e das configurações descritas nos arquivos `CONFIGURAR_FIREBASE.md` e `GUIA_IA_OPENAI.md`.

## 12. Organização do projeto

No Visual Studio Code, trabalhe principalmente na pasta `lib`, onde está o código do Kazux. A pasta `build` é criada automaticamente durante a compilação e contém arquivos internos do Flutter, Xcode e Firebase. Ela não deve ser alterada.
