#----------Creating VPC--------------
resource "aws_vpc" "VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "CLIXX_VPC"
  }
}


#-----------Creating  Public Subnets------
resource "aws_subnet" "Publicsubnet1" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Publicsubnet1"
  }
}


resource "aws_subnet" "Publicsubnet2" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true


  tags = {
    Name = "Publicsubnet2"
  }
}

#------------Creating Private Subnet---------
resource "aws_subnet" "Privatesubnet1" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Privatesubnet1"
  }
}



resource "aws_subnet" "Privatesubnet2" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Privatesubnet2"
  }
}


#--------------Creating Public subnet Route Tables--------
resource "aws_route_table" "PublicubnetRT" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "PublicsubnetRT"
  }
}


#-------------Creating Private subnet Route Table ----------
resource "aws_route_table" "PrivatesubnetRT" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "PrivatesubnetRT"
  }
}


#---------------Create Internet Gateway ---------
resource "aws_internet_gateway" "Internetgateway" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "ClixxIGW"
  }

  depends_on = [ aws_subnet.Publicsubnet1 ]
}

#--------------Create Elastic IP ---------
resource "aws_eip" "clixx_eip" {
  domain = "vpc"

  tags = {
    Name = "ClixxEIP"
  }
}


#------------Create NAT Gateway ------------
resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.clixx_eip.id
  subnet_id     = aws_subnet.Publicsubnet1.id

  tags = {
    Name = "CliXXNATGW"
  }

  depends_on = [aws_internet_gateway.Internetgateway]
}


#---------Adding Internet Gateway to the Route Table -------
resource "aws_route" "InternetRoute" {
  route_table_id         = aws_route_table.PublicubnetRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Internetgateway.id
  depends_on = [ aws_route_table.PublicubnetRT ]
}


#---------Adding NAT Gateway to Route Table ------
resource "aws_route" "InternetRoute1" {
  route_table_id         = aws_route_table.PrivatesubnetRT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.NAT.id
  depends_on = [ aws_route_table.PrivatesubnetRT ]
}


#--------Attaching Public Route table to Public Subnet --------
resource "aws_route_table_association" "Publicassociation" {
  for_each = {
    subnet1 = aws_subnet.Publicsubnet1.id
    subnet2 = aws_subnet.Publicsubnet2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.PublicubnetRT.id
}

#-------Attaching private RT to Private subnet -------
resource "aws_route_table_association" "Privateassociation" {
  for_each = {
    subnet1 = aws_subnet.Privatesubnet1.id
    subnet2 = aws_subnet.Privatesubnet2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.PrivatesubnetRT.id
}

#--------Creating security groups for load Balancer----------------
resource "aws_security_group" "LOADBALANCERSG" {
  name        = var.LOADBALANCERSG
  description = "Allow http from everywhere"
  vpc_id      = aws_vpc.VPC.id

  tags = {
    Name = var.LOADBALANCERSG
  }
}


#----Inbound rule for laod balancer sg------------

resource "aws_vpc_security_group_ingress_rule" "LB" {
  security_group_id = aws_security_group.LOADBALANCERSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

#------Outbound rule for LB SG-------------------------------

resource "aws_vpc_security_group_egress_rule" "LOADBALANCER_SG_PORT_OUTPUT" {
  security_group_id = aws_security_group.LOADBALANCERSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#-------------Creating Security group for Bastion Sevrer ---------
resource "aws_security_group" "BASTIONSG" {
  name        = var.BASTIONSERVER_SG
  description = "Allow http and ssh from everywhere"
  vpc_id      = aws_vpc.VPC.id

  tags = {
    Name = var.BASTIONSERVER_SG
  }
}

#------Inbound Rule for Bastion Server SG------------------------
resource "aws_vpc_security_group_ingress_rule" "LBRULE1" {
  security_group_id = aws_security_group.BASTIONSG.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}


resource "aws_vpc_security_group_ingress_rule" "LBRULE2" {
  security_group_id = aws_security_group.BASTIONSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
#------Outbound rule for Bastion Server SG----------------
resource "aws_vpc_security_group_egress_rule" "BASTIONSERVER_SG_PORT_OUTPUT" {
  security_group_id = aws_security_group.BASTIONSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#----------Creating Security Group for Application server --------
resource "aws_security_group" "APPLICATIONSERVER_SG" {
  name        = var.APPLICATIONSERVER_SG
  description = "Allow ssh and http from LB"
  vpc_id      = aws_vpc.VPC.id

  tags = {
    Name = var.APPLICATIONSERVER_SG
  }
}

#-----------Inbound Rule for Applcaiction Server ----------------
resource "aws_vpc_security_group_ingress_rule" "APPSERVERRULE1" {
  security_group_id = aws_security_group.APPLICATIONSERVER_SG.id

  referenced_security_group_id = aws_security_group.BASTIONSG.id

  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}


resource "aws_vpc_security_group_ingress_rule" "APPSERVERRULE2" {
  security_group_id = aws_security_group.APPLICATIONSERVER_SG.id

  referenced_security_group_id = aws_security_group.LOADBALANCERSG.id

  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

#-----------Outbound Rule for Applcation server ----------
resource "aws_vpc_security_group_egress_rule" "APPSERVER_SG_PORT_OUTPUT" {
  security_group_id = aws_security_group.APPLICATIONSERVER_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#--------Creating EFS sG--------------------------
resource "aws_security_group" "EFS_SG" {
  name        = var.EFSSG
  description = "Allow ssh and http from LB"
  vpc_id      = aws_vpc.VPC.id

  tags = {
    Name = var.EFSSG
  }
}

#-----------Ibound rule EFS SG-----------------------------
resource "aws_vpc_security_group_ingress_rule" "EFSRULE1" {
  security_group_id = aws_security_group.EFS_SG.id

  referenced_security_group_id = aws_security_group.APPLICATIONSERVER_SG.id

  from_port   = 2049
  ip_protocol = "tcp"
  to_port     = 2049
}




#-----------Outbound Rule for Applcation server ----------
resource "aws_vpc_security_group_egress_rule" "EFS_SG_PORT_OUTPUT" {
  security_group_id = aws_security_group.EFS_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



#------------------Creating DB SG-----------------------------

resource "aws_security_group" "RDS_SG" {
  name        = var.RDSSG
  description = "Allow ssh and http from LB"
  vpc_id      = aws_vpc.VPC.id

  tags = {
    Name = var.RDSSG
  }
}


#---------------Inbound RUle for RDS ------------------------
resource "aws_vpc_security_group_ingress_rule" "RDSRULE1" {
  security_group_id = aws_security_group.RDS_SG.id

  referenced_security_group_id = aws_security_group.APPLICATIONSERVER_SG.id

  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}

#-----------Outbound Rule for DB Sg ----------
resource "aws_vpc_security_group_egress_rule" "RDS_SG_PORT_OUTPUT" {
  security_group_id = aws_security_group.RDS_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



#----Bastion serverr----
resource "aws_instance" "BastionServer" {
  ami           = "ami-0b245cc5f82576748"

  instance_type = "t2.micro"

  subnet_id = aws_subnet.Publicsubnet1.id

  vpc_security_group_ids = [
    aws_security_group.BASTIONSG.id
  ]

  key_name = "clixxkey2"

  tags = {
    Name = "BastionServer"
  }
}