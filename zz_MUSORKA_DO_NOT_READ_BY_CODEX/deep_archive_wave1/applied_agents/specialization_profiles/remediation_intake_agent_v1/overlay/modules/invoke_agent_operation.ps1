function Invoke-AgentOperation {
    param(
        [object]$Request,
        [object]$Profile
    )

    $PayloadKeys = @()
    if ($null -ne $Request.payload) {
        $PayloadKeys = @($Request.payload.PSObject.Properties.Name)
    }

    return [pscustomobject]@{
        status = "PASS"
        request_id = $Request.request_id
        agent_id = $Profile.agent_id
        result = [ordered]@{
            operation = "remediation_intake_mode_v1"
            mission = $Profile.mission
            payload_key_count = @($PayloadKeys).Count
            payload_keys = $PayloadKeys
            next_alert_id = "remediation_intake_agent_intake_request"
            escalation_status = "INTAKE_READY"
        }
        diagnostics = [ordered]@{
            package_profile = $Profile.package_profile
            specialization_profile = $Profile.agent_id
            capability_count = @($Profile.capabilities).Count
            github_action_launch_surface = "delivery_artifact_present"
        }
    }
}
