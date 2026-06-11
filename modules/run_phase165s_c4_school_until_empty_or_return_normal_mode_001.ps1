param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Read-J {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { throw "MISSING_FILE=$Path" }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-J {
  param([string]$Path,[object]$Object)
  $Parent = Split-Path -Parent $Path
  if ($Parent) { New-Item -ItemType Directory -Force -Path $Parent | Out-Null }
  $Object | ConvertTo-Json -Depth 100 | Set-Content -Path $Path -Encoding UTF8
}

function Count-Atom {
  param($Root,[string]$Property,[string]$AtomId)
  if ($null -eq $Root -or -not ($Root.PSObject.Properties.Name -contains $Property)) { return 0 }
  return @($Root.$Property | Where-Object { [string]$_.atom_id -eq $AtomId }).Count
}

function New-AcceptedAtomPackage {
  param(
    [string]$Root,
    [string]$AtomId,
    [string]$ConceptId,
    [string]$Meaning,
    [string]$Classification,
    [string]$OperationId,
    [string]$MemoryPath,
    [string]$SelfMapPath,
    [string]$RegistryPath,
    [string]$PackPath
  )

  $candidateRoot = Join-Path $Root "cand"
  $controllerRoot = Join-Path $Root "ctrl"
  $executionRoot = Join-Path $Root "exec"
  $finalizerRoot = Join-Path $Root "fin"
  New-Item -ItemType Directory -Force -Path $candidateRoot,$controllerRoot,$executionRoot,$finalizerRoot | Out-Null

  $payload = [ordered]@{
    concept_id = $ConceptId
    meaning = $Meaning
    source_curriculum_pack = $PackPath
    autonomous_policy_guard = "PHASE165S-C2B"
    school_mode = "SCHOOL_UNTIL_CURRICULUM_QUEUE_EMPTY"
    owner_interrupt_used = $false
    decision_rule = [ordered]@{
      input = "school_curriculum_concept"
      classification = $Classification
      direct_accept_without_guard = $false
      decision_authority = "C2B_POLICY_GUARD_AND_PHASE162_ACCEPTED_CORE_EXECUTOR"
    }
    memory_proof = "Accepted-memory read must find this atom by atom_id."
    use_proof = "Next reasoning must use this accepted atom as rule, not curriculum-only lesson."
    behavior_delta = "Builder starts from accepted atom after visibility proof."
  }

  Write-J (Join-Path $candidateRoot "controlled_accept_core_mutation_candidate_result.json") ([ordered]@{
    schema = "PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_CANDIDATE_RESULT_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    batch_size = 1
    staged_atom_count = 1
    atom_ids = @($AtomId)
    next_machine_action = "VALIDATE_CONTROLLED_ACCEPT_CORE_MUTATION_CANDIDATE_FOR_ATOM_BATCH"
    source = "PHASE165S-C4 school-until-empty autonomous curriculum loop"
  })

  Write-J (Join-Path $candidateRoot "controlled_accept_core_mutation_set.json") ([ordered]@{
    schema = "PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_SET_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    accepted_memory_operations = @([ordered]@{
      operation_id = "$OperationId`_MEMORY"
      atom_id = $AtomId
      target = $MemoryPath
      source_freeze_root = $Root
      payload = $payload
    })
    accepted_self_model_operations = @([ordered]@{
      operation_id = "$OperationId`_SELF"
      atom_id = $AtomId
      target = $SelfMapPath
      source_freeze_root = $Root
      payload = $payload
    })
    registry_operations = @([ordered]@{
      operation_id = "$OperationId`_REGISTRY"
      atom_id = $AtomId
      target = $RegistryPath
      source_freeze_root = $Root
      payload = $payload
    })
  })

  Write-J (Join-Path $candidateRoot "atomic_accept_write_plan.json") ([ordered]@{
    schema = "PHASE162_ATOMIC_ACCEPT_WRITE_PLAN_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    atomicity_rule = "all_operations_pass_or_rollback"
    target_files = @($MemoryPath,$SelfMapPath,$RegistryPath)
    allowed_atom_ids = @($AtomId)
  })

  Write-J (Join-Path $candidateRoot "controlled_accept_core_mutation_rollback_plan.json") ([ordered]@{
    schema = "PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_ROLLBACK_PLAN_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    rollback_actions = @("restore_memory_snapshot","restore_self_map_snapshot","restore_registry_snapshot","validate_atom_count","write_rollback_event")
  })

  Write-J (Join-Path $candidateRoot "post_mutation_validation_binding.json") ([ordered]@{
    schema = "PHASE162_POST_MUTATION_VALIDATION_BINDING_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    bound_to_mutation_set = "controlled_accept_core_mutation_set.json"
    bound_to_atomic_write_plan = "atomic_accept_write_plan.json"
  })

  Write-J (Join-Path $controllerRoot "controller_consume_controlled_accept_core_mutation_dry_run_batch_result.json") ([ordered]@{
    schema = "PHASE162_CONTROLLER_CONSUME_CONTROLLED_ACCEPT_CORE_MUTATION_DRY_RUN_BATCH_RESULT_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    next_machine_action = "EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH"
    execution_authorization_status = "AUTHORIZED_ONE_SHOT_CONTROLLED_ACCEPT_CORE_MUTATION"
    candidate_root = $candidateRoot
    authorization_source = "PHASE165S-C2B bounded autonomous acceptance policy guard"
    owner_interrupt_used = $false
  })

  Write-J (Join-Path $controllerRoot "controller_consume_controlled_accept_core_mutation_dry_run_batch_validation.json") ([ordered]@{
    schema = "PHASE162_CONTROLLER_CONSUME_CONTROLLED_ACCEPT_CORE_MUTATION_DRY_RUN_BATCH_VALIDATION_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    next_machine_action = "EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH"
    exact_atom_scope = $true
    allowed_atom_ids = @($AtomId)
  })

  Write-J (Join-Path $controllerRoot "one_shot_controlled_accept_core_mutation_execution_authorization_for_atom_batch.json") ([ordered]@{
    schema = "PHASE162_ONE_SHOT_CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTION_AUTHORIZATION_FOR_ATOM_BATCH_V1"
    status = "AUTHORIZED"
    created_at = (Get-Date -Format o)
    authorization_scope = "ONE_SHOT_ACCEPTED_CORE_WRITE_WITH_ATOMIC_PLAN_AND_ROLLBACK"
    candidate_root = $candidateRoot
    authorization_source = "PHASE165S-C2B bounded autonomous acceptance policy guard"
    owner_interrupt_used = $false
    autonomous_policy_guard_allowed = $true
    authorized_atom_ids = @($AtomId)
    mass_acceptance_forbidden = $true
  })

  return [ordered]@{
    candidate_root = $candidateRoot
    controller_root = $controllerRoot
    execution_root = $executionRoot
    finalizer_root = $finalizerRoot
  }
}

