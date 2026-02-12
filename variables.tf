variable "location" {
  type    = string
  default = "westus3"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "test"
}

variable "vm_name" {
  type        = string
  description = "The name of the VM. It will be dynamically created using a pet name."
}

variable "ip_address" {
  type        = string
  description = "Local ip address"
}

variable "virtual_machine_size" {
  type        = string
  description = "Name of the virtual machine"
  default     = "Standard_B2s_v2"
}
