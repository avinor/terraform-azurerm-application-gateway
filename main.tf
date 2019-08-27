terraform {
  required_version = ">= 0.12.0"
  required_providers {
    azurerm = ">= 1.32.0"
  }
}

locals {
  sku_name = var.waf_enabled ? "WAF_v2" : "Standard_v2"
  sku_tier = var.waf_enabled ? "WAF_v2" : "Standard_v2"

  backend_address_pool_name      = "${var.name}-beap"
  frontend_port_name             = "${var.name}-feport"
  frontend_ip_configuration_name = "${var.name}-feip"
  http_setting_name              = "${var.name}-be-htst"
  listener_name                  = "${var.name}-httplstn"
  request_routing_rule_name      = "${var.name}-rqrt"

  merged_tags = merge(var.tags, { managed-by-k8s-ingress = "" })
}

#
# Resource group
#

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

#
# User Managed Identity
#

resource "azurerm_user_assigned_identity" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "${var.name}-uai"

  tags = var.tags
}

#
# Public IP
#

resource "azurerm_public_ip" "main" {
  name                = "${var.name}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

#
# Application Gateway
#

resource "azurerm_application_gateway" "main" {
  name                = "${var.name}-appgw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  enable_http2        = true
  zones               = var.zones

  tags = local.merged_tags

  sku {
    name     = local.sku_name
    tier     = local.sku_tier
    capacity = var.capacity.min
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  gateway_ip_configuration {
    name      = "${var.name}-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}-public"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  frontend_ip_configuration {
    name                          = "${local.frontend_ip_configuration_name}-private"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    subnet_id                     = var.subnet_id
  }

  frontend_port {
    name = "${local.frontend_port_name}-80"
    port = 80
  }

  frontend_port {
    name = "${local.frontend_port_name}-443"
    port = 443
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/ping/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}-private"
    frontend_port_name             = "${local.frontend_port_name}-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = var.ssl_policy_name
  }

  waf_configuration {
    enabled          = var.waf_enabled
    firewall_mode    = var.waf_mode
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"
  }

  // Ignore most changes as they should be managed by AKS ingress controller
  lifecycle {
    ignore_changes = [
      "backend_address_pool",
      "backend_http_settings",
      "frontend_port",
      "http_listener",
      "probe",
      "request_routing_rule",
      tags["managed-by-k8s-ingress"],
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.name}-appgw-log-analytics"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "ApplicationGatewayAccessLog"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "ApplicationGatewayPerformanceLog"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "ApplicationGatewayFirewallLog"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}