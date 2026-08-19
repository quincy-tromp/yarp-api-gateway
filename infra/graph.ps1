<#
.SYNOPSIS
    Configures the Entra ID applications used by the YARP sample.

.DESCRIPTION
    Creates the Product API, Order API, Overview BFF, and Postman client apps,
    configures their OAuth scopes, and grants the required delegated permissions.
#>

#Requires -Version 5.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$SubscriptionId = "55404129-7640-466f-97c0-aab8910fdc82"
$SignInAudience = "AzureADMyOrg"
$PostmanClientName = "postman-client"
$PostmanRedirectUri = "https://oauth.pstmn.io/v1/callback"
$AzureAdGraphId = "00000003-0000-0000-c000-000000000000"
$UserReadScopeId = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"

$productApiName = "product-api"
$productApiScopeName = "Products.Read"
$productApiScopeId = "fd5a16f5-b441-4fcd-a173-7a5d6150dce9"
$productApiDisplayName = "Access Product API"
$productApiDescription = "Allows access to Product API"

$orderApiName = "order-api"
$orderApiScopeName = "Orders.Read"
$orderApiScopeId = "fd3a16f4-b442-4fed-b178-9a5e6141dcf2"
$orderApiDisplayName = "Access Order API"
$orderApiDescription = "Allows access to Order API"

$overviewBffName = "overview-bff"
$overviewBffScopeName = "Overview.Read"
$overviewBffScopeId = "cd3a16b5-b442-4fed-f778-8a5e8148dcf3"
$overviewBffDisplayName = "Access Overview BFF"
$overviewBffDescription = "Allows access to Overview BFF"

# Temporary files for OAuth scope configuration
$productOauth2ScopesFile = New-TemporaryFile
$orderOauth2ScopesFile = New-TemporaryFile
$overviewOauth2ScopesFile = New-TemporaryFile

function Write-Section {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )

    Write-Host ""
    Write-Host $Text -ForegroundColor $Color
}

