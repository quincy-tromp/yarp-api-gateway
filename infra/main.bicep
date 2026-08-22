param location string
param tenantId string

param appServicePlanName string
param productApiName string
param orderApiName string
param overviewBffName string
param yarpProxyName string

@secure()
param productApiClientId string

@secure()
param orderApiClientId string

@secure()
param overviewBffClientId string

@secure()
param overviewBffClientSecret string

@secure()
param jwtAuthority string

@secure()
param jwtIssuer string

@description('Create the app service plan')
resource servicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'F1'
    capacity: 0
  }
  kind: 'linux'
  properties: {
    reserved: true
    zoneRedundant: false
  }
}

var apps = [
  {
    name: productApiName
  }
  {
    name: orderApiName
  }
  {
    name: overviewBffName
  }
  {
    name: yarpProxyName
  }
]

@description('Create the app services')
resource appServices 'Microsoft.Web/sites@2022-09-01' = [for app in apps: {
  name: app.name
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: servicePlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}]

var productApi = appServices[0]
var orderApi = appServices[1]
var overviewBff = appServices[2]

resource productApiAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appServices[0]
  name: 'appsettings'
  properties: {
    AzureAd__TenantId: tenantId
    AzureAd__ClientId: productApiClientId
  }
}

resource orderApiAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appServices[1]
  name: 'appsettings'
  properties: {
    AzureAd__TenantId: tenantId
    AzureAd__ClientId: orderApiClientId
  }
}

resource overviewBffAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appServices[2]
  name: 'appsettings'
  properties: {
    ExternalApis__Products__BaseUrl: 'https://${productApi.name}.azurewebsites.net'
    ExternalApis__Orders__BaseUrl: 'https://${orderApi.name}.azurewebsites.net'

    AzureAd__TenantId: tenantId
    AzureAd__ClientId: overviewBffClientId
    AzureAd__ClientCredentials__0__ClientSecret: overviewBffClientSecret
  }
}

resource yarpAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appServices[3]
  name: 'appsettings'
  properties: {
    Jwt__Authority: jwtAuthority
    Jwt__Issuer: jwtIssuer
    Jwt__Audiences__0: productApiClientId
    Jwt__Audiences__1: orderApiClientId
    Jwt__Audiences__2: overviewBffClientId

    ReverseProxy__Clusters__products__Destinations__productsapi__Address: 'https://${productApi.name}.azurewebsites.net'
    ReverseProxy__Clusters__orders__Destinations__ordersapi__Address: 'https://${orderApi.name}.azurewebsites.net'
    ReverseProxy__Clusters__overview__Destinations__overviewbff__Address: 'https://${overviewBff.name}.azurewebsites.net'
  }
}
