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
            operation = "baseline_request_processing"
            mission = $Profile.mission
            payload_key_count = @($PayloadKeys).Count
            payload_keys = $PayloadKeys
        }
        diagnostics = [ordered]@{
            package_profile = $Profile.package_profile
            capability_count = @($Profile.capabilities).Count
            github_action_launch_surface = "delivery_artifact_present"
        }
    }
}