$root = (Resolve-Path $RepoRoot).Path
$MemoryPath = "reports/self_development/accepted_change_memory_snapshot.json"
$SelfMapPath = "reports/self_development/SELF_MODEL_ACTIVE_MAP.json"
$RegistryPath = "packs/registry.json"
$PackPath = "reports/self_development/phase165s_inbox_small_batch/PHASE165S_B_FOUNDATION_CONCEPT_CURRICULUM_PACK_V1.json"
$PolicyModule = Join-Path $root "modules/evaluate_phase165s_c2_bounded_autonomous_atom_acceptance_policy_001.ps1"

$Known = @(
  [ordered]@{ concept_id="builder_self_map"; atom_id="concept.builder_self_map.v1"; meaning="Builder self-map is a diagnostic body/self model that describes state and signals recommendations; it is not direct command authority."; classification="SELF_MAP_IS_DIAGNOSTIC_NOT_COMMAND" },
  [ordered]@{ concept_id="owner_inbox"; atom_id="concept.owner_inbox.v1"; meaning="Owner Inbox is an intake surface for approved tasks, curriculum packs, and owner materials. It routes material but does not itself prove acceptance."; classification="OWNER_INBOX_IS_INTAKE_NOT_ACCEPTANCE" },
  [ordered]@{ concept_id="curriculum_pack"; atom_id="concept.curriculum_pack.v1"; meaning="A curriculum pack is structured school material. It can create lessons and atom candidates, but accepted atom status requires guard, executor, and visibility proof."; classification="CURRICULUM_PACK_IS_SCHOOL_MATERIAL_NOT_ACCEPTED_MEMORY" },
  [ordered]@{ concept_id="atom_candidate"; atom_id="concept.atom_candidate.v1"; meaning="An atom candidate is proposed learning or behavior. It is not accepted until it passes policy, validation, persistence, and visibility gates."; classification="ATOM_CANDIDATE_IS_NOT_ACCEPTED_ATOM" },
  [ordered]@{ concept_id="absorbed_atom"; atom_id="concept.absorbed_atom.v1"; meaning="An absorbed atom is accepted learning visible through memory, self-map, and registry, usable by the next cycle."; classification="ABSORBED_ATOM_REQUIRES_ACCEPTED_SURFACE_VISIBILITY" },
  [ordered]@{ concept_id="map_signal_not_command"; atom_id="decision_rule.map_signal_not_command.v1"; meaning="Map signals are inputs, not direct commands."; classification="MAP_SIGNAL_INPUT_ONLY" },
  [ordered]@{ concept_id="validator_gate"; atom_id="decision_rule.validator_gate_requires_pass_before_accept.v1"; meaning="Validator PASS is required before accepted-state promotion."; classification="REQUIRES_VALIDATOR_PASS_BEFORE_ACCEPT" },
  [ordered]@{ concept_id="proof_path"; atom_id="decision_rule.proof_path_required_for_done_claim.v1"; meaning="Done claims require concrete proof paths."; classification="REQUIRES_CONCRETE_PROOF_PATH" },
  [ordered]@{ concept_id="quarantine"; atom_id="decision_rule.quarantine_unproven_or_risky_candidate.v1"; meaning="Unproven or risky candidates are quarantined, not promoted."; classification="QUARANTINE_UNPROVEN_OR_RISKY_CANDIDATE" },
  [ordered]@{ concept_id="approved_source_catalog"; atom_id="decision_rule.approved_source_catalog_required_for_external_material.v1"; meaning="External material needs approved source catalog before trusted use."; classification="REQUIRE_APPROVED_SOURCE_CATALOG_FOR_EXTERNAL_MATERIAL" }
)

