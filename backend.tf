terraform {
  backend "s3" {
    bucket         = "azeezterraformstatefilesbucket" 
    key            = "terraform.tfstate"            
    region         = "us-east-1"                     
    dynamodb_table = "terraformstatetable"              
    encrypt        = true 

  }
  
}

