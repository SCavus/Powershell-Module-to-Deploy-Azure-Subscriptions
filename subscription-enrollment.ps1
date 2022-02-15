[String] [Parameter (Mandatory = $true)] $ClientId,
[String] [Parameter (Mandatory = $true)] $ClientSecret,
[String] [Parameter (Mandatory = $true)] $TenantId

$enrollmentAccount = "123456"
$billingAccount = "1234567"

$secClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $secClientSecret
connect-azaccount -Credential $Credential -Tenant $TenantId -ServicePrincipal

$AllSubscriptions = Get-AzSubscription -TenantId $TenantId
$AllSubscriptions | ConvertTo-Json

$NewSubscriptions = Get-Content './subscription-enrollment/subscriptions.json' | ConvertFrom-Json
$NewSubscriptions | ConvertTo-Json

#Create subscriptions if not exist in prod
foreach ($NewSub in $NewSubscriptions) {
    if ($NewSub.subscription.name -NotIn $AllSubscriptions.name) {
        New-AzSubscriptionAlias -AliasName "$($NewSub.subscription.name)" -SubscriptionName "$($NewSub.subscription.name)" -BillingScope "/providers/Microsoft.Billing/BillingAccounts/$billingAccount/enrollmentAccounts/$enrollmentAccount" -Workload "$($NewSub.subscription.workload)"
    }
    #Move created subscriptions to the right management groups
    New-AzManagementGroupSubscription -GroupId "$($NewSub.name)" -SubscriptionId "$(Get-AzSubscription -SubscriptionName "$($NewSub.subscription.name)")"
}
