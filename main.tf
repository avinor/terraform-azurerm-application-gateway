terraform {
  required_version = ">= 0.12.6"
  required_providers {
    azurerm = "~> 1.36.0"
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

  diag_appgw_logs = [
    "ApplicationGatewayAccessLog",
    "ApplicationGatewayPerformanceLog",
    "ApplicationGatewayFirewallLog",
  ]
  diag_appgw_metrics = [
    "AllMetrics",
  ]

  diag_resource_list = var.diagnostics != null ? split("/", var.diagnostics.destination) : []
  parsed_diag = var.diagnostics != null ? {
    log_analytics_id   = contains(local.diag_resource_list, "microsoft.operationalinsights") ? var.diagnostics.destination : null
    storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.diagnostics.destination : null
    event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.diagnostics.destination : null
    metric             = contains(var.diagnostics.metrics, "all") ? local.diag_appgw_metrics : var.diagnostics.metrics
    log                = contains(var.diagnostics.logs, "all") ? local.diag_appgw_logs : var.diagnostics.logs
    } : {
    log_analytics_id   = null
    storage_account_id = null
    event_hub_auth_id  = null
    metric             = []
    log                = []
  }
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
  name                = "${var.name}-msi"

  tags = var.tags
}

resource "azurerm_role_assignment" "self" {
  scope                = azurerm_user_assigned_identity.main.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

resource "azurerm_role_assignment" "appgw" {
  scope                = azurerm_application_gateway.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

resource "azurerm_role_assignment" "rg" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
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
    name = local.sku_name
    tier = local.sku_tier
  }

  autoscale_configuration {
    min_capacity = var.capacity.min
    max_capacity = var.capacity.max
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
    enabled                  = var.waf_enabled
    firewall_mode            = coalesce(var.waf_configuration.firewall_mode, "Prevention")
    rule_set_type            = coalesce(var.waf_configuration.rule_set_type, "OWASP")
    rule_set_version         = coalesce(var.waf_configuration.rule_set_version, "3.0")
    file_upload_limit_mb     = coalesce(var.waf_configuration.file_upload_limit_mb, 100)
    max_request_body_size_kb = coalesce(var.waf_configuration.max_request_body_size_kb, 128)
  }

  dynamic "custom_error_configuration" {
    for_each = var.custom_error
    iterator = ce
    content {
      status_code           = ce.value.status_code
      custom_error_page_url = ce.value.error_page_url
    }
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
      "url_path_map",
      "ssl_certificate",
      "redirect_configuration",
      tags["managed-by-k8s-ingress"],
    ]
  }
}

resource "azurerm_web_application_firewall_policy" "main" {
  count               = length(var.custom_policies) > 0 ? 1 : 0
  name                = format("%swafpolicy", lower(replace(var.name, "/[[:^alnum:]]/", "")))
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  dynamic "custom_rules" {
    for_each = var.custom_policies
    iterator = cp
    content {
      name      = cp.value.name
      priority  = (cp.key + 1) * 10
      rule_type = cp.value.rule_type
      action    = cp.value.action

      dynamic "match_conditions" {
        for_each = cp.value.match_conditions
        iterator = mc
        content {
          dynamic "match_variables" {
            for_each = mc.value.match_variables
            iterator = mv
            content {
              variable_name = mv.value.match_variable
              selector      = mv.value.selector
            }
          }

          operator           = mc.value.operator
          negation_condition = mc.value.negation_condition
          match_values       = mc.value.match_values
        }
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  count                          = var.diagnostics != null ? 1 : 0
  name                           = "${var.name}-appgw-diag"
  target_resource_id             = azurerm_application_gateway.main.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  dynamic "log" {
    for_each = local.parsed_diag.log
    content {
      category = log.value

      retention_policy {
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = local.parsed_diag.metric
    content {
      category = metric.value

      retention_policy {
        enabled = false
      }
    }
  }
}
