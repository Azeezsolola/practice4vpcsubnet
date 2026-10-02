#----------Creating EFS ---------
resource "aws_efs_file_system" "EFS" {
  creation_token = "ClixxEFS"

  tags = {
    Name = "clixxEFS"
  }
}



#--------Creating Mount Target -------------
resource "aws_efs_mount_target" "EFSMT1" {
  file_system_id = aws_efs_file_system.EFS.id
  subnet_id      = aws_subnet.Privatesubnet1.id
  security_groups = [aws_security_group.EFS_SG.id]
}


resource "aws_efs_mount_target" "EFSMT2" {
  file_system_id = aws_efs_file_system.EFS.id
  subnet_id      = aws_subnet.Privatesubnet2.id
  security_groups = [aws_security_group.EFS_SG.id]
}

