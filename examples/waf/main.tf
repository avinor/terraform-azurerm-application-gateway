module "waf" {
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

  waf_enabled = true
  waf_configuration = {
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.1"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
  }

  managed_policies_override = [
    {
      rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
      disabled_rules  = ["920300", "920440"]
    },
    {
      rule_group_name = "REQUEST-930-APPLICATION-ATTACK-LFI"
      disabled_rules  = ["930100"]
    },
  ]

}