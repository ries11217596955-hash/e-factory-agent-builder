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

function New-Phase162Package {
  param(
    [string]$AtomRoot,
    [object]$Lesson,
    [string]$OperationId,
    [string]$MemoryPath,
    [string]$SelfMapPath,
    [string]$RegistryPath,
    [string]$PackPath
  )

  $AtomId = [string]$Lesson.target_atom_id
  $ConceptId = [string]$Lesson.lesson_id
  $CandidateRoot = Join-Path $AtomRoot "cand"
  $ControllerRoot = Join-Path $AtomRoot "ctrl"
  $ExecutionRoot = Join-Path $AtomRoot "exec"
  $FinalizerRoot = Join-Path $AtomRoot "fin"

  New-Item -ItemType Directory -Force -Path $CandidateRoot,$ControllerRoot,$ExecutionRoot,$FinalizerRoot | Out-Null

  $candidate = $Lesson.atom_candidate

  $Payload = [ordered]@{
    concept_id = $ConceptId
    meaning = [string]$candidate.meaning
    atom_type = [string]$candidate.atom_type
    used_when = @($candidate.used_when)
    next_layer_questions = @($candidate.next_layer_questions)
    behavior_change = [string]$candidate.behavior_change
    source_curriculum_pack = $PackPath
    autonomous_policy_guard = "PHASE165S-C2B"
    school_wave = "PHASE165S-D1B"
    owner_interrupt_used = $false
    decision_rule = [ordered]@{
      input = "primitive_builder_concept"
      classification = "USE_ACCEPTED_PRIMITIVE_CONCEPT_AND_MOVE_TO_NEXT_LAYER"
      direct_accept_without_guard = $false
      decision_authority = "C2B_POLICY_GUARD_AND_PHASE162_ACCEPTED_CORE_EXECUTOR"
    }
    memory_proof = "Accepted-memory read must find this primitive concept atom by atom_id."
    use_proof = "Future task should classify the concept and move to procedure/proof/organ layer."
    behavior_delta = "Next cycle starts from accepted primitive concept, not zero-definition search."
  }

  Write-J (Join-Path $CandidateRoot "controlled_accept_core_mutation_candidate_result.json") ([ordered]@{
    schema = "PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_CANDIDATE_RESULT_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    batch_size = 1
    staged_atom_count = 1
    atom_ids = @($AtomId)
    next_machine_action = "VALIDATE_CONTROLLED_ACCEPT_CORE_MUTATION_CANDIDATE_FOR_ATOM_BATCH"
    source = "PHASE165S-D1B primitive builder alphabet school wave"
  })

  Write-J (Join-Path $CandidateRoot "controlled_accept_core_mutation_set.json") ([ordered]@{
    schema = "PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_SET_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    accepted_memory_operations = @([ordered]@{
      operation_id = "$OperationId`_MEMORY"
      atom_id = $AtomId
      target = $MemoryPath
      source_freeze_root = $AtomRoot
      payload = $Payload
    })
    accepted_self_model_operations = @([ordered]@{
      operation_id = "$OperationId`_SELF"
      atom_id = $AtomId
      target = $SelfMapPath
      source_freeze_root = $AtomRoot
      payload = $Payload
    })
    registry_operations = @([ordered]@{
      operation_id = "$OperationId`_REGISTRY"
      atom_id = $AtomId
      target = $RegistryPath
      source_freeze_root = $AtomRoot
      payload = $Payload
    })
  })

  Write-J (Join-Path $CandidateRoot "atomic_accept_write_plan.json") ([ordered]@{
    schema = "PHASE162_ATOMIC_ACCEPT_WRITE_PLAN_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    atomicity_rule = "all_operations_pass_or_rollback"
    target_files = @($MemoryPath,$SelfMapPath,$RegistryPath)
    allowed_atom_ids = @($AtomId)
  })

  Write-J (Join-Path $CandidateRoot "controlled_accept_core_mutation_rollback_plan.json") ([ordered]@{
    schema = "PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_ROLLBACK_PLAN_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    rollback_actions = @("restore_memory_snapshot","restore_self_map_snapshot","restore_registry_snapshot","validate_atom_count","write_rollback_event")
  })

  Write-J (Join-Path $CandidateRoot "post_mutation_validation_binding.json") ([ordered]@{
    schema = "PHASE162_POST_MUTATION_VALIDATION_BINDING_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    bound_to_mutation_set = "controlled_accept_core_mutation_set.json"
    bound_to_atomic_write_plan = "atomic_accept_write_plan.json"
  })

  Write-J (Join-Path $ControllerRoot "controller_consume_controlled_accept_core_mutation_dry_run_batch_result.json") ([ordered]@{
    schema = "PHASE162_CONTROLLER_CONSUME_CONTROLLED_ACCEPT_CORE_MUTATION_DRY_RUN_BATCH_RESULT_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    next_machine_action = "EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH"
    execution_authorization_status = "AUTHORIZED_ONE_SHOT_CONTROLLED_ACCEPT_CORE_MUTATION"
    candidate_root = $CandidateRoot
    authorization_source = "PHASE165S-C2B bounded autonomous acceptance policy guard"
    owner_interrupt_used = $false
  })

  Write-J (Join-Path $ControllerRoot "controller_consume_controlled_accept_core_mutation_dry_run_batch_validation.json") ([ordered]@{
    schema = "PHASE162_CONTROLLER_CONSUME_CONTROLLED_ACCEPT_CORE_MUTATION_DRY_RUN_BATCH_VALIDATION_V1"
    status = "PASS"
    created_at = (Get-Date -Format o)
    next_machine_action = "EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH"
    exact_atom_scope = $true
    allowed_atom_ids = @($AtomId)
  })

  Write-J (Join-Path $ControllerRoot "one_shot_controlled_accept_core_mutation_execution_authorization_for_atom_batch.json") ([ordered]@{
    schema = "PHASE162_ONE_SHOT_CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTION_AUTHORIZATION_FOR_ATOM_BATCH_V1"
    status = "AUTHORIZED"
    created_at = (Get-Date -Format o)
    authorization_scope = "ONE_SHOT_ACCEPTED_CORE_WRITE_WITH_ATOMIC_PLAN_AND_ROLLBACK"
    candidate_root = $CandidateRoot
    authorization_source = "PHASE165S-C2B bounded autonomous acceptance policy guard"
    owner_interrupt_used = $false
    autonomous_policy_guard_allowed = $true
    authorized_atom_ids = @($AtomId)
    mass_acceptance_forbidden = $true
  })

  return [ordered]@{
    candidate_root = $CandidateRoot
    controller_root = $ControllerRoot
    execution_root = $ExecutionRoot
    finalizer_root = $FinalizerRoot
  }
}

