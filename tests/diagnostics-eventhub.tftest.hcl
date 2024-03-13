variables {
  name                = "diagnostics"
  resource_group_name = "appgw-rg"
  location            = "westeurope"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mygroup1/providers/Microsoft.Network/virtualNetworks/myvnet1/subnets/mysub"

  private_ip_address = "10.0.0.100"

  capacity = {
    min = 1
    max = 2
  }

  zones = ["1", "2", "3"]

  diagnostics = {
    destination   = "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/XXXXXXXXXX/providers/Microsoft.EventHub/namespaces/XXXXXXXXXX/authorizationRules/myrule"
    eventhub_name = "diagnostics"
    logs          = ["all"]
    metrics       = ["all"]
  }
}

run "diagnostics-eventhub" {
  command = plan
}