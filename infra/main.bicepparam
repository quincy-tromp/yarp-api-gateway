using 'main.bicep'

param location = 'westeurope'
param tenantId = 'f9041973-e228-45ce-8dbd-a51b4d7d3203'

param appServicePlanName = 'yarp-app-service-plan'
param productApiName = 'product-web-api'
param orderApiName = 'order-web-api'
param overviewBffName = 'overview-web-bff'
param yarpProxyName = 'yarp-web-proxy'

param productApiClientId = readEnvironmentVariable('PRODUCT_API_CLIENT_ID')
param orderApiClientId = readEnvironmentVariable('ORDER_API_CLIENT_ID')
param overviewBffClientId = readEnvironmentVariable('OVERVIEW_BFF_CLIENT_ID')
param overviewBffClientSecret = readEnvironmentVariable('OVERVIEW_BFF_CLIENT_SECRET')
param jwtAuthority = readEnvironmentVariable('JWT_AUTHORITY')
param jwtIssuer = readEnvironmentVariable('JWT_ISSUER')
