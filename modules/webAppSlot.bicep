targetScope = 'resourceGroup'

@minLength(2)
@maxLength(60)
param webAppSlotName string

@description('Location to deploy the resources')
param location string = resourceGroup().location

@description('App Service Plan id to host the app')
param appServicePlanId string

@description('Log Analytics workspace id to use for diagnostics settings')
param logAnalyticsWorkspaceId string

@description('Ghost container full image name and tag')
param ghostContainerImage string

@description('Storage account name to store Ghost content files')
param storageAccountName string

@secure()
param storageAccountAccessKey string

@description('File share name on the storage account to store Ghost content files')
param fileShareName string

@description('Path to mount the file share in the container')
param containerMountPath string

var containerImageReference = 'DOCKER|${ghostContainerImage}'

resource webAppSlot 'Microsoft.Web/sites@2021-01-15' = {
  name: webAppSlotName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clientAffinityEnabled: false
    serverFarmId: appServicePlanId
    httpsOnly: true
    enabled: true
    reserved: true
    siteConfig: {
      managedPipelineMode: 'Integrated'
      http20Enabled: true
      httpLoggingEnabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      linuxFxVersion: containerImageReference
      alwaysOn: true
      use32BitWorkerProcess: false
      azureStorageAccounts: {
        ContentFilesVolume: {
          type: 'AzureFiles'
          accountName: storageAccountName
          shareName: fileShareName
          mountPath: containerMountPath
          accessKey: storageAccountAccessKey
        }
      }
    }
  }
}

resource siteConfig 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: webAppSlot
  name: 'web'
  properties: {
    ipSecurityRestrictions: [
      {
        ipAddress: 'AzureFrontDoor.Backend'
        action: 'Allow'
        tag: 'ServiceTag'
        priority: 300
        name: 'Access from Azure Front Door'
        description: 'Rule for access from Azure Front Door'
      }
    ]
  }
}
resource deplConfig 'Microsoft.Web/sites/sourcecontrols@2021-01-15' = {
  parent: webAppSlot
  name: 'web'
  properties: {
    isManualIntegration: false
}

}
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: webAppSlot
  name: 'WebAppDiagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
  }
}

output name string = webAppSlot.name
output hostName string = webAppSlot.properties.hostNames[0]
output principalId string = webAppSlot.identity.principalId
