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
  type        = object({ min = number, max = number })
}

variable "log_analytics_workspace_id" {
  description = "Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent."
  default     = null
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

variable "waf_mode" {
  description = "The Web Application Firewall Mode."
  default     = "Prevention"
}

variable "ssl_policy_name" {
  description = "SSL Policy name"
  default     = "AppGwSslPolicy20170401"
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}
