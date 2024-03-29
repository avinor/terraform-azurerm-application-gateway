# Application Gateway

*This template is not optimal at the moment due to missing azurerm provider features. Will be fixed as soon as there is
an updated provider*

This module deploys a simplified version of Application Gateway v2, it does not support v1 of Application Gateway. It is
a slim down version that is meant to be configured by an external application, in this
case https://github.com/Azure/application-gateway-kubernetes-ingress. It will create some endpoints and backends because
that is required, but will ignore any changes to them on later deployments. That way any changes done by external
application will be kept.

Although it is slimmed down there are some options to configure the security policies, private ip and waf
configurations. It will however always use sku Standard_v2 or WAF_v2 based on if waf is enabled.

## Usage

To create a simple application gateway.

```terraform
module "simple" {
  source  = "avinor/application-gateway/azurerm"
  version = "1.0.0"

  resource_group_name = "appgw-rg"
  location            = "westeurope"
  subnet_id           = "/subscriptions/...."

  private_ip_address = "10.0.0.100"

  capacity = {
    min = 1
    max = 2
  }

  zones = ["1", "2", "3"]
}
```

## Diagnostics

Diagnostics settings can be sent to either storage account, event hub or Log Analytics workspace. The
variable `diagnostics.destination` is the id of receiver, ie. storage account id, event namespace authorization rule id
or log analytics resource id. Depending on what id is it will detect where to send. Unless using event namespace
the `eventhub_name` is not required, just set to `null` for storage account and log analytics workspace.

Setting `all` in logs and metrics will send all possible diagnostics to destination. If not using `all` type name of
categories to send.

## WAF

To enable WAF set `waf_enabled` to true and it will automatically deploy sku WAF_v2 (this required redeploy if it was
disabled). To configure WAF settings set the `waf_configuration` variable. It will default to resonable values.

## Rewrite rules

Rewrite rules can be specified and should be linked to routes outside this module.

### Custom policies

In addition to the default policies in firewall it is also possible to add custom policies. These can be additional
security rules or exceptions to allow traffic. Using the `custom_policies` variable it is possible to customize the
firewall rules. It will create a custom policy and associate it with the firewall.

`custom_policies` variable follow similar structure as the terraform resource. Priority will be set according to order
in list, higher priority for elements early in the list.

Example of policy:

```terraform
custom_policies = [
  {
    name             = "AllowRefererBeginWithExample"
    rule_type        = "MatchRule"
    action           = "Allow"
    match_conditions = [
      {
        match_variables = [
          {
            match_variable = "RequestHeaders"
            selector       = "referer"
          }
        ]
        operator           = "BeginsWith"
        negation_condition = false
        match_values       = ["https://example.com"]
      }
    ]
  }
]
```

For details how to write custom policies see
the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/application-gateway/custom-waf-rules-overview).

### Managed rules

It is possible to add waf policies for managed rules to disable rules.

```terraform
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
```

for details for managed rules se
the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules?tabs=owasp31)

## Managed Identity

Since this module was created to be used together with AKS it also creates a managed identity that have access to modify
the Application Gateway. Id and client_id of managed identity is part of output and can be used by external application
to control configurations.
