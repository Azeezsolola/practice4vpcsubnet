resource "aws_db_subnet_group" "RDSSUBNET" {
  name       = "clixx_rds_subnet"
  subnet_ids = [aws_subnet.Privatesubnet1.id, aws_subnet.Privatesubnet2.id]

  tags = {
    Name = "CLIXX_RDS_SUBNET"
  }
}




#------------------------Restoring RDS Database from snapshot------------------------------------------------------

resource "aws_db_instance" "restored_db" {
  identifier          = "wordpressdbclixx-ecs"
  snapshot_identifier = "arn:aws:rds:us-east-1:276925326643:snapshot:wordpressdbclixx-ecs"  
  instance_class      = "db.m6gd.large"        
  allocated_storage    = 20                     
  engine             = "mysql"                
  username           = data.aws_ssm_parameter.dbusername.value
  password           = data.aws_ssm_parameter.dbpassword.value         
  db_subnet_group_name = aws_db_subnet_group.RDSSUBNET.name 
  vpc_security_group_ids = [aws_security_group.RDS_SG.id] 
  skip_final_snapshot     = true
  publicly_accessible  = false
  
  tags = {
    Name = "wordpressdb"
  }
}