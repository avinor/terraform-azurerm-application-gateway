# Application Gateway

This module deploys a simplified version of Application Gateway v2, it does not support v1 of Application Gateway. It is a slim down version that is meant to be configured by an external application, in this case https://github.com/Azure/application-gateway-kubernetes-ingress. It will create some endpoints and backends because that is required, but will ignore any changes to them on later deployments. That way any changes done by external application will be kept.

Although it is slimmed down there are some options to configure the security policies, private ip and waf configurations. It will however always use sku Standard_v2 or WAF_v2 based on if waf is enabled.

## Usage

To create a simple application gateway deployed with [tau](https://github.com/avinor/tau).

```terraform
module {
    source = "avinor/application-gateway/azurerm"
    version = "1.0.0"
}

inputs {
    name = "simple"
    resource_group_name = "appgw-rg"
    subnet_id = "/subscriptions/...."

    private_ip_address = "10.0.0.100"

    capacity = {
        min = 1
        max = 2
    }

    zones = ["1", "2", "3"]
}
```

## WAF

To enable WAF set `waf_enabled` to true and it will automatically deploy sku WAF_v2 (this required redeploy if it was disabled). To configure WAF settings set the `waf_configuration` variable. It will default to resonable values.

## Managed Identity

Since this module was created to be used together with AKS it also creates a managed identity that have access to modify the Application Gateway. Id and client_id of managed identity is part of output and can be used by external application to control configurations.
