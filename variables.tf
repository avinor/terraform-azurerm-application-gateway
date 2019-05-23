variable "name" {
  description = "Name of the spoke virtual network."
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "sku_name" {
  description = "The name of the SKU to use for this Application Gateway."
}

variable "sku_tier" {
  description = "The Tier of the SKU to use for this Application Gateway."
}

variable "capacity" {
  description = "The Capacity of the SKU to use for this Application Gateway."
}

variable "subnet_id" {
  description = "Id of the subnet to deploy Application Gateway."
}

variable "waf_enabled" {
  description = "Set to true to enable WAF on Application Gateway."
  type = bool
  default = true
}

variable "waf_mode" {
  description = "The Web Application Firewall Mode."
  default = "Prevention"
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}
