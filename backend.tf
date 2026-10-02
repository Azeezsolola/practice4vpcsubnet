# terraform {
#   backend "s3" {
#     bucket         = "azeezterraformstatefilesbucket" 
#     key            = "terraform.tfstate"            
#     region         = "us-east-1"                     
#     dynamodb_table = "terraformstatetable"              
#     encrypt        = true 

#   }
  
# }

terraform {
  backend "s3" {
    bucket         = "azeezterraformstatefilesbucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraformstatetable"
    encrypt        = true

    assume_role = {
      role_arn = "arn:aws:iam::381549359798:role/TerraformBackendRole"
    }
  }
}