function Get-Phase160JClassifierObjectProperty {
  param([object]$Object, [string[]]$Names, [object]$Default = $null)
  if ($null -eq $Object) {
    return $Default
  }
  foreach ($name in $Names) {
    if ($Object -is [System.Collections.IDictionary] -and $Object.Contains($name)) {
      return $Object[$name]
    }
    if ($Object.PSObject.Properties.Name -contains $name) {
      return $Object.$name
    }
  }
  return $Default
}

function ConvertTo-Phase160JClassifierBoolean {
  param([object]$Value, [bool]$Default = $false)
  if ($null -eq $Value) {
    return $Default
  }
  if ($Value -is [bool]) {
    return [bool]$Value
  }
  $text = ([string]$Value).Trim()
  if ($text -eq "true") {
    return $true
  }
  if ($text -eq "false") {
    return $false
  }
  return $Default
}

function Get-Phase160JClassifierFlag {
  param([object]$Task, [string[]]$Names)
  $rules = Get-Phase160JClassifierObjectProperty -Object $Task -Names @("safety_rules") -Default $null
  if ($null -ne $rules) {
    foreach ($name in $Names) {
      if ($rules -is [System.Collections.IDictionary] -and $rules.Contains($name)) {
        return ConvertTo-Phase160JClassifierBoolean -Value $rules[$name] -Default $false
      }
      if ($rules.PSObject.Properties.Name -contains $name) {
        return ConvertTo-Phase160JClassifierBoolean -Value $rules.$name -Default $false
      }
    }
  }
  foreach ($name in $Names) {
    if ($null -ne $Task -and $Task -is [System.Collections.IDictionary] -and $Task.Contains($name)) {
      return ConvertTo-Phase160JClassifierBoolean -Value $Task[$name] -Default $false
    }
    if ($null -ne $Task -and $Task.PSObject.Properties.Name -contains $name) {
      return ConvertTo-Phase160JClassifierBoolean -Value $Task.$name -Default $false
    }
  }
  return $false
}

function Test-Phase160JUnknownUnsafeField {
  param([object]$Object)
  if ($null -eq $Object) {
    return $false
  }
  if ($Object -is [System.Array]) {
    foreach ($entry in @($Object)) {
      if (Test-Phase160JUnknownUnsafeField -Object $entry) {
        return $true
      }
    }
    return $false
  }
  if ($Object -is [string]) {
    return $false
  }
  if ($Object -is [System.Collections.IDictionary]) {
    foreach ($key in $Object.Keys) {
      $name = ([string]$key).ToLowerInvariant()
      $value = $Object[$key]
      if (@("command", "commands", "cmd", "shell_command", "powershell_command", "bash_command", "accepted_repo_command", "repo_command", "live_repo_shell", "exec", "execute", "script_to_run") -contains $name) {
        return $true
      }
      if ($name -eq "code_execution_requested" -and (ConvertTo-Phase160JClassifierBoolean -Value $value -Default $false)) {
        return $true
      }
      if (($name -match "shell|command|exec|script") -and -not (@("safety_rules") -contains $name)) {
        return $true
      }
      if ($null -ne $value -and -not ($value -is [string]) -and -not ($value -is [int]) -and -not ($value -is [bool])) {
        if (Test-Phase160JUnknownUnsafeField -Object $value) {
          return $true
        }
      }
    }
    return $false
  }
  $knownSafe = @(
    "event_type",
    "task_id",
    "id",
    "source",
    "priority",
    "owner_goal",
    "program_goal",
    "curriculum_goal",
    "goal",
    "title",
    "name",
    "desired_next_gap",
    "next_gap",
    "target_gap",
    "expected_outputs",
    "safety_rules",
    "plan_items",
    "plan_steps",
    "lessons",
    "program",
    "curriculum",
    "created_at",
    "success_signals",
    "can_parallelize",
    "runtime_session_only",
    "owner_promotion_required",
    "owner_approval_required",
    "repo_commit_allowed",
    "repo_push_allowed",
    "branch_switch_allowed",
    "live_repo_file_mutation_allowed",
    "protected_state_mutation_allowed",
    "accepted_repo_mutation_allowed",
    "accepted_state_mutation_allowed",
    "accepted_memory_mutation_allowed",
    "accepted_self_model_mutation_allowed",
    "accepted_code_mutation_allowed",
    "accepted_repo_file_mutation_allowed",
    "code_execution_requested"
  )
  $dangerousNames = @(
    "command",
    "commands",
    "cmd",
    "shell_command",
    "powershell_command",
    "bash_command",
    "accepted_repo_command",
    "repo_command",
    "live_repo_shell",
    "exec",
    "execute",
    "script_to_run"
  )
  foreach ($property in $Object.PSObject.Properties) {
    $name = ([string]$property.Name).ToLowerInvariant()
    if ($dangerousNames -contains $name) {
      return $true
    }
    if ($name -eq "code_execution_requested" -and (ConvertTo-Phase160JClassifierBoolean -Value $property.Value -Default $false)) {
      return $true
    }
    if (($name -match "shell|command|exec|script") -and -not ($knownSafe -contains $name)) {
      return $true
    }
    if ($null -ne $property.Value -and -not ($property.Value -is [string]) -and -not ($property.Value -is [int]) -and -not ($property.Value -is [bool])) {
      if (Test-Phase160JUnknownUnsafeField -Object $property.Value) {
        return $true
      }
    }
  }
  return $false
}

