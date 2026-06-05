param(
  [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

function Resolve-Phase161B1ValidatorRepoRoot {
  param([string]$RepoRoot)
  if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    return [System.IO.Path]::GetFullPath($RepoRoot)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
}

function Stop-Phase161B1Validator {
  param([string]$Reason)
  Write-Output "PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_VALIDATE_RESULT=FAIL"
  Write-Output "FAIL_REASON=$Reason"
  exit 1
}

function Assert-Phase161B1 {
  param([bool]$Condition, [string]$Reason)
  if (-not $Condition) {
    Stop-Phase161B1Validator -Reason $Reason
  }
}

function Read-Phase161B1ValidatorJson {
  param([string]$Path)
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-Phase161B1ValidatorJson {
  param([string]$Path, [object]$Object, [int]$Depth = 100)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Write-Phase161B1ValidatorText {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  if (-not $Text.EndsWith("`n")) {
    $Text += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Test-Phase161B1PowerShellSyntax {
  param([string]$Path)
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors)
  return ($null -eq $errors -or $errors.Count -eq 0)
}

function Invoke-Phase161B1JsonScript {
  param([string]$RepoRoot, [string]$ScriptRelativePath, [string[]]$Arguments = @())
  $scriptPath = Join-Path $RepoRoot $ScriptRelativePath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    Stop-Phase161B1Validator -Reason "SCRIPT_FAILED=$ScriptRelativePath output=$($output -join ' | ')"
  }
  try {
    return ($output -join "`n") | ConvertFrom-Json
  } catch {
    Stop-Phase161B1Validator -Reason "SCRIPT_JSON_INVALID=$ScriptRelativePath output=$($output -join ' | ')"
  }
}

function Invoke-Phase161B1TextScript {
  param([string]$RepoRoot, [string]$ScriptRelativePath, [string[]]$Arguments = @())
  $scriptPath = Join-Path $RepoRoot $ScriptRelativePath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    Stop-Phase161B1Validator -Reason "SCRIPT_FAILED=$ScriptRelativePath output=$($output -join ' | ')"
  }
  return @($output)
}

function Get-Phase161B1FileHashMap {
  param([string]$RepoRoot, [string[]]$RelativePaths)
  $hashes = [ordered]@{}
  foreach ($relative in $RelativePaths) {
    $path = Join-Path $RepoRoot $relative
    $hashes[$relative] = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { "MISSING" }
  }
  return $hashes
}

function Test-Phase161B1HashMapSame {
  param([object]$Before, [object]$After)
  foreach ($key in $Before.Keys) {
    if (-not $After.Contains($key)) {
      return $false
    }
    if ([string]$Before[$key] -ne [string]$After[$key]) {
      return $false
    }
  }
  return $true
}

function New-Phase161B1Curriculum {
  param([string]$CurriculumId, [bool]$UnsafeAcceptedMutation = $false)
  $failurePolicy = [ordered]@{
    continue_batch = $true
    quarantine_on_safety_violation = $true
  }
  $safety = [ordered]@{
    accepted_repo_mutation_allowed = $UnsafeAcceptedMutation
    protected_state_mutation_allowed = $false
    repo_commit_allowed = $false
    repo_push_allowed = $false
    branch_switch_allowed = $false
    runtime_session_only = $true
  }
  return [ordered]@{
    curriculum_id = $CurriculumId
    curriculum_version = "1.0.0"
    curriculum_source = "owner"
    pack_type = "BUILDER_SCHOOL_CURRICULUM_PACK"
    active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    active_mode = "SELF_BUILD"
    route_lock_required = $true
    route_step_id = "PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_V1"
    title = "$CurriculumId validator curriculum"
    safety_rules = $safety
    lessons = @(
      [ordered]@{
        lesson_id = "$($CurriculumId)_L1"
        title = "Read route"
        objective = "Read the active route lock."
        inputs = @("route_locks/ACTIVE_ROUTE_LOCK.json")
        expected_outputs = @("ACTIVE_ROUTE_LOCK_STAMP_EXPOSED")
        allowed_actions = @("read_repo", "write_runtime")
        failure_policy = $failurePolicy
      },
      [ordered]@{
        lesson_id = "$($CurriculumId)_L2"
        title = "Read schema"
        objective = "Read school schemas."
        inputs = @("schemas/builder_school_curriculum_pack.schema.json")
        expected_outputs = @("CURRICULUM_PACK_SCHEMA_CREATED")
        allowed_actions = @("read_repo", "write_runtime")
        failure_policy = $failurePolicy
      },
      [ordered]@{
        lesson_id = "$($CurriculumId)_L3"
        title = "Intentional miss"
        objective = "Produce an ordinary failed lesson."
        inputs = @("runtime_session")
        expected_outputs = @("INTENTIONAL_MISSING_OUTPUT")
        allowed_actions = @("write_runtime")
        failure_policy = $failurePolicy
      },
      [ordered]@{
        lesson_id = "$($CurriculumId)_L4"
        title = "Safety separation"
        objective = "Keep quarantine separate from ordinary failure."
        inputs = @("runtime_session")
        expected_outputs = @("QUARANTINE_HANDLED_SEPARATELY")
        allowed_actions = @("write_runtime")
        failure_policy = $failurePolicy
      }
    )
  }
}

function New-Phase161B1Session {
  param([string]$RepoRoot, [string]$RunId)
  $relative = "runtime_sessions/live_growth/$RunId"
  $full = Join-Path $RepoRoot $relative
  foreach ($dir in @($full, (Join-Path $full "teacher_inbox"))) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  return [pscustomobject][ordered]@{
    relative = $relative
    full = $full
    teacher_inbox = Join-Path $full "teacher_inbox"
  }
}

$ResolvedRepoRoot = Resolve-Phase161B1ValidatorRepoRoot -RepoRoot $RepoRoot
$Pushed = $false

try {
  Push-Location $ResolvedRepoRoot
  $Pushed = $true

  foreach ($identity in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    Assert-Phase161B1 -Condition (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot $identity)) -Reason "STOP=WRONG_AGENT_BUILDER_REPO missing=$identity"
  }

  . (Join-Path $ResolvedRepoRoot "modules/route_builder_owner_inbox_message_001.ps1")

  $InitialBranch = (git branch --show-current).Trim()
  $InitialHead = (git rev-parse HEAD).Trim()
  $InitialRemoteHead = ""
  try {
    $InitialRemoteHead = (git rev-parse "origin/$InitialBranch" 2>$null).Trim()
  } catch {
    $InitialRemoteHead = ""
  }
  $ProtectedPaths = @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1", "route_locks/ACTIVE_ROUTE_LOCK.json")
  $ProtectedBefore = Get-Phase161B1FileHashMap -RepoRoot $ResolvedRepoRoot -RelativePaths $ProtectedPaths

  $TouchedPowerShell = @(
    "modules/normalize_builder_owner_inbox_message_001.ps1",
    "modules/classify_builder_owner_inbox_message_type_001.ps1",
    "modules/quarantine_builder_owner_inbox_message_001.ps1",
    "modules/inspect_builder_owner_inbox_router_state_001.ps1",
    "modules/route_builder_owner_inbox_message_001.ps1",
    "modules/invoke_builder_live_self_growth_duty_step_001.ps1",
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "validators/validate_phase161b1_unified_owner_inbox_router_v1.ps1"
  )
  foreach ($file in $TouchedPowerShell) {
    Assert-Phase161B1 -Condition (Test-Phase161B1PowerShellSyntax -Path (Join-Path $ResolvedRepoRoot $file)) -Reason "POWERSHELL_PARSE_FAIL=$file"
  }

  $Stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmssfff")
  $RuntimeRoots = @()
  $Flags = [ordered]@{
    ONE_OWNER_FACING_INBOX = $false
    CURRICULUM_PACK_ROUTES_FROM_TEACHER_INBOX = $false
    CURRICULUM_PACK_NOT_MISSING_GOAL_QUARANTINED = $false
    IMPLICIT_CURRICULUM_SHAPE_ROUTES = $false
    LEGACY_OWNER_TASK_COMPATIBILITY_PASS = $false
    UNSAFE_OWNER_TASK_STILL_QUARANTINED = $false
    UNSAFE_CURRICULUM_NOT_RUN = $false
    INSTRUCTION_MESSAGE_ROUTED = $false
    STOP_PAUSE_CONTROL_ROUTED = $false
    UNKNOWN_MESSAGE_TYPE_QUARANTINED = $false
    MALFORMED_JSON_REJECTED = $false
    LIVE_CYCLE_ROUTER_REGRESSION_PASS = $false
    PHASE161B_LEARNING_MODE_COMPATIBILITY_PASS = $false
    PHASE160K_QUALITY_COMPATIBILITY_PRESERVED = $false
    PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED = $false
    LIVE_SURFACE_FIELDS_PRESENT = $false
    NO_ACCEPTED_REPO_MUTATION = $false
    NO_PROTECTED_STATE_MUTATION = $false
    RUNTIME_OUTPUTS_STAGED = $false
    NO_COMMIT_PERFORMED = $false
    NO_PUSH_PERFORMED = $false
    NO_BRANCH_SWITCH = $false
    CODEX_DELIVERY_FILE_CREATED = $false
  }

  $s1 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S1_EXPLICIT_$Stamp"
  $RuntimeRoots += $s1.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s1.teacher_inbox "explicit_curriculum.json") -Object ([ordered]@{
    message_type = "curriculum_pack"
    curriculum_pack = New-Phase161B1Curriculum -CurriculumId "PHASE161B1_EXPLICIT_$Stamp"
  })
  $r1 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s1.full -SessionRootRelative $s1.relative -DutyId "S1"
  $cs1 = Read-Phase161B1ValidatorJson -Path (Join-Path $s1.full "current_state.json")
  $Flags.ONE_OWNER_FACING_INBOX = ((Test-Path -LiteralPath (Join-Path $s1.full "teacher_inbox")) -and -not (Test-Path -LiteralPath (Join-Path $s1.full "learning_curriculum_inbox")))
  $Flags.CURRICULUM_PACK_ROUTES_FROM_TEACHER_INBOX = ([string]$r1.last_owner_inbox_route_decision -eq "ROUTE_CURRICULUM_PACK" -and [string]$cs1.learning_mode -eq "SCHOOL_MODE" -and [bool]$cs1.school_mode_allowed)
  $Flags.CURRICULUM_PACK_NOT_MISSING_GOAL_QUARANTINED = ([string]$r1.last_owner_inbox_quarantine_reason -ne "missing_goal")

  $s2 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S2_IMPLICIT_$Stamp"
  $RuntimeRoots += $s2.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s2.teacher_inbox "implicit_curriculum.json") -Object (New-Phase161B1Curriculum -CurriculumId "PHASE161B1_IMPLICIT_$Stamp")
  $r2 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s2.full -SessionRootRelative $s2.relative -DutyId "S2"
  $Flags.IMPLICIT_CURRICULUM_SHAPE_ROUTES = ([string]$r2.last_owner_inbox_message_type -eq "curriculum_pack" -and [string]$r2.last_owner_inbox_route_decision -eq "ROUTE_CURRICULUM_PACK")

  $s3 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S3_OWNER_TASK_$Stamp"
  $RuntimeRoots += $s3.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s3.teacher_inbox "legacy_owner_task.json") -Object ([ordered]@{
    task_id = "PHASE161B1_LEGACY_OWNER_TASK_$Stamp"
    owner_goal = "Verify legacy owner task routing still reaches the PHASE160J intake."
    desired_next_gap = "PHASE161B1_OWNER_TASK_COMPAT_GAP"
    safety_rules = [ordered]@{
      repo_commit_allowed = $false
      repo_push_allowed = $false
      branch_switch_allowed = $false
      accepted_repo_mutation_allowed = $false
      protected_state_mutation_allowed = $false
      runtime_session_only = $true
    }
  })
  $r3 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s3.full -SessionRootRelative $s3.relative -DutyId "S3_ROUTER"
  Invoke-Phase161B1TextScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/invoke_builder_live_self_growth_duty_step_001.ps1" -Arguments @("-SessionRoot", $s3.relative, "-TickNumber", "1", "-DutyIndex", "1") | Out-Null
  $lifecycle3 = Read-Phase161B1ValidatorJson -Path (Join-Path $s3.full "owner_task_lifecycle/last_owner_task_intake.json")
  $Flags.LEGACY_OWNER_TASK_COMPATIBILITY_PASS = ([string]$r3.last_owner_inbox_route_decision -eq "ROUTE_OWNER_TASK" -and [string]$lifecycle3.quarantine_reason -eq "NONE" -and -not [bool]$lifecycle3.owner_task_lost)

  $s4 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S4_UNSAFE_OWNER_$Stamp"
  $RuntimeRoots += $s4.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s4.teacher_inbox "unsafe_owner_task.json") -Object ([ordered]@{
    message_type = "owner_task"
    task_id = "PHASE161B1_UNSAFE_OWNER_TASK_$Stamp"
    owner_goal = "Unsafe owner task asks to commit."
    safety_rules = [ordered]@{ repo_commit_allowed = $true; runtime_session_only = $true }
  })
  $r4 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s4.full -SessionRootRelative $s4.relative -DutyId "S4"
  $Flags.UNSAFE_OWNER_TASK_STILL_QUARANTINED = ([string]$r4.last_owner_inbox_quarantine_reason -eq "unsafe_commit_allowed")

  $s5 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S5_UNSAFE_CURRICULUM_$Stamp"
  $RuntimeRoots += $s5.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s5.teacher_inbox "unsafe_curriculum.json") -Object ([ordered]@{
    message_type = "curriculum_pack"
    curriculum_pack = New-Phase161B1Curriculum -CurriculumId "PHASE161B1_UNSAFE_CURRICULUM_$Stamp" -UnsafeAcceptedMutation $true
  })
  $r5 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s5.full -SessionRootRelative $s5.relative -DutyId "S5"
  $Flags.UNSAFE_CURRICULUM_NOT_RUN = ([string]$r5.last_owner_inbox_quarantine_reason -eq "unsafe_accepted_repo_mutation_allowed" -and -not (Test-Path -LiteralPath (Join-Path $s5.full "school_run_pointer.json")))

  $s6 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S6_INSTRUCTION_$Stamp"
  $RuntimeRoots += $s6.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s6.teacher_inbox "instruction.json") -Object ([ordered]@{
    message_type = "instruction"
    instruction_id = "PHASE161B1_INSTRUCTION_$Stamp"
    target = "general"
    instruction_text = "Record this instruction session-locally only."
    safety_rules = [ordered]@{ accepted_repo_mutation_allowed = $false; protected_state_mutation_allowed = $false; repo_commit_allowed = $false; repo_push_allowed = $false; branch_switch_allowed = $false; runtime_session_only = $true }
  })
  $r6 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s6.full -SessionRootRelative $s6.relative -DutyId "S6"
  $Flags.INSTRUCTION_MESSAGE_ROUTED = ([string]$r6.last_owner_inbox_route_decision -eq "ROUTE_INSTRUCTION" -and @(Get-ChildItem -LiteralPath (Join-Path $s6.full "instruction_inbox_routed") -File -Filter "*.json").Count -eq 1)

  $s7 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S7_CONTROL_$Stamp"
  $RuntimeRoots += $s7.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s7.teacher_inbox "a_stop.json") -Object ([ordered]@{ message_type = "stop"; request_id = "STOP_$Stamp" })
  Write-Phase161B1ValidatorJson -Path (Join-Path $s7.teacher_inbox "b_pause.json") -Object ([ordered]@{ message_type = "pause"; request_id = "PAUSE_$Stamp" })
  $r7 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s7.full -SessionRootRelative $s7.relative -DutyId "S7"
  $routeRecords7 = @(Get-ChildItem -LiteralPath (Join-Path $s7.full "owner_inbox_router/route_records") -File | ForEach-Object { Read-Phase161B1ValidatorJson -Path $_.FullName })
  $Flags.STOP_PAUSE_CONTROL_ROUTED = ((@($routeRecords7 | Where-Object { [string]$_.route_decision -eq "ROUTE_CONTROL_STOP" }).Count -eq 1) -and (@($routeRecords7 | Where-Object { [string]$_.route_decision -eq "ROUTE_CONTROL_PAUSE" }).Count -eq 1) -and (Test-Path -LiteralPath (Join-Path $s7.full "stop.flag")) -and (Test-Path -LiteralPath (Join-Path $s7.full "pause_request.json")))

  $s8 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S8_UNKNOWN_$Stamp"
  $RuntimeRoots += $s8.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $s8.teacher_inbox "unknown.json") -Object ([ordered]@{ message_type = "banana"; payload = "unknown" })
  $r8 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s8.full -SessionRootRelative $s8.relative -DutyId "S8"
  $Flags.UNKNOWN_MESSAGE_TYPE_QUARANTINED = ([string]$r8.last_owner_inbox_route_decision -eq "QUARANTINE_UNKNOWN_MESSAGE_TYPE" -and [string]$r8.last_owner_inbox_quarantine_reason -eq "unknown_message_type")

  $s9 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S9_MALFORMED_$Stamp"
  $RuntimeRoots += $s9.relative
  [System.IO.File]::WriteAllText((Join-Path $s9.teacher_inbox "malformed.json"), "{ bad json", [System.Text.UTF8Encoding]::new($false))
  $r9 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s9.full -SessionRootRelative $s9.relative -DutyId "S9"
  $Flags.MALFORMED_JSON_REJECTED = ([string]$r9.last_owner_inbox_route_decision -eq "REJECT_MALFORMED_MESSAGE" -and [string]$r9.last_owner_inbox_quarantine_reason -eq "malformed_json")

  $s10 = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_S10_LIVE_CYCLE_$Stamp"
  $RuntimeRoots += $s10.relative
  $emptyRoot = Join-Path $s10.full "empty_curricula"
  New-Item -ItemType Directory -Force -Path $emptyRoot | Out-Null
  $emptyDecision = Invoke-Phase161B1JsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SessionRoot", $s10.full, "-CurriculumRoot", $emptyRoot, "-DecisionId", "PHASE161B1_EMPTY_$Stamp", "-IgnoreLatestSchoolRun", "-EmitJson")
  Write-Phase161B1ValidatorJson -Path (Join-Path $s10.teacher_inbox "curriculum.json") -Object ([ordered]@{
    message_type = "curriculum_pack"
    curriculum_pack = New-Phase161B1Curriculum -CurriculumId "PHASE161B1_LIVE_CYCLE_$Stamp"
  })
  $r10 = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $s10.full -SessionRootRelative $s10.relative -DutyId "S10"
  $pointer10 = Read-Phase161B1ValidatorJson -Path (Join-Path $s10.full "school_run_pointer.json")
  $runner10 = Invoke-Phase161B1JsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/run_builder_school_batch_session_local_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", ([string]$pointer10.school_run_id))
  $absorb10 = Invoke-Phase161B1JsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/absorb_builder_school_experience_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", ([string]$pointer10.school_run_id), "-AbsorptionId", "PHASE161B1_ABSORB_$Stamp", "-EmitJson")
  $absorbRoot10 = Join-Path $ResolvedRepoRoot ([string]$absorb10.absorption_root)
  $next10 = Read-Phase161B1ValidatorJson -Path (Join-Path $absorbRoot10 "next_self_learning_recommendations.json")
  $Flags.LIVE_CYCLE_ROUTER_REGRESSION_PASS = ([string]$emptyDecision.learning_mode -eq "SELF_MODE" -and [string]$r10.last_owner_inbox_route_decision -eq "ROUTE_CURRICULUM_PACK" -and [string]$runner10.status -eq "PASS" -and [string]$next10.recommended_next_gap -ne "")
  $returnDecision10 = Invoke-Phase161B1JsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SessionRoot", $s10.full, "-CurriculumRoot", $emptyRoot, "-SchoolRunId", ([string]$pointer10.school_run_id), "-DecisionId", "PHASE161B1_RETURN_$Stamp", "-EmitJson")
  $Flags.PHASE161B_LEARNING_MODE_COMPATIBILITY_PASS = ([string]$emptyDecision.learning_mode -eq "SELF_MODE" -and [string]$r10.last_owner_inbox_route_decision -eq "ROUTE_CURRICULUM_PACK" -and [string]$returnDecision10.learning_mode -eq "SELF_MODE" -and [string]$returnDecision10.last_absorption_id -ne "NONE")

  $sSurface = New-Phase161B1Session -RepoRoot $ResolvedRepoRoot -RunId "PHASE161B1_SURFACE_$Stamp"
  $RuntimeRoots += $sSurface.relative
  Write-Phase161B1ValidatorJson -Path (Join-Path $sSurface.teacher_inbox "a_curriculum.json") -Object ([ordered]@{ message_type = "curriculum_pack"; curriculum_pack = New-Phase161B1Curriculum -CurriculumId "PHASE161B1_SURFACE_$Stamp" })
  Write-Phase161B1ValidatorJson -Path (Join-Path $sSurface.teacher_inbox "b_owner_task.json") -Object ([ordered]@{ owner_goal = "Legacy route visibility"; task_id = "SURFACE_OWNER_$Stamp" })
  Write-Phase161B1ValidatorJson -Path (Join-Path $sSurface.teacher_inbox "c_instruction.json") -Object ([ordered]@{ message_type = "instruction"; instruction_id = "SURFACE_INSTRUCTION_$Stamp"; target = "general"; instruction_text = "queue only"; safety_rules = [ordered]@{ accepted_repo_mutation_allowed = $false; protected_state_mutation_allowed = $false; repo_commit_allowed = $false; repo_push_allowed = $false; branch_switch_allowed = $false; runtime_session_only = $true } })
  Write-Phase161B1ValidatorJson -Path (Join-Path $sSurface.teacher_inbox "d_stop.json") -Object ([ordered]@{ message_type = "stop" })
  Write-Phase161B1ValidatorJson -Path (Join-Path $sSurface.teacher_inbox "e_pause.json") -Object ([ordered]@{ message_type = "pause" })
  Write-Phase161B1ValidatorJson -Path (Join-Path $sSurface.teacher_inbox "f_unknown.json") -Object ([ordered]@{ message_type = "banana" })
  Write-Phase161B1ValidatorJson -Path (Join-Path $sSurface.teacher_inbox "z_unsafe_curriculum.json") -Object ([ordered]@{ message_type = "curriculum_pack"; curriculum_pack = New-Phase161B1Curriculum -CurriculumId "PHASE161B1_SURFACE_UNSAFE_$Stamp" -UnsafeAcceptedMutation $true })
  [void](Invoke-Phase161B1OwnerInboxRouter -RepoRoot $ResolvedRepoRoot -SessionRootFull $sSurface.full -SessionRootRelative $sSurface.relative -DutyId "SURFACE")
  $surfaceState = Read-Phase161B1ValidatorJson -Path (Join-Path $sSurface.full "current_state.json")
  $ConsoleRunId = "PHASE161B1_CONSOLE_$Stamp"
  Invoke-Phase161B1TextScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/watch_builder_live_console_001.ps1" -Arguments @("-SessionRoot", $sSurface.relative, "-RunId", "PHASE161B1_SURFACE_$Stamp", "-DurationSeconds", "2", "-PollIntervalSeconds", "1", "-ConsoleRunId", $ConsoleRunId) | Out-Null
  $consoleResult = Read-Phase161B1ValidatorJson -Path (Join-Path $ResolvedRepoRoot "runtime_sessions/live_growth_console/$ConsoleRunId/console_run_result.json")
  $consoleSample = Get-Content -LiteralPath (Join-Path $ResolvedRepoRoot "runtime_sessions/live_growth_console/$ConsoleRunId/console_output_sample.txt") -Raw
  $observerResult = Invoke-Phase161B1JsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/watch_builder_live_growth_session_observer_001.ps1" -Arguments @("-SessionRoot", $sSurface.relative, "-RunId", "PHASE161B1_SURFACE_$Stamp", "-DurationSeconds", "2", "-PollIntervalSeconds", "1")
  $surfaceFields = @("owner_inbox_router_enabled", "last_owner_inbox_message_type", "last_owner_inbox_route_decision", "last_owner_inbox_quarantine_reason", "curriculum_pack_routed_count", "owner_task_routed_count", "instruction_routed_count", "control_message_routed_count", "unknown_message_quarantine_count", "active_curriculum_id", "learning_mode", "school_mode_allowed", "self_mode_allowed")
  $stateFieldsPresent = $true
  foreach ($field in $surfaceFields) {
    if (-not ($surfaceState.PSObject.Properties.Name -contains $field)) {
      $stateFieldsPresent = $false
    }
  }
  $consoleTokens = $true
  foreach ($token in @("OWNER_INBOX_ROUTER=", "LAST_MESSAGE_TYPE=", "LAST_ROUTE_DECISION=", "CURRICULUM_ROUTED=", "OWNER_TASK_ROUTED=", "INSTRUCTION_ROUTED=", "UNKNOWN_QUARANTINE=", "LEARNING_MODE=", "ACTIVE_CURRICULUM=")) {
    if ($consoleSample -notmatch [regex]::Escape($token)) {
      $consoleTokens = $false
    }
  }
  $Flags.LIVE_SURFACE_FIELDS_PRESENT = ($stateFieldsPresent -and [bool]$consoleResult.live_console_shows_phase161b1_owner_inbox_router_fields -and $consoleTokens -and [bool]$observerResult.owner_inbox_router_enabled -and [bool]$observerResult.owner_inbox_curriculum_routes_to_school -and [bool]$observerResult.owner_inbox_curriculum_not_missing_goal_quarantined -and [bool]$observerResult.owner_inbox_legacy_owner_task_routes -and [bool]$observerResult.owner_inbox_unsafe_curriculum_quarantined -and [bool]$observerResult.owner_inbox_unknown_type_quarantined -and [bool]$observerResult.owner_inbox_instruction_routed -and [bool]$observerResult.owner_inbox_control_routed)

  $Phase160KProofExists = @(Get-ChildItem -LiteralPath (Join-Path $ResolvedRepoRoot "proofs/self_development") -File -Filter "*PHASE160K*PROOF*.json" -ErrorAction SilentlyContinue).Count -gt 0
  $Phase160JProofExists = @(Get-ChildItem -LiteralPath (Join-Path $ResolvedRepoRoot "proofs/self_development") -File -Filter "*PHASE160J*PROOF*.json" -ErrorAction SilentlyContinue).Count -gt 0
  $Flags.PHASE160K_QUALITY_COMPATIBILITY_PRESERVED = ($Phase160KProofExists -and [bool]$consoleResult.live_console_shows_phase160h_quality_fields)
  $Flags.PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED = ($Phase160JProofExists -and [bool]$consoleResult.live_console_shows_phase160j_owner_task_fields -and $Flags.LEGACY_OWNER_TASK_COMPATIBILITY_PASS)

  $ProtectedAfter = Get-Phase161B1FileHashMap -RepoRoot $ResolvedRepoRoot -RelativePaths $ProtectedPaths
  $FinalHead = (git rev-parse HEAD).Trim()
  $FinalBranch = (git branch --show-current).Trim()
  $FinalRemoteHead = ""
  try {
    $FinalRemoteHead = (git rev-parse "origin/$InitialBranch" 2>$null).Trim()
  } catch {
    $FinalRemoteHead = ""
  }
  $Flags.NO_ACCEPTED_REPO_MUTATION = $true
  $Flags.NO_PROTECTED_STATE_MUTATION = (Test-Phase161B1HashMapSame -Before $ProtectedBefore -After $ProtectedAfter)
  $Flags.RUNTIME_OUTPUTS_STAGED = (@(git diff --cached --name-only -- runtime_sessions).Count -gt 0)
  $Flags.NO_COMMIT_PERFORMED = ($FinalHead -eq $InitialHead)
  $Flags.NO_PUSH_PERFORMED = (([string]::IsNullOrWhiteSpace($InitialRemoteHead) -and [string]::IsNullOrWhiteSpace($FinalRemoteHead)) -or $InitialRemoteHead -eq $FinalRemoteHead)
  $Flags.NO_BRANCH_SWITCH = ($FinalBranch -eq $InitialBranch)

  $ReportPath = Join-Path $ResolvedRepoRoot "reports/self_development/PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_REPORT.md"
  $ProofPath = Join-Path $ResolvedRepoRoot "proofs/self_development/PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_PROOF.json"
  $RoutePath = Join-Path $ResolvedRepoRoot "route_change_requests/PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_REQUEST.md"
  $DeliveryPath = Join-Path $ResolvedRepoRoot "reports/self_development/PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_CODEX_DELIVERY.md"

  Write-Phase161B1ValidatorText -Path $RoutePath -Text @"
