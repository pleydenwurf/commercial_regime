# Rocky Linux 9 specific infrastructure
resource "aws_instance" "nginx_acme_server" {
  ami           = var.rocky_linux_9_ami
  instance_type = "t3.medium"
  
  vpc_security_group_ids = [aws_security_group.nginx_acme.id]
  subnet_id             = aws_subnet.private.id
  
  user_data = templatefile("${path.module}/rocky-userdata.sh", {
    artifactory_url = var.artifactory_url
  })
  
  tags = {
    Name = "nginx-acme-rocky9"
    OS   = "Rocky Linux 9"
  }
}

# Security group for Rocky Linux specific ports
resource "aws_security_group" "nginx_acme" {
  name_prefix = "nginx-acme-rocky9"
  vpc_id      = aws_vpc.build_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.build_vpc.cidr_block]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.build_vpc.cidr_block]
  }
}