function Get-Phase160JOwnerTaskUnsafeReasons {
  param([object]$Task)
  $reasons = @()
  if (Get-Phase160JClassifierFlag -Task $Task -Names @("repo_commit_allowed", "commit_allowed")) {
    $reasons += "unsafe_commit_allowed"
  }
  if (Get-Phase160JClassifierFlag -Task $Task -Names @("repo_push_allowed", "push_allowed")) {
    $reasons += "unsafe_push_allowed"
  }
  if (Get-Phase160JClassifierFlag -Task $Task -Names @("branch_switch_allowed", "git_checkout_allowed")) {
    $reasons += "unsafe_branch_switch_allowed"
  }
  if (Get-Phase160JClassifierFlag -Task $Task -Names @("protected_state_mutation_allowed", "accepted_state_mutation_allowed", "accepted_memory_mutation_allowed", "accepted_self_model_mutation_allowed")) {
    $reasons += "unsafe_protected_state_mutation_allowed"
  }
  if (Get-Phase160JClassifierFlag -Task $Task -Names @("accepted_repo_mutation_allowed", "accepted_code_mutation_allowed", "accepted_repo_file_mutation_allowed", "live_repo_file_mutation_allowed", "repo_file_mutation_allowed")) {
    $reasons += "unsafe_accepted_repo_mutation_allowed"
  }
  if (Test-Phase160JUnknownUnsafeField -Object $Task) {
    $reasons += "unknown_unsafe_field"
  }
  return @($reasons | Select-Object -Unique)
}

