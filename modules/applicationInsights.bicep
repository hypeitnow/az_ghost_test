targetScope = 'resourceGroup'

@description('Application Insights name')
@minLength(1)
@maxLength(260)
param applicationInsightsName string

@description('Location to deploy the resources')
param location string = resourceGroup().location

@description('Log Analytics workspace id to use for diagnostics settings')
param logAnalyticsWorkspaceId string

@description('webAppServicePlan id for autoscale setiings')
param appServicePlanId string

@description('webAppServicePlan name for autoscale setiings')
param autoscaleName string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

resource applicationInsightsDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: applicationInsights
  name: 'InsightsDiagnostics'
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
        category: 'AppAvailabilityResults'
        enabled: true
      }
      {
        category: 'AppBrowserTimings'
        enabled: true
      }
      {
        category: 'AppEvents'
        enabled: true
      }
      {
        category: 'AppMetrics'
        enabled: true
      }
      {
        category: 'AppDependencies'
        enabled: true
      }
      {
        category: 'AppExceptions'
        enabled: true
      }
      {
        category: 'AppPageViews'
        enabled: true
      }
      {
        category: 'AppPerformanceCounters'
        enabled: true
      }
      {
        category: 'AppRequests'
        enabled: true
      }
      {
        category: 'AppSystemEvents'
        enabled: true
      }
      {
        category: 'AppTraces'
        enabled: true
      }
    ]
  }
}
resource AutoscaleSetting 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  location: location
  properties: {
    name: autoscaleName
    enabled: true
    profiles: [
      {
        name: 'Auto created scale condition'
        capacity: {
          minimum: '1'
          maximum: '4'
          default: '1'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 85
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
              metricResourceUri: appServicePlanId
              dividePerInstance: false
            }
          }
        ]
      }
    ]
    notifications: []
    targetResourceLocation: 'Germany West Central'
    targetResourceUri: appServicePlanId
  }
  name: autoscaleName
}
output InstrumentationKey string = applicationInsights.properties.InstrumentationKey
output ConnectionString string = applicationInsights.properties.ConnectionString
