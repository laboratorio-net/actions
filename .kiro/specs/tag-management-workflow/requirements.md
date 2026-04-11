# Requirements Document

## Introduction

Este documento descreve os requisitos para o workflow `tag-management-workflow`, um fluxo GitHub Actions acionado manualmente para gerenciar tags estáveis (ex: `v1`, `v2`, `v3`) no repositório de workflows reutilizáveis. O fluxo deve criar ou recriar uma tag apontando para o último commit da branch `main`, com validações de segurança, suporte a dry-run e registro de auditoria.

## Glossary

- **Workflow**: Arquivo YAML de automação do GitHub Actions
- **Tag**: Referência Git imutável associada a um commit específico
- **Tag_Manager**: O workflow `tag-management-workflow` descrito neste documento
- **Stable_Tag**: Tag de versão estável no formato `vN` (ex: `v1`, `v2`, `v3`)
- **Dry_Run**: Modo de execução simulada que valida as operações sem aplicá-las
- **Main_Branch**: Branch principal do repositório (`refs/heads/main`)
- **Actor**: Usuário do GitHub que acionou o workflow manualmente

---

## Requirements

### Requirement 1: Acionamento Manual Restrito à Branch Main

**User Story:** Como engenheiro de plataforma, quero acionar o gerenciamento de tags manualmente e somente na branch main, para evitar que tags estáveis sejam criadas ou sobrescritas a partir de branches incorretas.

#### Acceptance Criteria

1. THE Tag_Manager SHALL ser acionado exclusivamente via `workflow_dispatch`
2. WHEN o workflow é acionado, THE Tag_Manager SHALL executar somente quando a branch ativa for `refs/heads/main`
3. IF a branch ativa não for `refs/heads/main`, THEN THE Tag_Manager SHALL encerrar a execução com mensagem de erro indicando que o fluxo só pode ser executado na branch main

---

### Requirement 2: Input de Versão da Tag

**User Story:** Como engenheiro de plataforma, quero informar a versão da tag ao acionar o workflow, para controlar qual tag estável será criada ou atualizada.

#### Acceptance Criteria

1. THE Tag_Manager SHALL expor um input obrigatório chamado `tag-version` do tipo `string` com description `"Versão da tag estável a ser criada ou recriada. Exemplo: v1, v2, v3"`
2. WHEN o input `tag-version` é fornecido, THE Tag_Manager SHALL validar que o valor segue o padrão `vN`, onde `N` é um número inteiro positivo
3. IF o valor de `tag-version` não corresponder ao padrão `vN`, THEN THE Tag_Manager SHALL encerrar a execução com mensagem de erro descritiva indicando o formato esperado
4. THE Tag_Manager SHALL expor um input opcional chamado `dry-run` do tipo `boolean` com valor padrão `false` e description `"Simula as operações sem aplicá-las. Nenhuma tag será criada, removida ou atualizada"`

---

### Requirement 3: Criação de Tag Inexistente

**User Story:** Como engenheiro de plataforma, quero que o workflow crie automaticamente a tag quando ela ainda não existir, para facilitar o processo de publicação de uma nova versão estável.

#### Acceptance Criteria

1. WHEN a tag informada não existir no repositório remoto, THE Tag_Manager SHALL criar a tag apontando para o commit mais recente da branch main
2. WHEN a tag é criada, THE Tag_Manager SHALL utilizar como mensagem da tag o hash e a mensagem do commit mais recente da branch main
3. WHEN a tag é criada com sucesso, THE Tag_Manager SHALL registrar no log da execução: o nome da tag, o hash do commit referenciado e o Actor que acionou o workflow

---

### Requirement 4: Recriação de Tag Existente

**User Story:** Como engenheiro de plataforma, quero que o workflow remova e recrie a tag quando ela já existir, para que a versão estável sempre aponte para o commit mais recente da main.

#### Acceptance Criteria