function Invoke-Phase160JOwnerTaskSafetyClassification {
  param(
    [object]$Task,
    [object]$NormalizedTask,
    [string]$ParseError = "",
    [object]$ExistingActiveTask = $null,
    [string]$ExistingActiveStatus = "NONE"
  )

  $taskId = if ($null -ne $NormalizedTask -and $NormalizedTask.PSObject.Properties.Name -contains "normalized_task_id") { [string]$NormalizedTask.normalized_task_id } else { "UNPARSED" }
  $existingActiveTaskId = if ($null -ne $ExistingActiveTask -and $ExistingActiveTask.PSObject.Properties.Name -contains "task_id") { [string]$ExistingActiveTask.task_id } else { "NONE" }
  $activeBlocks = ($existingActiveTaskId -ne "NONE" -and -not [string]::IsNullOrWhiteSpace($existingActiveTaskId))

  if (-not [string]::IsNullOrWhiteSpace($ParseError)) {
    return [pscustomobject][ordered]@{
      normalized_task_id = $taskId
      decision = "REJECT_MALFORMED_TASK"
      accepted_by_intake = $false
      quarantine_required = $true
      quarantine_reason = "malformed_json"
      failed_fields = @("json")
      backlog_allowed = $false
      active_allowed = $false
      active_task_blocks_owner_task = $false
      blocked_by_active_task_id = "NONE"
      blocked_by_status = "NONE"
    }
  }

  if ($null -eq $Task -or $null -eq $NormalizedTask) {
    return [pscustomobject][ordered]@{
      normalized_task_id = $taskId
      decision = "REJECT_MALFORMED_TASK"
      accepted_by_intake = $false
      quarantine_required = $true
      quarantine_reason = "malformed_json"
      failed_fields = @("task")
      backlog_allowed = $false
      active_allowed = $false
      active_task_blocks_owner_task = $false
      blocked_by_active_task_id = "NONE"
      blocked_by_status = "NONE"
    }
  }

  if ($NormalizedTask.PSObject.Properties.Name -contains "missing_goal" -and [bool]$NormalizedTask.missing_goal) {
    return [pscustomobject][ordered]@{
      normalized_task_id = $taskId
      decision = "REJECT_MALFORMED_TASK"
      accepted_by_intake = $false
      quarantine_required = $true
      quarantine_reason = "missing_goal"
      failed_fields = @("owner_goal")
      backlog_allowed = $false
      active_allowed = $false
      active_task_blocks_owner_task = $false
      blocked_by_active_task_id = "NONE"
      blocked_by_status = "NONE"
    }
  }

  if ($NormalizedTask.PSObject.Properties.Name -contains "unsupported_task_shape" -and [bool]$NormalizedTask.unsupported_task_shape) {
    return [pscustomobject][ordered]@{
      normalized_task_id = $taskId
      decision = "QUARANTINE_UNSAFE_OWNER_TASK"
      accepted_by_intake = $false
      quarantine_required = $true
      quarantine_reason = "unsupported_task_shape"
      failed_fields = @("task_shape")
      backlog_allowed = $false
      active_allowed = $false
      active_task_blocks_owner_task = $false
      blocked_by_active_task_id = "NONE"
      blocked_by_status = "NONE"
    }
  }

  $unsafeReasons = @(Get-Phase160JOwnerTaskUnsafeReasons -Task $Task)
  if ($unsafeReasons.Count -gt 0) {
    return [pscustomobject][ordered]@{
      normalized_task_id = $taskId
      decision = "QUARANTINE_UNSAFE_OWNER_TASK"
      accepted_by_intake = $false
      quarantine_required = $true
      quarantine_reason = [string]$unsafeReasons[0]
      failed_fields = @($unsafeReasons)
      backlog_allowed = $false
      active_allowed = $false
      active_task_blocks_owner_task = $false
      blocked_by_active_task_id = "NONE"
      blocked_by_status = "NONE"
    }
  }

  return [pscustomobject][ordered]@{
    normalized_task_id = $taskId
    decision = if ($activeBlocks) { "BACKLOG_SAFE_OWNER_TASK" } else { "ACCEPT_SAFE_OWNER_TASK" }
    accepted_by_intake = $true
    quarantine_required = $false
    quarantine_reason = "NONE"
    failed_fields = @()
    backlog_allowed = $true
    active_allowed = -not $activeBlocks
    active_task_blocks_owner_task = $activeBlocks
    blocked_by_active_task_id = $existingActiveTaskId
    blocked_by_status = if ([string]::IsNullOrWhiteSpace($ExistingActiveStatus)) { "ACTIVE" } else { $ExistingActiveStatus }
  }
}
