using 'main.bicep'

param location = 'westeurope'
param tenantId = 'f9041973-e228-45ce-8dbd-a51b4d7d3203'

param appServicePlanName = 'yarp-app-service-plan'
param productApiName = 'product-api-site'
param orderApiName = 'order-api-site'
param overviewBffName = 'overview-bff-site'
param yarpProxyName = 'yarp-proxy-site'

param logWorkspaceName = 'yarp-log-workspace'
param yarpAppInsightName = 'yarp-insight'
param productAppInsightName = 'product-insight'
param orderAppInsightName = 'order-insight'
param overviewAppInsightName = 'overview-insight'

param productApiClientId = readEnvironmentVariable('PRODUCT_API_CLIENT_ID')
param orderApiClientId = readEnvironmentVariable('ORDER_API_CLIENT_ID')
param overviewBffClientId = readEnvironmentVariable('OVERVIEW_BFF_CLIENT_ID')
param overviewBffClientSecret = readEnvironmentVariable('OVERVIEW_BFF_CLIENT_SECRET')
param jwtAuthority = readEnvironmentVariable('JWT_AUTHORITY')
param jwtIssuer = readEnvironmentVariable('JWT_ISSUER')

param productsApiScope = readEnvironmentVariable('PRODUCT_API_SCOPE')
param ordersApiScope = readEnvironmentVariable('ORDER_API_SCOPE')