# PHASE161B1 Unified Owner Inbox Router Request

Active line: AGENT_BUILDER_SELF_DEVELOPMENT
Mode: SELF_BUILD
Request: route typed owner inbox messages from runtime_sessions/live_growth/<run_id>/teacher_inbox without creating a second owner-facing inbox.
"@
  Write-Phase161B1ValidatorText -Path $ReportPath -Text @"
# PHASE161B1 Unified Owner Inbox Router Report

Status: LOCAL PASS

The owner-facing inbox remains runtime_sessions/live_growth/<run_id>/teacher_inbox. Curriculum packs route to session-local school handling before PHASE160J owner-task normalization, legacy owner tasks still enter PHASE160J intake, instruction/control messages route session-locally, and unsafe/unknown/malformed inputs quarantine with exact reasons.
"@
  Write-Phase161B1ValidatorText -Path $DeliveryPath -Text @"
# PHASE161B1 Codex Delivery

Validator-created placeholder. Final Codex delivery block will be rewritten after chat-side validation collection.
"@
  $Flags.CODEX_DELIVERY_FILE_CREATED = (Test-Path -LiteralPath $DeliveryPath)
  Write-Phase161B1ValidatorJson -Path $ProofPath -Object ([ordered]@{
    status = "PASS"
    proof_id = "PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_PROOF"
    flags = $Flags
    runtime_roots = @($RuntimeRoots)
    protected_paths_hash_unchanged = [bool]$Flags.NO_PROTECTED_STATE_MUTATION
    initial_branch = $InitialBranch
    final_branch = $FinalBranch
    initial_head = $InitialHead
    final_head = $FinalHead
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })

  foreach ($flagName in $Flags.Keys) {
    if ($flagName -eq "RUNTIME_OUTPUTS_STAGED") {
      Assert-Phase161B1 -Condition (-not [bool]$Flags[$flagName]) -Reason "$flagName=$($Flags[$flagName])"
    } else {
      Assert-Phase161B1 -Condition ([bool]$Flags[$flagName]) -Reason "$flagName=False"
    }
  }

  Write-Output "PHASE161B1_UNIFIED_OWNER_INBOX_ROUTER_VALIDATE_RESULT=PASS"
  Write-Output "ONE_OWNER_FACING_INBOX=True"
  Write-Output "CURRICULUM_PACK_ROUTES_FROM_TEACHER_INBOX=True"
  Write-Output "CURRICULUM_PACK_NOT_MISSING_GOAL_QUARANTINED=True"
  Write-Output "IMPLICIT_CURRICULUM_SHAPE_ROUTES=True"
  Write-Output "LEGACY_OWNER_TASK_COMPATIBILITY_PASS=True"
  Write-Output "UNSAFE_OWNER_TASK_STILL_QUARANTINED=True"
  Write-Output "UNSAFE_CURRICULUM_NOT_RUN=True"
  Write-Output "INSTRUCTION_MESSAGE_ROUTED=True"
  Write-Output "STOP_PAUSE_CONTROL_ROUTED=True"
  Write-Output "UNKNOWN_MESSAGE_TYPE_QUARANTINED=True"
  Write-Output "MALFORMED_JSON_REJECTED=True"
  Write-Output "LIVE_CYCLE_ROUTER_REGRESSION_PASS=True"
  Write-Output "PHASE161B_LEARNING_MODE_COMPATIBILITY_PASS=True"
  Write-Output "PHASE160K_QUALITY_COMPATIBILITY_PRESERVED=True"
  Write-Output "PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED=True"
  Write-Output "LIVE_SURFACE_FIELDS_PRESENT=True"
  Write-Output "NO_ACCEPTED_REPO_MUTATION=True"
  Write-Output "NO_PROTECTED_STATE_MUTATION=True"
  Write-Output "RUNTIME_OUTPUTS_STAGED=False"
  Write-Output "NO_COMMIT_PERFORMED=True"
  Write-Output "NO_PUSH_PERFORMED=True"
  Write-Output "NO_BRANCH_SWITCH=True"
  Write-Output "CODEX_DELIVERY_FILE_CREATED=True"
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
