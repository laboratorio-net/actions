# Implementation Plan: tag-management-workflow

## Overview

Implementação do workflow GitHub Actions `tag-management-workflow` como arquivo YAML com trigger `workflow_dispatch`, contendo um único job `manage-tag` com 9 steps sequenciais para criação, recriação e validação de tags estáveis no formato `vN`.

## Tasks

- [x] 1. Criar estrutura do arquivo YAML e declarar inputs do workflow
  - Criar `.github/workflows/tag-management-workflow.yaml`
  - Declarar trigger `workflow_dispatch` com inputs: `tag-version` (obrigatório, string), `dry-run` (boolean, default false), `force` (boolean, default false), `runs-on` (string, default ubuntu-latest)
  - Declarar job `manage-tag` com `runs-on: ${{ inputs.runs-on }}`
  - _Requirements: 1.1, 2.1, 2.4, 5.2, 7.3_

- [x] 2. Implementar steps de checkout e configuração do Git
  - [x] 2.1 Implementar step 1: Checkout do repositório
    - Usar `actions/checkout@v4` com `fetch-depth: 0`
    - _Requirements: 7.2, 8.1_
  - [x] 2.2 Implementar step 2: Configuração do Git
    - Configurar `git config user.email` e `git config user.name`
    - _Requirements: 7.1, 8.1_

- [x] 3. Implementar validações de entrada
  - [x] 3.1 Implementar step 3: Validação do formato da tag
    - Script bash com regex `^v[0-9]+$` contra `inputs.tag-version`
    - Exportar `CURRENT_COMMIT` via `$GITHUB_ENV` (`git rev-parse HEAD`)
    - Falhar com mensagem descritiva se formato inválido
    - _Requirements: 2.2, 2.3, 8.1_
  - [x] 3.2 Escrever testes unitários para validação de formato
    - Testar entradas válidas: `v1`, `v10`, `v100`
    - Testar entradas inválidas: `1`, `v`, `v1.0`, `V1`, `v1-beta`, string vazia
    - _Requirements: 2.2, 2.3_
  - [x] 3.3 Escrever property test para validação de formato da tag
    - **Property 2: Validação do formato da tag**
    - **Validates: Requirements 2.2, 2.3**
    - Usar bats-core com geração de strings aleatórias (mínimo 100 iterações)
    - Verificar que resultado é equivalente a testar `^v[0-9]+$`
  - [x] 3.4 Implementar step 4: Verificação de existência da tag remota
    - Usar `git ls-remote --tags origin` para checar existência
    - Exportar `TAG_EXISTS` (true/false) e `PREVIOUS_COMMIT` via `$GITHUB_ENV`
    - _Requirements: 3.1, 4.1, 8.1_
  - [x] 3.5 Implementar step 5: Validação de proteção contra sobrescrita
    - Falhar com mensagem de erro se `TAG_EXISTS=true` e `force=false`
    - Prosseguir normalmente nos demais casos
    - _Requirements: 5.3, 5.4, 8.1_
  - [x] 3.6 Escrever testes unitários para lógica de proteção contra sobrescrita
    - Testar: `(TAG_EXISTS=true, force=false)` → falha
    - Testar: `(TAG_EXISTS=true, force=true)` → passa
    - Testar: `(TAG_EXISTS=false, force=*)` → passa
    - _Requirements: 5.3, 5.4_
  - [x] 3.7 Escrever property test para proteção contra sobrescrita
    - **Property 5: Proteção contra sobrescrita**
    - **Validates: Requirements 5.3**
    - Usar bats-core com repositório git local; para qualquer tag existente com `force=false`, verificar que o step falha antes de qualquer operação de remoção (mínimo 100 iterações)

- [x] 4. Checkpoint — Garantir que todos os testes de validação passam
  - Garantir que todos os testes passam, perguntar ao usuário se houver dúvidas.