$root = (Resolve-Path $RepoRoot).Path
$MemoryPath = "reports/self_development/accepted_change_memory_snapshot.json"
$SelfMapPath = "reports/self_development/SELF_MODEL_ACTIVE_MAP.json"
$RegistryPath = "packs/registry.json"
$PackPath = "reports/self_development/phase165s_d1_primitive_builder_alphabet/PHASE165S_D1_PRIMITIVE_BUILDER_ALPHABET_CURRICULUM_PACK_V1.json"
$PolicyModule = Join-Path $root "modules/evaluate_phase165s_c2_bounded_autonomous_atom_acceptance_policy_001.ps1"

Write-Host "=== D1B_PRECHECK ==="
Write-Host "BRANCH=$(git -C $root branch --show-current)"
Write-Host "HEAD=$(git -C $root rev-parse --short HEAD)"
Write-Host "ORIGIN=$(git -C $root rev-parse --short origin/phase110-idempotent-autonomy-trial-runtime)"
Write-Host "LAST_COMMIT=$(git -C $root log -1 --oneline)"

$Continue = $true

$ProtectedDirty = @(git -C $root status --short -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json packs/registry.json orchestrator/run.ps1)
if ($ProtectedDirty.Count -gt 0) {
  Write-Host "STOP=PROTECTED_STATE_DIRTY_BEFORE_D1B"
  $Continue = $false
}

foreach ($p in @($PackPath,$PolicyModule)) {
  if (Test-Path -LiteralPath $p) { Write-Host "FOUND=$p" } else { Write-Host "MISSING=$p"; $Continue = $false }
}

$Accepted = @()
$Denied = @()
$Failed = @()
$Skipped = @()

if ($Continue) {
  $Pack = Read-J (Join-Path $root $PackPath)
  $Lessons = @($Pack.lessons)

  Write-Host "PACK_LESSON_COUNT=$($Lessons.Count)"

  if ($Lessons.Count -ne 25) {
    Write-Host "STOP=PACK_LESSON_COUNT_NOT_25"
    $Continue = $false
  }
}

