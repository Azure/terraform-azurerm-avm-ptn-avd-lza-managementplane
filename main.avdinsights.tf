# Create Azure Log Analytics workspace for Azure Virtual Desktop
resource "azurerm_log_analytics_workspace" "this" {
  location            = var.log_analytics_workspace_location
  name                = var.log_analytics_workspace_name
  resource_group_name = var.monitor_data_collection_rule_resource_group_name
  sku                 = "PerGB2018"
  tags                = var.log_analytics_workspace_tags
}

# Create resources for Azure Virtual Desktop Insights data collection rules
module "avm_ptn_avd_lza_insights" {
  source                                = "Azure/avm-ptn-avd-lza-insights/azurerm"
  version                               = "0.1.3"
  enable_telemetry                      = var.enable_telemetry
  monitor_data_collection_rule_location = var.monitor_data_collection_rule_location
  monitor_data_collection_rule_kind     = "Windows"
  monitor_data_collection_rule_name     = var.monitor_data_collection_rule_name
  monitor_data_collection_rule_data_flow = [
    {
      destinations = [azurerm_log_analytics_workspace.this.name]
      streams      = ["Microsoft-Perf", "Microsoft-Event"]
    }
  ]
  monitor_data_collection_rule_destinations = {
    log_analytics = {
      name                  = azurerm_log_analytics_workspace.this.name
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }
  monitor_data_collection_rule_data_sources = {
    performance_counter = [
      {
        counter_specifiers            = ["\\LogicalDisk(C:)\\Avg. Disk Queue Length", "\\LogicalDisk(C:)\\Current Disk Queue Length", "\\Memory\\Available Mbytes", "\\Memory\\Page Faults/sec", "\\Memory\\Pages/sec", "\\Memory\\% Committed Bytes In Use", "\\PhysicalDisk(*)\\Avg. Disk Queue Length", "\\PhysicalDisk(*)\\Avg. Disk sec/Read", "\\PhysicalDisk(*)\\Avg. Disk sec/Transfer", "\\PhysicalDisk(*)\\Avg. Disk sec/Write", "\\Processor Information(_Total)\\% Processor Time", "\\User Input Delay per Process(*)\\Max Input Delay", "\\User Input Delay per Session(*)\\Max Input Delay", "\\RemoteFX Network(*)\\Current TCP RTT", "\\RemoteFX Network(*)\\Current UDP Bandwidth"]
        name                          = "perfCounterDataSource10"
        sampling_frequency_in_seconds = 30
        streams                       = ["Microsoft-Perf"]
      },
      {
        counter_specifiers            = ["\\LogicalDisk(C:)\\% Free Space", "\\LogicalDisk(C:)\\Avg. Disk sec/Transfer", "\\Terminal Services(*)\\Active Sessions", "\\Terminal Services(*)\\Inactive Sessions", "\\Terminal Services(*)\\Total Sessions"]
        name                          = "perfCounterDataSource30"
        sampling_frequency_in_seconds = 30
        streams                       = ["Microsoft-Perf"]
      }
    ],
    windows_event_log = [
      {
        name           = "eventLogsDataSource"
        streams        = ["Microsoft-Event"]
        x_path_queries = ["Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "System!*", "Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Application!*[System[(Level=2 or Level=3)]]", "Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]"]
      }
    ]
  }
  monitor_data_collection_rule_resource_group_name = var.monitor_data_collection_rule_resource_group_name
}