- [x] 5. Implementar log de auditoria e dry-run
  - [x] 5.1 Implementar step 6: Log de auditoria / dry-run summary
    - Imprimir linhas `[AUDIT]` com actor, operation (CREATE ou RECREATE), tag, commit(s)
    - Se `dry-run=true`: imprimir linhas `[DRY-RUN]` e encerrar com `exit 0`
    - _Requirements: 3.3, 4.4, 6.1, 6.2, 6.3, 8.1_
  - [x] 5.2 Escrever testes unitários para log de auditoria
    - Verificar presença de todos os campos obrigatórios no output (tag, commit, actor)
    - Verificar prefixo `[DRY-RUN]` quando dry-run=true
    - _Requirements: 3.3, 4.4, 6.2_
  - [x] 5.3 Escrever property test para log de auditoria
    - **Property 4: Log de auditoria contém todos os campos obrigatórios**
    - **Validates: Requirements 3.3, 4.4**
    - Para qualquer execução bem-sucedida sem dry-run, verificar presença de tag, hash do commit e actor no log
  - [x] 5.4 Escrever property test para invariante do modo dry-run
    - **Property 6: Invariante do modo dry-run**
    - **Validates: Requirements 6.1, 6.2, 6.3**
    - Usar bats-core com repositório git local; para qualquer combinação de inputs válidos com `dry-run=true`, verificar que: conjunto de tags antes/depois é idêntico, log contém `[DRY-RUN]`, validações executam normalmente (mínimo 100 iterações)

- [x] 6. Implementar operações de tag
  - [x] 6.1 Implementar step 7: Remoção da tag local e remota
    - Executar somente se `TAG_EXISTS=true`
    - Remover tag remota (`git push origin --delete`) e local (`git tag -d`)
    - _Requirements: 4.1, 4.2, 8.1_
  - [x] 6.2 Implementar step 8: Criação e push da nova tag
    - `git tag <tag-version>` + `git push origin <tag-version>`
    - _Requirements: 3.1, 4.3, 8.1_
  - [x] 6.3 Escrever property test para tag aponta para HEAD
    - **Property 3: Tag resultante aponta para HEAD**
    - **Validates: Requirements 3.1, 4.3**
    - Usar bats-core com repositório git local; para qualquer operação bem-sucedida, verificar que `git rev-parse <tag>` retorna o mesmo hash que `git rev-parse HEAD` (mínimo 100 iterações com diferentes commits e nomes de tag)
  - [x] 6.3 Implementar step 9: Registro de conclusão no log
    - Imprimir nome da tag, hash do commit e actor que acionou o workflow
    - _Requirements: 3.3, 4.4, 8.1_

- [x] 7. Implementar validação de branch
  - [x] 7.1 Adicionar verificação de branch no início do job (após checkout)
    - Verificar `GITHUB_REF == refs/heads/main`; falhar com mensagem de erro caso contrário
    - Posicionar como step entre Checkout e Configuração do Git, ou como condição no step de validação
    - _Requirements: 1.2, 1.3, 8.1_
  - [x] 7.2 Escrever testes unitários para validação de branch
    - Testar `refs/heads/main` → passa
    - Testar `refs/heads/feature-x`, `refs/tags/v1`, strings arbitrárias → falha
    - _Requirements: 1.2, 1.3_
  - [x] 7.3 Escrever property test para validação de branch
    - **Property 1: Validação de branch**
    - **Validates: Requirements 1.2, 1.3**
    - Usar bats-core; gerar strings aleatórias de refs e verificar que apenas `refs/heads/main` passa (mínimo 100 iterações)

- [x] 8. Testes de integração e smoke
  - [x] 8.1 Escrever testes de integração com repositório git local
    - Criação de tag inexistente (happy path)
    - Recriação de tag existente com `force=true`
    - Falha com tag existente e `force=false`
    - Dry-run em ambos os cenários
    - Falha com branch incorreta
    - Falha com formato de tag inválido
    - _Requirements: 1.2, 1.3, 2.2, 2.3, 3.1, 4.1, 4.2, 4.3, 5.3, 5.4, 6.1, 6.2, 6.3_
  - [x] 8.2 Escrever testes de smoke no YAML
    - Verificar: trigger é `workflow_dispatch`, todos os inputs declarados com tipos corretos, `fetch-depth: 0` presente, steps na ordem correta, nenhum `continue-on-error: true`, nenhum secret hardcoded
    - _Requirements: 1.1, 2.1, 7.2, 8.1, 8.2_

- [x] 9. Checkpoint final — Garantir que todos os testes passam
  - Garantir que todos os testes passam, perguntar ao usuário se houver dúvidas.

## Notes

- Tasks marcadas com `*` são opcionais e podem ser puladas para um MVP mais rápido
- Cada task referencia requisitos específicos para rastreabilidade
- Testes de propriedade usam bats-core com mínimo de 100 iterações por propriedade
- Nenhum step deve usar `continue-on-error: true`
- Estado compartilhado entre steps via `$GITHUB_ENV`: `TAG_EXISTS`, `PREVIOUS_COMMIT`, `CURRENT_COMMIT`
