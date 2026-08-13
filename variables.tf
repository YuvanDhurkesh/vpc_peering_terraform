variable "primary_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "primary_vpc_reg" {
  default = "us-east-1"
}

variable "secondary_vpc_reg" {
  default = "ap-south-1"
}