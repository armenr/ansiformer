variable "host" {
  description = "IP of the host to provision"
  default     = []
}

variable "id_list" {
  description = "list of instance ids"
  default     = []
}

variable "instance_id" {
  description = "IP of the host to provision"
  default     = ""
}

variable "instance_identifiers" {
  description = "A list of unique instance IDs"
  default     = []
}

variable "ip_list" {
  description = "list of instance ids"
  default     = []
}

variable "playbook" {
  description = "Playbook to execute on resource"
  default     = ""
}

variable "plays_lists" {
  description = "A list of plays to run from a given playbook"
  type        = "list"
  default     = []
}

variable "private_key" {
  description = "PEM key used for provisional SSH to the host"
  default     = ""
}

variable "public_ips" {
  default = []
}

variable "target_group_vars" {
  default = []
}

variable "target_hosts_list" {
  description = "The inventory group to run plays against. This is to maintain backwards compatability with existing/conventional ansible configuration and inventory layout"
  type        = "list"
  default     = []
}

variable "total_instances" {
  default = 1
}

variable "user" {
  description = "The username to provision the instance with"
  default     = "ubuntu"
}
