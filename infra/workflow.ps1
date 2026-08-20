$location = 'westeurope'
$resourceGroup = 'yarp-sample'
$managedIdentity = 'yarp-workflow-identity'
$subscriptionId = '55404129-7640-466f-97c0-aab8910fdc82'
$federatedCredentialName = 'yarp-fed-cred'
$issuer = 'https://token.actions.githubusercontent.com'
$audience = 'api://AzureADTokenExchange'
$githubUsername = 'quincy-tromp'
$githubRepo = 'yarp-api-gateway'


Write-Host "Checking Azure CLI authentication..." -ForegroundColor Cyan
az account show 

Write-Host "Checking GitHub CLI authentication..." -ForegroundColor Cyan
gh auth status --active 

Write-Host "Setting subscription: $SubscriptionId" -ForegroundColor Cyan
az account set --subscription $SubscriptionId 

Write-Host "Creating resource group" -ForegroundColor Cyan

az group create `
    --location $location `
    --name $resourceGroup

Write-Host "Creating identity" -ForegroundColor Cyan

$identityCreated = az identity create `
  --resource-group $resourceGroup `
  --name $managedIdentity | ConvertFrom-Json

Write-Host "Getting github user id" -ForegroundColor Cyan

$githubUserId = gh api /user --jq ".id" 

Write-Host "Getting github repo id" -ForegroundColor Cyan

$githubRepoId = gh api "/repos/${githubUsername}/${githubRepo}" --jq ".id"

$subject = "repo:${githubUsername}@${githubUserId}/${githubRepo}@${githubRepoId}:ref:refs/heads/main"

Write-Host "Creating federated credential" -ForegroundColor Cyan

az identity federated-credential create `
  --name $federatedCredentialName `
  --identity-name $managedIdentity `
  --resource-group $resourceGroup `
  --issuer $issuer `
  --subject $subject `
  --audiences $audience

Write-Host "Assigning role..." -ForegroundColor Cyan

az role assignment create `
  --assignee $identityCreated.clientId `
  --role Contributor `
  --scope "/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}"