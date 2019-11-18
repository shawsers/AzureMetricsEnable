#login with a sub aleready onboarded that can see the Turbo custom role
$sub = login-azurermsubscription
$turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly'
    $newsub = Read-Host -Prompt 'enter the sub ID you want to update with the Turbo custom role:'
    $readNewSub = Select-AzureRmSubscription -Subscription $newsub -ErrorAction Stop
    $subscriptionId = $readNewSub.subscription.ID
    $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
    $turboCustomRoleName = $turboCustomRole.Name
    Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
    $setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
    Write-Host "Waiting 5 mins for Azure AD Sync to complete before checking again..." -ForegroundColor Green
    Start-Sleep 300
    $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
    $checkTurboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly'
    if ($checkTurboCustomRole -eq $null){
        Write-Host "Cannot find Turbo custom role, please rerun the script" -ForegroundColor Red -BackgroundColor Black
        Exit
    } else {
        Write-Host "Turbo custom role found, script complete" -ForegroundColor Green
    }
    #END OF SCRIPT
