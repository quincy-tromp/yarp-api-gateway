param location string
param tenantId string

param appServicePlanName string
param productApiName string
param orderApiName string
param overviewBffName string
param yarpProxyName string

param logWorkspaceName string
param yarpAppInsightName string
param productAppInsightName string
param orderAppInsightName string
param overviewAppInsightName string

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

resource productApi 'Microsoft.Web/sites@2022-09-01' = {
  name: productApiName
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
}

resource orderApi 'Microsoft.Web/sites@2022-09-01' = {
  name: orderApiName
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
}

resource overviewBff 'Microsoft.Web/sites@2022-09-01' = {
  name: overviewBffName
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
}

resource yarpProxy 'Microsoft.Web/sites@2022-09-01' = {
  name: yarpProxyName
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
}

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logWorkspaceName
  location: location
  properties: {
    retentionInDays: 5
  }
}

resource yarpInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: yarpAppInsightName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logWorkspace.id
  }
}

resource productInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: productAppInsightName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logWorkspace.id
  }
}

resource orderInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: orderAppInsightName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logWorkspace.id
  }
}

resource overviewInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: overviewAppInsightName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logWorkspace.id
  }
}

resource productApiAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: productApi
  name: 'appsettings'
  properties: {
    AzureAd__TenantId: tenantId
    AzureAd__ClientId: productApiClientId
    APPLICATIONINSIGHTS_CONNECTION_STRING: productInsights.properties.ConnectionString
  }
}

resource orderApiAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: orderApi
  name: 'appsettings'
  properties: {
    AzureAd__TenantId: tenantId
    AzureAd__ClientId: orderApiClientId
    APPLICATIONINSIGHTS_CONNECTION_STRING: orderInsights.properties.ConnectionString
  }
}

resource overviewBffAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: overviewBff
  name: 'appsettings'
  properties: {
    ExternalApis__Products__BaseUrl: 'https://${productApi.name}.azurewebsites.net'
    ExternalApis__Orders__BaseUrl: 'https://${orderApi.name}.azurewebsites.net'
    AzureAd__TenantId: tenantId
    AzureAd__ClientId: overviewBffClientId
    AzureAd__ClientCredentials__0__ClientSecret: overviewBffClientSecret
    APPLICATIONINSIGHTS_CONNECTION_STRING: overviewInsights.properties.ConnectionString
  }
}

resource yarpAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: yarpProxy
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
    APPLICATIONINSIGHTS_CONNECTION_STRING: yarpInsights.properties.ConnectionString
  }
}