1. WHEN a tag informada já existir no repositório remoto, THE Tag_Manager SHALL remover a tag remota existente antes de recriar
2. WHEN a tag remota é removida, THE Tag_Manager SHALL também remover a tag local antes de recriar
3. WHEN a tag é recriada, THE Tag_Manager SHALL apontar para o commit mais recente da branch main no momento da execução
4. WHEN a tag é recriada com sucesso, THE Tag_Manager SHALL registrar no log da execução: o nome da tag, o hash do commit anterior, o hash do novo commit e o Actor que acionou o workflow

---

### Requirement 5: Proteção contra Sobrescrita Acidental (Confirmação)

**User Story:** Como engenheiro de plataforma, quero ser alertado quando uma tag já existente for sobrescrita, para evitar remoções acidentais em produção.

#### Acceptance Criteria

1. WHEN a tag informada já existir, THE Tag_Manager SHALL exibir no log um aviso explícito indicando que a tag existente será removida e recriada antes de executar a operação
2. THE Tag_Manager SHALL expor um input opcional chamado `force` do tipo `boolean` com valor padrão `false` e description `"Permite sobrescrever uma tag existente. Obrigatório quando a tag já existe"`
3. WHEN a tag informada já existir E o input `force` for `false`, THEN THE Tag_Manager SHALL encerrar a execução com mensagem de erro indicando que é necessário definir `force: true` para sobrescrever a tag
4. WHEN a tag informada já existir E o input `force` for `true`, THE Tag_Manager SHALL prosseguir com a remoção e recriação da tag

---

### Requirement 6: Modo Dry-Run

**User Story:** Como engenheiro de plataforma, quero executar o workflow em modo simulado, para validar o comportamento esperado sem alterar tags no repositório.

#### Acceptance Criteria

1. WHEN o input `dry-run` for `true`, THE Tag_Manager SHALL executar todas as validações (formato da tag, existência, permissão de sobrescrita) normalmente
2. WHEN o input `dry-run` for `true`, THE Tag_Manager SHALL registrar no log todas as operações que seriam executadas, prefixadas com `[DRY-RUN]`
3. WHEN o input `dry-run` for `true`, THE Tag_Manager SHALL encerrar sem criar, remover ou atualizar nenhuma tag no repositório
4. WHEN o input `dry-run` for `false`, THE Tag_Manager SHALL executar as operações de tag normalmente

---

### Requirement 7: Configuração do Ambiente Git

**User Story:** Como engenheiro de plataforma, quero que o workflow configure o ambiente Git corretamente antes de operar, para que as operações de tag sejam atribuídas a uma identidade rastreável.

#### Acceptance Criteria

1. THE Tag_Manager SHALL configurar `user.email` e `user.name` no Git antes de executar qualquer operação de tag
2. THE Tag_Manager SHALL utilizar `fetch-depth: 0` no checkout para garantir acesso ao histórico completo de commits
3. THE Tag_Manager SHALL expor um input opcional `runs-on` do tipo `string` com valor padrão `ubuntu-latest` e description `"Runner a ser utilizado"`

---

### Requirement 8: Divisão em Steps

**User Story:** Como engenheiro de plataforma, quero que o workflow seja organizado em steps nomeados e independentes, para facilitar a leitura, manutenção e identificação de falhas.

#### Acceptance Criteria

1. THE Tag_Manager SHALL organizar as operações nos seguintes steps distintos, nesta ordem:
   - Checkout do repositório
   - Configuração do Git
   - Validação do formato da tag
   - Verificação de existência da tag remota
   - Validação de proteção contra sobrescrita (quando aplicável)
   - Log de auditoria / dry-run summary
   - Remoção da tag local e remota (quando aplicável)
   - Criação e push da nova tag
   - Registro de conclusão no log
2. WHEN um step falha, THE Tag_Manager SHALL encerrar a execução e exibir a mensagem de erro do step que falhou
