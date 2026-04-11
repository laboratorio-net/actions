#!/usr/bin/env bats
# Smoke tests for tag-management-workflow.yaml
# Validates YAML structure without executing the workflow
# Requirements: 1.1, 2.1, 7.2, 8.1, 8.2

YAML_FILE="$BATS_TEST_DIRNAME/../../.github/workflows/tag-management-workflow.yaml"

@test "smoke: trigger is workflow_dispatch" {
  grep -q "workflow_dispatch" "$YAML_FILE"
}

@test "smoke: input tag-version is declared as required string" {
  grep -q "tag-version:" "$YAML_FILE"
  grep -A5 "tag-version:" "$YAML_FILE" | grep -q "type: string"
  grep -A5 "tag-version:" "$YAML_FILE" | grep -q "required: true"
}

@test "smoke: input dry-run is declared as boolean with default false" {
  grep -q "dry-run:" "$YAML_FILE"
  grep -A5 "dry-run:" "$YAML_FILE" | grep -q "type: boolean"
  grep -A5 "dry-run:" "$YAML_FILE" | grep -q "default: false"
}

@test "smoke: input force is declared as boolean with default false" {
  grep -q "force:" "$YAML_FILE"
  grep -A5 "force:" "$YAML_FILE" | grep -q "type: boolean"
  grep -A5 "force:" "$YAML_FILE" | grep -q "default: false"
}

@test "smoke: input runs-on is declared as string with default ubuntu-latest" {
  grep -q "runs-on:" "$YAML_FILE"
  grep -A5 "runs-on:" "$YAML_FILE" | grep -q "type: string"
  grep -A5 "runs-on:" "$YAML_FILE" | grep -q "ubuntu-latest"
}

@test "smoke: fetch-depth: 0 is present in checkout step" {
  grep -q "fetch-depth: 0" "$YAML_FILE"
}

@test "smoke: no continue-on-error: true in any step" {
  ! grep -q "continue-on-error: true" "$YAML_FILE"
}

@test "smoke: no hardcoded secrets or tokens" {
  ! grep -qiE "(ghp_|github_pat_|token:\s+[a-zA-Z0-9]{20,})" "$YAML_FILE"
}

@test "smoke: step Checkout do repositório is present" {
  grep -q "Checkout do repositório" "$YAML_FILE"
}

@test "smoke: step Validação de branch is present" {
  grep -q "Validação de branch" "$YAML_FILE"
}

@test "smoke: step Configuração do Git is present" {
  grep -q "Configuração do Git" "$YAML_FILE"
}

@test "smoke: step Validação do formato da tag is present" {
  grep -q "Validação do formato da tag" "$YAML_FILE"
}

@test "smoke: step Verificação de existência da tag remota is present" {
  grep -q "Verificação de existência da tag remota" "$YAML_FILE"
}

@test "smoke: step Validação de proteção contra sobrescrita is present" {
  grep -q "Validação de proteção contra sobrescrita" "$YAML_FILE"
}

@test "smoke: step Log de auditoria is present" {
  grep -q "Log de auditoria" "$YAML_FILE"
}

@test "smoke: step Remoção da tag local e remota is present" {
  grep -q "Remoção da tag local e remota" "$YAML_FILE"
}

@test "smoke: step Criação e push da nova tag is present" {
  grep -q "Criação e push da nova tag" "$YAML_FILE"
}

@test "smoke: step Registro de conclusão no log is present" {
  grep -q "Registro de conclusão no log" "$YAML_FILE"
}

@test "smoke: steps are in correct order" {
  # Extract line numbers of each step name and verify ordering
  local checkout_line format_line branch_line git_line remote_line overwrite_line audit_line remove_line create_line conclusion_line
  checkout_line=$(grep -n "Checkout do repositório" "$YAML_FILE" | head -1 | cut -d: -f1)
  branch_line=$(grep -n "Validação de branch" "$YAML_FILE" | head -1 | cut -d: -f1)
  git_line=$(grep -n "Configuração do Git" "$YAML_FILE" | head -1 | cut -d: -f1)
  format_line=$(grep -n "Validação do formato da tag" "$YAML_FILE" | head -1 | cut -d: -f1)
  remote_line=$(grep -n "Verificação de existência da tag remota" "$YAML_FILE" | head -1 | cut -d: -f1)
  overwrite_line=$(grep -n "Validação de proteção contra sobrescrita" "$YAML_FILE" | head -1 | cut -d: -f1)
  audit_line=$(grep -n "Log de auditoria" "$YAML_FILE" | head -1 | cut -d: -f1)
  remove_line=$(grep -n "Remoção da tag local e remota" "$YAML_FILE" | head -1 | cut -d: -f1)
  create_line=$(grep -n "Criação e push da nova tag" "$YAML_FILE" | head -1 | cut -d: -f1)
  conclusion_line=$(grep -n "Registro de conclusão no log" "$YAML_FILE" | head -1 | cut -d: -f1)

  [ "$checkout_line" -lt "$branch_line" ]
  [ "$branch_line" -lt "$git_line" ]
  [ "$git_line" -lt "$format_line" ]
  [ "$format_line" -lt "$remote_line" ]
  [ "$remote_line" -lt "$overwrite_line" ]
  [ "$overwrite_line" -lt "$audit_line" ]
  [ "$audit_line" -lt "$remove_line" ]
  [ "$remove_line" -lt "$create_line" ]
  [ "$create_line" -lt "$conclusion_line" ]
}