try {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "YARP Gateway - Entra ID Setup" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

    Write-Section "Checking Azure CLI authentication..." -Color Cyan
    az account show --output none | Out-Null

    Write-Section "Setting subscription: $SubscriptionId" -Color Cyan
    az account set --subscription $SubscriptionId --output none | Out-Null

    # Product API
    Write-Section "Configuring Product API" -Color Green
    $productApiApp = az ad app create `
        --display-name $productApiName `
        --sign-in-audience $SignInAudience `
        --requested-access-token-version 2 | ConvertFrom-Json

    if ($null -eq $productApiApp.appId) {
        throw "Failed to create Product API application."
    }

    $productApiAppId = $productApiApp.appId
    Write-Host "Product API App ID: $productApiAppId" -ForegroundColor Green

    az ad sp create --id $productApiAppId | Out-Null
    az ad app permission add --id $productApiAppId --api $AzureAdGraphId --api-permissions "$UserReadScopeId=Scope" | Out-Null
    az ad app permission grant --id $productApiAppId --api $AzureAdGraphId --scope "User.Read" | Out-Null

    $productApiOauth2ScopesJson = @{
        oauth2PermissionScopes = @(
            @{
                adminConsentDescription = $productApiDescription
                adminConsentDisplayName = $productApiDisplayName
                id = $productApiScopeId
                isEnabled = $true
                type = "Admin"
                value = $productApiScopeName
            }
        )
    }
    $productApiOauth2ScopesJson | ConvertTo-Json -Depth 10 | Set-Content $productOauth2ScopesFile.FullName

    az ad app update --id $productApiAppId --identifier-uris "api://$productApiAppId" --set "api=@$($productOauth2ScopesFile.FullName)" | Out-Null

    # Order API
    Write-Section "Configuring Order API" -Color Green
    $orderApiApp = az ad app create `
        --display-name $orderApiName `
        --sign-in-audience $SignInAudience `
        --requested-access-token-version 2 | ConvertFrom-Json

    if ($null -eq $orderApiApp.appId) {
        throw "Failed to create Order API application."
    }

    $orderApiAppId = $orderApiApp.appId
    Write-Host "Order API App ID: $orderApiAppId" -ForegroundColor Green

    az ad sp create --id $orderApiAppId | Out-Null
    az ad app permission add --id $orderApiAppId --api $AzureAdGraphId --api-permissions "$UserReadScopeId=Scope" | Out-Null
    az ad app permission grant --id $orderApiAppId --api $AzureAdGraphId --scope "User.Read" | Out-Null

    $orderApiOauth2ScopesJson = @{
        oauth2PermissionScopes = @(
            @{
                adminConsentDescription = $orderApiDescription
                adminConsentDisplayName = $orderApiDisplayName
                id = $orderApiScopeId
                isEnabled = $true
                type = "Admin"
                value = $orderApiScopeName
            }
        )
    }
    $orderApiOauth2ScopesJson | ConvertTo-Json -Depth 10 | Set-Content $orderOauth2ScopesFile.FullName

    az ad app update --id $orderApiAppId --identifier-uris "api://$orderApiAppId" --set "api=@$($orderOauth2ScopesFile.FullName)" | Out-Null

    # Overview BFF
    Write-Section "Configuring Overview BFF" -Color Green
    $overviewBffApp = az ad app create `
        --display-name $overviewBffName `
        --sign-in-audience $SignInAudience `
        --requested-access-token-version 2 | ConvertFrom-Json

    if ($null -eq $overviewBffApp.appId) {
        throw "Failed to create Overview BFF application."
    }

    $overviewBffAppId = $overviewBffApp.appId
    Write-Host "Overview BFF App ID: $overviewBffAppId" -ForegroundColor Green

    az ad sp create --id $overviewBffAppId | Out-Null
    az ad app permission add --id $overviewBffAppId --api $AzureAdGraphId --api-permissions "$UserReadScopeId=Scope" | Out-Null
    az ad app permission grant --id $overviewBffAppId --api $AzureAdGraphId --scope "User.Read" | Out-Null

    az ad app permission add --id $overviewBffAppId --api $productApiAppId --api-permissions "$productApiScopeId=Scope" | Out-Null
    az ad app permission grant --id $overviewBffAppId --api $productApiAppId --scope $productApiScopeName | Out-Null

    az ad app permission add --id $overviewBffAppId --api $orderApiAppId --api-permissions "$orderApiScopeId=Scope" | Out-Null
    az ad app permission grant --id $overviewBffAppId --api $orderApiAppId --scope $orderApiScopeName | Out-Null

    $overviewBffOauth2ScopesJson = @{
        oauth2PermissionScopes = @(
            @{
                adminConsentDescription = $overviewBffDescription
                adminConsentDisplayName = $overviewBffDisplayName
                id = $overviewBffScopeId
                isEnabled = $true
                type = "Admin"
                value = $overviewBffScopeName
            }
        )
    }
    $overviewBffOauth2ScopesJson | ConvertTo-Json -Depth 10 | Set-Content $overviewOauth2ScopesFile.FullName

    az ad app update --id $overviewBffAppId --identifier-uris "api://$overviewBffAppId" --set "api=@$($overviewOauth2ScopesFile.FullName)" | Out-Null

    # Postman client
    Write-Section "Configuring Postman client" -Color Green
    $postmanApp = az ad app create `
        --display-name $PostmanClientName `
        --sign-in-audience "AzureADMyOrg" `
        --public-client-redirect-uris $PostmanRedirectUri `
        --requested-access-token-version 2 | ConvertFrom-Json

    if ($null -eq $postmanApp.appId) {
        throw "Failed to create Postman application."
    }

    $postmanAppId = $postmanApp.appId
    Write-Host "Postman Client App ID: $postmanAppId" -ForegroundColor Green

    az ad sp create --id $postmanAppId | Out-Null
    az ad app permission add --id $postmanAppId --api $AzureAdGraphId --api-permissions "$UserReadScopeId=Scope" | Out-Null
    az ad app permission grant --id $postmanAppId --api $AzureAdGraphId --scope "User.Read" | Out-Null

    az ad app permission add --id $postmanAppId --api $productApiAppId --api-permissions "$productApiScopeId=Scope" | Out-Null
    az ad app permission grant --id $postmanAppId --api $productApiAppId --scope $productApiScopeName | Out-Null

    az ad app permission add --id $postmanAppId --api $orderApiAppId --api-permissions "$orderApiScopeId=Scope" | Out-Null
    az ad app permission grant --id $postmanAppId --api $orderApiAppId --scope $orderApiScopeName | Out-Null

    az ad app permission add --id $postmanAppId --api $overviewBffAppId --api-permissions "$overviewBffScopeId=Scope" | Out-Null
    az ad app permission grant --id $postmanAppId --api $overviewBffAppId --scope $overviewBffScopeName | Out-Null

    Write-Section "Setup completed successfully" -Color Green
    Write-Host "Product API: $productApiAppId" -ForegroundColor Cyan
    Write-Host "Order API:   $orderApiAppId" -ForegroundColor Cyan
    Write-Host "Overview BFF: $overviewBffAppId" -ForegroundColor Cyan
    Write-Host "Postman:     $postmanAppId" -ForegroundColor Cyan
}
catch {
    Write-Host ""
    Write-Host "ERROR: Setup failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    Write-Section "Cleaning up temporary files..." -Color Cyan
    if ($productOauth2ScopesFile) { Remove-Item $productOauth2ScopesFile.FullName -Force -ErrorAction SilentlyContinue }
    if ($orderOauth2ScopesFile) { Remove-Item $orderOauth2ScopesFile.FullName -Force -ErrorAction SilentlyContinue }
    if ($overviewOauth2ScopesFile) { Remove-Item $overviewOauth2ScopesFile.FullName -Force -ErrorAction SilentlyContinue }
}