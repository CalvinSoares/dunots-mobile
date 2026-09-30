# Dunots Mobile — regras de colaboração

## Fluxo principal

O assistente é responsável por analisar, implementar, testar e revisar o código. O usuário revisa as mudanças e executa os comandos Git de salvamento e envio.

## Responsabilidades do assistente

- Implementar as mudanças solicitadas no projeto mobile.
- Não alterar o aplicativo desktop sem solicitação específica.
- Respeitar a separação do diretório mobile como repositório independente.
- Executar formatador, análise estática, testes e builds adequados ao risco.
- Corrigir os problemas encontrados antes de encerrar uma etapa.
- Explicar o resultado, os arquivos alterados e qualquer limitação.
- Nunca criar commits nem executar push.
- Ao final de cada etapa, fornecer comandos de commits granulares.

## Ordem segura de implementação

- Criar primeiro arquivos sem dependências internas.
- Criar depois arquivos que dependem deles.
- Manter o aplicativo compilável entre as etapas.
- Não importar arquivo que ainda não existe.
- Colocar testes em test/, nunca em lib/.
- Validar cada grupo de alterações antes de iniciar o próximo.

## Commits

Separar por responsabilidade:

- modelo ou regra de domínio;
- tela ou componente;
- persistência;
- testes;
- documentação.

O usuário deve revisar o diff antes de executar os commits.

## Documentação

O plano atual está em docs/plan.md. O estado de validação está em docs/checks.md. Decisões arquiteturais ficam em docs/decisions.md.