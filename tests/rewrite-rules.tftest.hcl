variables {
  name                = "rewrite"
  resource_group_name = "appgw-rg"
  location            = "westeurope"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mygroup1/providers/Microsoft.Network/virtualNetworks/myvnet1/subnets/mysub"

  private_ip_address = "10.0.0.100"

  capacity = {
    min = 1
    max = 2
  }

  zones = ["1", "2", "3"]

  rewrite_rule_sets = [{
    name = "rewrites"
    rewrite_rule = [
      {
        rule_name     = "Allow foocookie"
        rule_sequence = 100
        condition = [
          {
            ignore_case = false
            negate      = false
            pattern     = ".*\\bfoocookie=.*"
            variable    = "http_req_Cookie"
          }
        ]
        request_header_configuration = [
          {
            header_name  = "Cookie"
            header_value = "foocookie={var_cookie_foocookie}"
          }
        ]
        response_header_configuration = []
        url                           = []
      },
    ]
  }]
}

run "rewrite-rules" {
  command = plan
}