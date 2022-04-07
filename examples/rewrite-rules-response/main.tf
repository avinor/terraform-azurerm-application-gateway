module "rewrites" {
  source = "../../"

  name                = "rewrite-response"
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
    name = "security-headers"
    rewrite_rule = [
      {
        rule_name                    = "AddSecurityHeaders"
        rule_sequence                = 100
        condition                    = []
        request_header_configuration = []
        response_header_configuration = [
          {
            header_name  = "X-Frame-Options"
            header_value = "SAMEORIGIN"
          },
          {
            header_name  = "X-Content-Type-Options"
            header_value = "nosniff"
          },
        ]
        url = []
      },
    ]
  }]
}
