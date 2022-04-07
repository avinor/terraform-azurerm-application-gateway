variable "name" {
  description = "Name of the spoke virtual network."
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "subnet_id" {
  description = "Id of the subnet to deploy Application Gateway."
}

variable "private_ip_address" {
  description = "The Private IP Address to use for the Application Gateway."
}

variable "capacity" {
  description = "Min and max capacity for auto scaling"
  type = object({
    min = number
    max = number
  })
  default = null
}

variable "diagnostics" {
  description = "Diagnostic settings for those resources that support it. See README.md for details on configuration."
  type = object({
    destination   = string
    eventhub_name = string
    logs          = list(string)
    metrics       = list(string)
  })
  default = null
}

variable "zones" {
  description = "A collection of availability zones to spread the Application Gateway over."
  type        = list(string)
  default     = null
}

variable "waf_enabled" {
  description = "Set to true to enable WAF on Application Gateway."
  type        = bool
  default     = true
}

variable "waf_configuration" {
  description = "Configuration block for WAF."
  type = object({
    firewall_mode            = string
    rule_set_type            = string
    rule_set_version         = string
    file_upload_limit_mb     = number
    max_request_body_size_kb = number
  })
  default = null
}

variable "managed_policies_override" {
  description = "List of managed firewall policies overrides. See https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules"
  type = list(object({
    rule_group_name = string
    disabled_rules  = list(string)
  }))
  default = []
}

variable "managed_policies_exclusions" {
  description = "List of managed firewall policies exclusions"
  type = list(object({
    match_variable          = string
    selector_match_operator = string
    selector                = string
  }))
  default = []
}

variable "custom_policies" {
  description = "List of custom firewall policies. See https://docs.microsoft.com/en-us/azure/application-gateway/custom-waf-rules-overview."
  type = list(object({
    name      = string
    rule_type = string
    action    = string
    match_conditions = list(object({
      match_variables = list(object({
        match_variable = string
        selector       = string
      })),
      operator           = string
      negation_condition = bool
      match_values       = list(string)
    }))
  }))
  default = []
}

variable "rewrite_rule_sets" {
  description = "List of rewrite rules. See https://docs.microsoft.com/en-us/azure/application-gateway/rewrite-http-headers-url"
  type = list(object({
    name = string
    rewrite_rule = list(object({
      rule_name     = string
      rule_sequence = number
      condition = list(object({
        ignore_case = bool
        negate      = bool
        pattern     = string
        variable    = string
      }))
      request_header_configuration = list(object({
        header_name  = string
        header_value = string
      }))
      response_header_configuration = list(object({
        header_name  = string
        header_value = string
      }))
      url = list(object({
        path         = string
        query_string = string
        reroute      = bool
      }))
    }))
  }))
  default = []
}

variable "ssl_policy_name" {
  description = "SSL Policy name"
  default     = "AppGwSslPolicy20170401"
}

variable "custom_error" {
  description = "List of custom error configurations, only support status code `HttpStatus403` and `HttpStatus502`."
  type = list(object({
    status_code    = string
    error_page_url = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}
