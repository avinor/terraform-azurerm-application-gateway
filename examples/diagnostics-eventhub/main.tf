module "simple" {
  source = "../../"

  name                = "diagnostics"
  resource_group_name = "appgw-rg"
  location            = "westeurope"
  subnet_id           = "/subscriptions/...."

  private_ip_address = "10.0.0.100"

  capacity = {
    min = 1
    max = 2
  }

  zones = ["1", "2", "3"]

  diagnostics = {
    destination          = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/XXXXXXXXXX/providers/Microsoft.EventHub/namespaces/XXXXXXXXXX"
    eventhub_name_log    = "diagnostics-log"
    eventhub_name_metric = "diagnostics-metric"
    logs                 = ["all"]
    metrics              = ["all"]
  }
}