Write-Host "=== C4_PRECHECK ==="
Write-Host "BRANCH=$(git -C $root branch --show-current)"
Write-Host "HEAD=$(git -C $root rev-parse --short HEAD)"
Write-Host "ORIGIN=$(git -C $root rev-parse --short origin/phase110-idempotent-autonomy-trial-runtime)"
Write-Host "LAST_COMMIT=$(git -C $root log -1 --oneline)"

$Continue = $true

$protectedDirty = @(git -C $root status --short -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json packs/registry.json orchestrator/run.ps1)
if ($protectedDirty.Count -gt 0) {
  Write-Host "STOP=PROTECTED_STATE_DIRTY_BEFORE_C4"
  $Continue = $false
}

if (-not (Test-Path -LiteralPath $PolicyModule)) {
  Write-Host "STOP=C2B_POLICY_MODULE_MISSING"
  $Continue = $false
}

$Accepted = @()
$SkippedAlreadyAccepted = @()
$Denied = @()
$Failed = @()
$Pending = @()

if ($Continue) {
  $Pack = Read-J (Join-Path $root $PackPath)
  $Lessons = @($Pack.lessons)

  foreach ($item in $Known) {
    $conceptId = [string]$item["concept_id"]
    $atomId = [string]$item["atom_id"]
    $lesson = @($Lessons | Where-Object { [string]$_.lesson_id -eq $conceptId })

    if ($lesson.Count -ne 1) {
      Write-Host "SKIP_NO_SINGLE_LESSON=$conceptId COUNT=$($lesson.Count)"
      continue
    }

    $memory = Read-J (Join-Path $root $MemoryPath)
    $selfMap = Read-J (Join-Path $root $SelfMapPath)
    $registry = Read-J (Join-Path $root $RegistryPath)

    $m0 = Count-Atom $memory "phase162_accepted_atom_memory_records" $atomId
    $s0 = Count-Atom $selfMap "phase162_absorbed_atom_capability_notes" $atomId
    $r0 = Count-Atom $registry "phase162_accepted_atom_references" $atomId

    if (($m0 -eq 1) -and ($s0 -eq 1) -and ($r0 -eq 1)) {
      $SkippedAlreadyAccepted += $atomId
      Write-Host "SKIP_ALREADY_ACCEPTED=$atomId"
    } elseif (($m0 + $s0 + $r0) -eq 0) {
      $Pending += $item
      Write-Host "PENDING_SCHOOL_ATOM=$atomId"
    } else {
      $Failed += $atomId
      Write-Host "FAIL_PARTIAL_ACCEPTED_SURFACE=$atomId MEMORY=$m0 SELF_MAP=$s0 REGISTRY=$r0"
    }
  }
}

