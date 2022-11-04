#Input variables 

variable "ssm_profile" {
  description = "The  permissions for instances to use SSM"
  type        = string
  default     = "EC2SSMRole"
}


variable "sshkey" {
  description = "The key to be used from AWS"
  type        = string
  default     = "INSERT HERE"
}

variable "ipaddress" {
  description = "The first 2 octets of IP address to be used"
  type        = string
  default     = "10.124"
}

variable "az"{
  description = "The availability zone"
  type = string
  default =  "ca-central-1a"
}