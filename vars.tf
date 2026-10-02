variable "AWS_REGION" {}

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "LOADBALANCERSG" {
    default = "LOADBALANCERSG"
}

variable "BASTIONSERVER_SG" {
    default = "BASTIONSG"
}

variable "APPLICATIONSERVER_SG" {
    default = "APPLICATIONSERVERSG" 
}

variable "EFSSG" {
    default = "EFSSG"
}

variable "RDSSG" {
  default = "RDSSG"
}

# #-----TO be passed in at run time like this:
# #terraform apply -var="db_password=YourPassword"
# variable "dbpassword" {
#   type      = string
#   sensitive = true
# }



# variable "dbusername" {
#   type      = string
#   sensitive = true
# }

# variable "dbname" {
#   type      = string
#   sensitive = true
# }