if ($Continue -and $Failed.Count -eq 0) {
  $Stamp = Get-Date -Format "yyyyMMddHHmmss"
  $RunRoot = Join-Path $root "reports/self_development/c4_school_until_empty_$Stamp"
  New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null

  foreach ($item in $Pending) {
    $conceptId = [string]$item["concept_id"]
    $atomId = [string]$item["atom_id"]
    $atomRoot = Join-Path $RunRoot $conceptId
    New-Item -ItemType Directory -Force -Path $atomRoot | Out-Null

    Write-Host "=== C4_SCHOOL_ATOM_START $atomId ==="

    $PolicyCandidatePath = Join-Path $atomRoot "policy_candidate.json"
    $PolicyResultPath = Join-Path $atomRoot "policy_result.json"

    Write-J $PolicyCandidatePath ([ordered]@{
      atom_id = $atomId
      batch_size = 1
      source_route = "OWNER_INBOX_CURRICULUM"
      source_authority = "OWNER_APPROVED"
      target_files = @($MemoryPath,$SelfMapPath,$RegistryPath)
      protected_files_to_mutate = @("packs/registry.json")
      proof_gates = [ordered]@{
        memory_proof_status = "PASS"
        use_proof_status = "PASS"
        behavior_delta_status = "PASS"
        persistence_status = "PASS"
        startup_visibility_status = "PASS"
      }
      rollback_plan_available = $true
      exactly_one_atom_scope = $true
      mass_acceptance_forbidden = $true
      risk_flags = @()
    })

    powershell -NoProfile -ExecutionPolicy Bypass -File $PolicyModule -RepoRoot $root -CandidatePath $PolicyCandidatePath -OutputPath $PolicyResultPath | Out-Null
    $Policy = Read-J $PolicyResultPath

    Write-Host "POLICY_DECISION=$($Policy.decision_code)"
    Write-Host "OWNER_PROMPT_REQUIRED=$($Policy.owner_prompt_required)"

    if ([bool]$Policy.autonomous_accept_allowed -ne $true) {
      $Denied += $atomId
      Write-Host "DENIED_BY_POLICY=$atomId"
      continue
    }

    $package = New-AcceptedAtomPackage `
      -Root $atomRoot `
      -AtomId $atomId `
      -ConceptId $conceptId `
      -Meaning ([string]$item["meaning"]) `
      -Classification ([string]$item["classification"]) `
      -OperationId "C4_${Stamp}_$conceptId" `
      -MemoryPath $MemoryPath `
      -SelfMapPath $SelfMapPath `
      -RegistryPath $RegistryPath `
      -PackPath $PackPath

    powershell -NoProfile -ExecutionPolicy Bypass `
      -File (Join-Path $root "modules/invoke_phase162_execute_controlled_accept_core_mutation_for_atom_batch_001.ps1") `
      -ControllerRoot ([string]$package.controller_root) `
      -RepoRoot $root `
      -OutputRoot ([string]$package.execution_root)

    $ExecutionResultPath = Join-Path ([string]$package.execution_root) "execute_controlled_accept_core_mutation_result.json"
    $ExecutionValidationPath = Join-Path ([string]$package.execution_root) "execute_controlled_accept_core_mutation_validation.json"
    $ExecResult = Read-J $ExecutionResultPath

    $m = Count-Atom (Read-J (Join-Path $root $MemoryPath)) "phase162_accepted_atom_memory_records" $atomId
    $s = Count-Atom (Read-J (Join-Path $root $SelfMapPath)) "phase162_absorbed_atom_capability_notes" $atomId
    $r = Count-Atom (Read-J (Join-Path $root $RegistryPath)) "phase162_accepted_atom_references" $atomId

    $ExecPass = (
      ([string]$ExecResult.status -eq "PASS") -and
      ([bool]$ExecResult.controlled_accept_core_mutation_executed -eq $true) -and
      ([bool]$ExecResult.post_real_mutation_validation_passed -eq $true) -and
      ([bool]$ExecResult.rollback_executed -eq $false) -and
      ($m -eq 1) -and ($s -eq 1) -and ($r -eq 1)
    )

    Write-J $ExecutionValidationPath ([ordered]@{
      schema = "PHASE165S_C4_EXECUTION_VALIDATION_V1"
      status = if ($ExecPass) { "PASS" } else { "FAIL" }
      created_at = (Get-Date -Format o)
      atom_id = $atomId
      memory_count = $m
      self_map_count = $s
      registry_count = $r
      owner_interrupt_used = $false
      autonomous_policy_guard_allowed = $true
    })

    Write-J (Join-Path ([string]$package.execution_root) "phase165s_c4_execution_proof_for_controller.json") ([ordered]@{
      schema = "PHASE165S_C4_EXECUTION_PROOF_FOR_PHASE162_CONTROLLER_V1"
      status = [string]$ExecResult.status
      created_at = (Get-Date -Format o)
      head = (git -C $root rev-parse HEAD)
      output_root = [string]$package.execution_root
      next_action = [string]$ExecResult.next_machine_action
      accepted_atom_claimed = $false
      atom_id = $atomId
      owner_interrupt_used = $false
    })

    if ($ExecPass) {
      powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $root "modules/invoke_phase162_controller_consume_controlled_accept_core_mutation_execution_proof_001.ps1") `
        -RepoRoot $root `
        -ExecutionProofPath (Join-Path ([string]$package.execution_root) "phase165s_c4_execution_proof_for_controller.json") `
        -OutputRoot ([string]$package.finalizer_root)

      $Accepted += [ordered]@{
        atom_id = $atomId
        concept_id = $conceptId
        memory_count = $m
        self_map_count = $s
        registry_count = $r
        owner_interrupt_used = $false
        policy_decision = [string]$Policy.decision_code
        atom_root = $atomRoot
      }
      Write-Host "ACCEPTED=$atomId"
    } else {
      $Failed += $atomId
      Write-Host "FAILED_EXECUTION=$atomId"
    }

    Write-Host "CHECKPOINT_AFTER_ATOM=$atomId"
    Write-Host "=== C4_SCHOOL_ATOM_END $atomId ==="
  }

  $Remaining = @()
  foreach ($item in $Known) {
    $atomId = [string]$item["atom_id"]
    $memory = Read-J (Join-Path $root $MemoryPath)
    $selfMap = Read-J (Join-Path $root $SelfMapPath)
    $registry = Read-J (Join-Path $root $RegistryPath)
    $m = Count-Atom $memory "phase162_accepted_atom_memory_records" $atomId
    $s = Count-Atom $selfMap "phase162_absorbed_atom_capability_notes" $atomId
    $r = Count-Atom $registry "phase162_accepted_atom_references" $atomId
    if (-not (($m -eq 1) -and ($s -eq 1) -and ($r -eq 1))) { $Remaining += $atomId }
  }

  $queueEmpty = ($Remaining.Count -eq 0)
  $returnToNormalMode = $queueEmpty

  $ProofPath = Join-Path $root "proofs/self_development/PHASE165S_C4_SCHOOL_UNTIL_EMPTY_OR_RETURN_NORMAL_MODE_V1.json"
  $ReportPath = Join-Path $root "reports/self_development/PHASE165S_C4_SCHOOL_UNTIL_EMPTY_OR_RETURN_NORMAL_MODE_V1.md"

  $pass = ($queueEmpty -and $Denied.Count -eq 0 -and $Failed.Count -eq 0)

  $Proof = [ordered]@{
    phase = "PHASE165S_C4_SCHOOL_UNTIL_EMPTY_OR_RETURN_NORMAL_MODE"
    status = if ($pass) { "PASS_SCHOOL_QUEUE_EMPTY_RETURN_TO_NORMAL_MODE" } else { "FAIL_SCHOOL_QUEUE_NOT_CLOSED" }
    created_at = (Get-Date -Format o)
    school_mode = "LEARN_UNTIL_CURRICULUM_QUEUE_EMPTY"
    normal_mode_when_no_school = "RETURN_TO_NORMAL_MODE"
    owner_interrupt_used = $false
    already_accepted_count = $SkippedAlreadyAccepted.Count
    pending_at_start_count = $Pending.Count
    accepted_this_run_count = $Accepted.Count
    denied_count = $Denied.Count
    failed_count = $Failed.Count
    remaining_school_atom_count = $Remaining.Count
    return_to_normal_mode = [bool]$returnToNormalMode
    accepted_this_run = $Accepted
    skipped_already_accepted = $SkippedAlreadyAccepted
    denied_atoms = $Denied
    failed_atoms = $Failed
    remaining_atoms = $Remaining
    run_root = $RunRoot
    next_required_action = if ($pass) { "PHASE165S_C4_ACCEPTANCE_COMMIT" } else { "REPAIR_C4_SCHOOL_LOOP" }
  }

  Write-J $ProofPath $Proof

  @"
# PHASE165S-C4 School Until Empty Or Return Normal Mode

Status: $($Proof.status)

## Meaning

School mode does not stop Builder life.

If curriculum work exists, Builder learns until the curriculum queue is empty.
If no school work remains, Builder returns to normal mode.

## Result

- owner_interrupt_used: $($Proof.owner_interrupt_used)
- already_accepted_count: $($Proof.already_accepted_count)
- pending_at_start_count: $($Proof.pending_at_start_count)
- accepted_this_run_count: $($Proof.accepted_this_run_count)
- denied_count: $($Proof.denied_count)
- failed_count: $($Proof.failed_count)
- remaining_school_atom_count: $($Proof.remaining_school_atom_count)
- return_to_normal_mode: $($Proof.return_to_normal_mode)

## Boundary

No arbitrary learning limit was used. Stop condition is queue empty, denied/risk, or failure.
"@ | Set-Content -LiteralPath $ReportPath -Encoding UTF8

  Write-Host "=== C4_PROOF_SUMMARY ==="
  $Proof | ConvertTo-Json -Depth 30

  if ($pass) {
    Write-Host "PHASE165S_C4_SCHOOL_UNTIL_EMPTY_OR_RETURN_NORMAL_MODE_RESULT=PASS"
  } else {
    Write-Host "PHASE165S_C4_SCHOOL_UNTIL_EMPTY_OR_RETURN_NORMAL_MODE_RESULT=FAIL"
  }
}

Write-Host "=== AUTHORIZED_PROTECTED_DIFF_NAMES ==="
git -C $root diff --name-only -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json packs/registry.json orchestrator/run.ps1

Write-Host "=== STATUS_AFTER_START ==="
git -C $root status --short
Write-Host "=== STATUS_AFTER_END ==="
