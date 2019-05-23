provider "azurerm" {}

terraform {
  backend "azurerm" {}
}

data "terraform_remote_state" "setup" {
  backend = "azurerm"

  config {
    storage_account_name = "terraform${var.environment}sa"
    container_name       = "state"
    key                  = "global/setup/terraform.tfstate"
  }
}

data "terraform_remote_state" "networking" {
  backend = "azurerm"

  config {
    storage_account_name = "terraform${var.environment}sa"
    container_name       = "state"
    key                  = "${var.location}/networking/terraform.tfstate"
  }
}

locals {
  backend_address_pool_name      = "${var.name}-beap"
  frontend_port_name             = "${var.name}-feport"
  frontend_ip_configuration_name = "${var.name}-feip"
  http_setting_name              = "${var.name}-be-htst"
  listener_name                  = "${var.name}-httplstn"
  request_routing_rule_name      = "${var.name}-rqrt"
}

#
# Resource group
#

resource "azurerm_resource_group" "main" {
  name     = "${var.name}-appgw-rg"
  location = "${var.location}"

  tags = "${var.tags}"
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.name}-appgw"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  #http2_enabled = true

  tags = "${var.tags}"

  sku {
    name     = "${var.sku_name}"
    tier     = "${var.sku_tier}"
    capacity = "${var.capacity}"
  }

  waf_configuration {
    enabled = true
    firewall_mode = "${var.waf_mode}"
    rule_set_type = "OWASP"
    rule_set_version = "3.0"
  }

  gateway_ip_configuration {
    name      = "${var.name}-gateway-ip-configuration"
    subnet_id = "${data.terraform_remote_state.networking.subnets[var.subnet]}"
  }

  frontend_port {
    name = "${local.frontend_port_name}-80"
    port = 80
  }

  frontend_port {
    name = "${local.frontend_port_name}-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    subnet_id = "${data.terraform_remote_state.networking.subnets[var.subnet]}"
    private_ip_address_allocation = "Dynamic"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    path         = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "${local.listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "appgw-log-analytics"
  target_resource_id         = "${azurerm_application_gateway.main.id}"
  log_analytics_workspace_id = "${data.terraform_remote_state.setup.log_resource_id}"

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