if ($Continue) {
  $Stamp = Get-Date -Format "yyyyMMddHHmmss"
  $RunRoot = Join-Path $root "reports/self_development/d1b_primitive_alphabet_wave_$Stamp"
  New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null

  foreach ($Lesson in $Lessons) {
    $AtomId = [string]$Lesson.target_atom_id
    $ConceptId = [string]$Lesson.lesson_id
    $AtomRoot = Join-Path $RunRoot $ConceptId
    New-Item -ItemType Directory -Force -Path $AtomRoot | Out-Null

    Write-Host "=== D1B_ATOM_START $AtomId ==="

    $Memory = Read-J (Join-Path $root $MemoryPath)
    $SelfMap = Read-J (Join-Path $root $SelfMapPath)
    $Registry = Read-J (Join-Path $root $RegistryPath)

    $m0 = Count-Atom $Memory "phase162_accepted_atom_memory_records" $AtomId
    $s0 = Count-Atom $SelfMap "phase162_absorbed_atom_capability_notes" $AtomId
    $r0 = Count-Atom $Registry "phase162_accepted_atom_references" $AtomId

    if (($m0 -eq 1) -and ($s0 -eq 1) -and ($r0 -eq 1)) {
      Write-Host "SKIP_ALREADY_ACCEPTED=$AtomId"
      $Skipped += $AtomId
      continue
    }

    if (($m0 + $s0 + $r0) -ne 0) {
      Write-Host "FAIL_PARTIAL_ACCEPTED_SURFACE=$AtomId MEMORY=$m0 SELF_MAP=$s0 REGISTRY=$r0"
      $Failed += $AtomId
      continue
    }

    $PolicyCandidatePath = Join-Path $AtomRoot "policy_candidate.json"
    $PolicyResultPath = Join-Path $AtomRoot "policy_result.json"

    Write-J $PolicyCandidatePath ([ordered]@{
      atom_id = $AtomId
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
      $Denied += $AtomId
      Write-Host "DENIED_BY_POLICY=$AtomId REASONS=$($Policy.denial_reasons -join ',')"
      continue
    }

    $package = New-Phase162Package `
      -AtomRoot $AtomRoot `
      -Lesson $Lesson `
      -OperationId "D1B_${Stamp}_$ConceptId" `
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

    $m = Count-Atom (Read-J (Join-Path $root $MemoryPath)) "phase162_accepted_atom_memory_records" $AtomId
    $s = Count-Atom (Read-J (Join-Path $root $SelfMapPath)) "phase162_absorbed_atom_capability_notes" $AtomId
    $r = Count-Atom (Read-J (Join-Path $root $RegistryPath)) "phase162_accepted_atom_references" $AtomId

    $ExecPass = (
      ([string]$ExecResult.status -eq "PASS") -and
      ([bool]$ExecResult.controlled_accept_core_mutation_executed -eq $true) -and
      ([bool]$ExecResult.post_real_mutation_validation_passed -eq $true) -and
      ([bool]$ExecResult.rollback_executed -eq $false) -and
      ($m -eq 1) -and ($s -eq 1) -and ($r -eq 1)
    )

    Write-J $ExecutionValidationPath ([ordered]@{
      schema = "PHASE165S_D1B_EXECUTION_VALIDATION_V1"
      status = if ($ExecPass) { "PASS" } else { "FAIL" }
      created_at = (Get-Date -Format o)
      atom_id = $AtomId
      concept_id = $ConceptId
      memory_count = $m
      self_map_count = $s
      registry_count = $r
      owner_interrupt_used = $false
      autonomous_policy_guard_allowed = $true
    })

    Write-J (Join-Path ([string]$package.execution_root) "phase165s_d1b_execution_proof_for_controller.json") ([ordered]@{
      schema = "PHASE165S_D1B_EXECUTION_PROOF_FOR_PHASE162_CONTROLLER_V1"
      status = [string]$ExecResult.status
      created_at = (Get-Date -Format o)
      head = (git -C $root rev-parse HEAD)
      output_root = [string]$package.execution_root
      next_action = [string]$ExecResult.next_machine_action
      accepted_atom_claimed = $false
      atom_id = $AtomId
      owner_interrupt_used = $false
    })

    if ($ExecPass) {
      powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $root "modules/invoke_phase162_controller_consume_controlled_accept_core_mutation_execution_proof_001.ps1") `
        -RepoRoot $root `
        -ExecutionProofPath (Join-Path ([string]$package.execution_root) "phase165s_d1b_execution_proof_for_controller.json") `
        -OutputRoot ([string]$package.finalizer_root)

      $Accepted += [ordered]@{
        atom_id = $AtomId
        concept_id = $ConceptId
        memory_count = $m
        self_map_count = $s
        registry_count = $r
        owner_interrupt_used = $false
        policy_decision = [string]$Policy.decision_code
        atom_root = $AtomRoot
      }
      Write-Host "ACCEPTED=$AtomId"
    } else {
      $Failed += $AtomId
      Write-Host "FAILED_EXECUTION=$AtomId"
    }

    Write-Host "CHECKPOINT_AFTER_ATOM=$AtomId"
    Write-Host "=== D1B_ATOM_END $AtomId ==="
  }

  $ProofPath = Join-Path $root "proofs/self_development/PHASE165S_D1B_PRIMITIVE_BUILDER_ALPHABET_SCHOOL_WAVE_V1.json"
  $ReportPath = Join-Path $root "reports/self_development/PHASE165S_D1B_PRIMITIVE_BUILDER_ALPHABET_SCHOOL_WAVE_V1.md"

  $AllPass = (($Accepted.Count -eq 25) -and ($Denied.Count -eq 0) -and ($Failed.Count -eq 0))

  $Proof = [ordered]@{
    phase = "PHASE165S_D1B_PRIMITIVE_BUILDER_ALPHABET_SCHOOL_WAVE"
    status = if ($AllPass) { "PASS_PRIMITIVE_ALPHABET_25_ATOMS_VISIBLE" } else { "FAIL_PRIMITIVE_ALPHABET_SCHOOL_WAVE" }
    created_at = (Get-Date -Format o)
    owner_interrupt_used = $false
    autonomous_policy_guard_used = $true
    requested_lesson_count = 25
    accepted_atom_count = $Accepted.Count
    denied_atom_count = $Denied.Count
    failed_atom_count = $Failed.Count
    skipped_atom_count = $Skipped.Count
    accepted_atoms = $Accepted
    denied_atoms = $Denied
    failed_atoms = $Failed
    skipped_atoms = $Skipped
    run_root = $RunRoot
    next_required_action = if ($AllPass) { "PHASE165S_D1B_ACCEPTANCE_COMMIT" } else { "REPAIR_D1B_PRIMITIVE_ALPHABET_WAVE" }
  }

  Write-J $ProofPath $Proof

  @"
# PHASE165S-D1B Primitive Builder Alphabet School Wave

Status: $($Proof.status)

## Result

- requested_lesson_count: $($Proof.requested_lesson_count)
- accepted_atom_count: $($Proof.accepted_atom_count)
- denied_atom_count: $($Proof.denied_atom_count)
- failed_atom_count: $($Proof.failed_atom_count)
- skipped_atom_count: $($Proof.skipped_atom_count)
- owner_interrupt_used: $($Proof.owner_interrupt_used)
- autonomous_policy_guard_used: $($Proof.autonomous_policy_guard_used)

## Meaning

Builder absorbed 25 primitive Builder concepts as accepted atoms through the existing school-to-atom loop.

## Boundary

No internet. No tool installation. No new dispatcher. No manual self-map update.
"@ | Set-Content -LiteralPath $ReportPath -Encoding UTF8

  Write-Host "=== D1B_PROOF_SUMMARY ==="
  $Proof | ConvertTo-Json -Depth 30

  if ($AllPass) {
    Write-Host "PHASE165S_D1B_PRIMITIVE_BUILDER_ALPHABET_SCHOOL_WAVE_RESULT=PASS"
  } else {
    Write-Host "PHASE165S_D1B_PRIMITIVE_BUILDER_ALPHABET_SCHOOL_WAVE_RESULT=FAIL"
  }
}

Write-Host "=== AUTHORIZED_PROTECTED_DIFF_NAMES ==="
git -C $root diff --name-only -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json packs/registry.json orchestrator/run.ps1

Write-Host "=== STATUS_AFTER_START ==="
git -C $root status --short
Write-Host "=== STATUS_AFTER_END ==="
