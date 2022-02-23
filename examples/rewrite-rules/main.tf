module "rewrites" {
  source = "../../"

  name                = "waf"
  resource_group_name = "appgw-rg"
  location            = "westeurope"
  subnet_id           = "/subscriptions/...."

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
        url = []
      },
    ]
  }]
}
