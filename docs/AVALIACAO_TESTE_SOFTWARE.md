# Avaliação — Teste de Software | Kazux

## Demonstração
1. Abra https://github.com/The-kazu/kazux/actions e mostre a execução verde [CI #1](https://github.com/The-kazu/kazux/actions/runs/46054264823).
2. Abra os jobs testes e semgrep, mostre os passos e resultados.
3. Abra .github/workflows/ci.yml e explique push e pull_request para main, jobs independentes e permissões de leitura.
4. Mostre test/modelo_transacao_test.dart e test/servidor_ia_test.dart: oito testes novos e cinco existentes, além do teste de widget.
5. Abra https://github.com/The-kazu/kazux/pull/2 para demonstrar falhas intencionais em branch isolada. Nunca mescle esse PR.
6. Localmente execute flutter pub get e flutter test. Para SAST: semgrep scan --config .semgrep.yml --severity ERROR --error --strict .

## Cobertura
Classificação de receitas/despesas, serialização, desserialização, conta padrão, conversão numérica e tratamento de tipo inválido; extração de respostas e recusas da IA e tratamento de erros da API.

## Arguição
- CI: integração contínua com verificações automáticas a cada mudança.
- CD: entrega ou implantação contínua; este projeto implementa CI, não implantação.
- Workflow: arquivo YAML que define eventos, jobs e etapas.
- Job: unidade de execução em runner; os dois jobs são independentes.
- Push: envio de commits; pull request: proposta de integração de mudanças.
- Teste unitário: valida unidade isolada com resultado esperado.
- Caminho feliz: entrada válida; borda/erro: tipo desconhecido, conta ausente ou valor inválido.
- SAST: analisa código sem executar o aplicativo.
- Semgrep: busca padrões de segurança; usamos regras genéricas direcionadas a arquivos Dart, para chaves OpenAI e TLS inseguro. Não é uma auditoria completa.
- Severidade: regras usam ERROR como nível bloqueante e metadata CRITICAL para classificação acadêmica.
- --error: retorna código diferente de zero quando há achado; --strict também trata erros de análise como falha.
- Por que dois jobs? Isolamento e diagnóstico independente; ambos precisam passar.
- Por que branch de demo? Para mostrar falhas sem contaminar main.
- Teste local e CI usam o mesmo comando flutter test.
- CI verde não garante ausência de bugs; apenas aprovação das verificações configuradas.
