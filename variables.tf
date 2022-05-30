variable "cidr_block" {
  description = "This is list of object variable which holds all cidr_block values"
  type = list(object({
    cidr_block = string
    name = string
  }))  
}

variable "priv_key" {}
variable "pub_key" {}

variable "ports" {}