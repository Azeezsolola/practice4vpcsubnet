#---------Creating Target group-----------------
resource "aws_lb_target_group" "ClixxTG" {
  name        = "ClixxTG"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.VPC.id
  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
    port     = "80"
  }

}



#------------Creating Load Balancer -------------
resource "aws_lb" "LB" {
  name               = "CLixxLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.LOADBALANCERSG.id]
  subnets            = [aws_subnet.Publicsubnet1.id,aws_subnet.Publicsubnet2.id]
  depends_on = [ aws_subnet.Publicsubnet1,aws_subnet.Publicsubnet2]
  enable_deletion_protection = false

  tags = {
    Name = "ClixxLB"
  }
}



#----------Load Balancer Listener -------------------------------------------------
resource "aws_lb_listener" "HTTP" {
  load_balancer_arn = aws_lb.LB.arn
  port              = 80
  protocol          = "HTTP"
    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ClixxTG.arn
  }
}