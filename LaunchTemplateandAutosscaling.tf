#------------------- Pulling database information from ssm ---------------------------------------
data "aws_ssm_parameter" "dbusername" {
  name = "dbusername"
}


data "aws_ssm_parameter" "dbendpoint" {
  name = "dbendpoint"
}

data "aws_ssm_parameter" "dbpassword" {
  name = "dbpassword"
}

data "aws_ssm_parameter" "dbname" {
  name = "dbname"
}




#-------CreatingLaunch Template
resource "aws_launch_template" "CliXXLT" {
  name          = "ClixxLaunchTemplate"
  image_id      = "ami-0b245cc5f82576748"
  instance_type = "t2.micro"
  key_name      = "clixxkey2"

  ebs_optimized = true

  monitoring {
    enabled = true
  }
 

  vpc_security_group_ids = [
    aws_security_group.APPLICATIONSERVER_SG.id
  ]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ClixxServer"
    }
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
  file     = aws_efs_file_system.EFS.id
  lb_dns = aws_lb.LB.dns_name
  region     = "us-east-1"
  dbname     = data.aws_ssm_parameter.dbname.value
  dbusername = data.aws_ssm_parameter.dbusername.value
  dbendpoint = data.aws_ssm_parameter.dbendpoint.value
  dbpassword = data.aws_ssm_parameter.dbpassword.value
}))
}




#------Creating Ausoscating group-----------------


resource "aws_autoscaling_group" "clixxAG" {

  name                      = "ClixxAG"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true

  # Availability Zone balanced best effort
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }

  # Launch Template
  launch_template {
    id      = aws_launch_template.CliXXLT.id
    version = "$Latest"
  }

  # Private subnets
  vpc_zone_identifier = [
    aws_subnet.Privatesubnet1.id,
    aws_subnet.Privatesubnet2.id
  ]

  # Attach Target Group
  target_group_arns = [
    aws_lb_target_group.ClixxTG.arn
  ]

  # Instance maintenance policy
  instance_maintenance_policy {
    min_healthy_percentage = 100
    max_healthy_percentage = 100
  }

  # Tags
  tag {
    key                 = "Name"
    value               = "ClixxServer"
    propagate_at_launch = false
  }
}


resource "aws_autoscaling_policy" "ClixxTargetTrackingPolicy" {

  name                   = "Target Tracking Policy"
  autoscaling_group_name = aws_autoscaling_group.clixxAG.name
  policy_type            = "TargetTrackingScaling"

  # Instance warmup: 120 seconds
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}




