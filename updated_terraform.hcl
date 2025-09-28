# Step-CA server
resource "aws_instance" "step_ca_server" {
  ami           = var.rocky_linux_9_ami
  instance_type = "t3.medium"
  
  vpc_security_group_ids = [aws_security_group.step_ca.id]
  subnet_id             = aws_subnet.private.id
  
  user_data = templatefile("${path.module}/step-ca-userdata.sh", {
    artifactory_url = var.artifactory_url
  })
  
  tags = {
    Name = "step-ca-server"
    Role = "ACME-CA"
  }
}

# nginx-acme proxy servers
resource "aws_instance" "nginx_acme_proxy" {
  count         = var.proxy_count
  ami           = var.rocky_linux_9_ami
  instance_type = "t3.small"
  
  vpc_security_group_ids = [aws_security_group.nginx_acme.id]
  subnet_id             = aws_subnet.private.id
  
  user_data = templatefile("${path.module}/nginx-acme-userdata.sh", {
    artifactory_url = var.artifactory_url
    step_ca_url     = "https://${aws_instance.step_ca_server.private_ip}:9000"
  })
  
  tags = {
    Name = "nginx-acme-proxy-${count.index + 1}"
    Role = "ACME-Proxy"
  }
}

resource "aws_security_group" "step_ca" {
  name_prefix = "step-ca"
  vpc_id      = aws_vpc.build_vpc.id
  
  # ACME server port
  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_acme.id]
  }
  
  # CA management port
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.build_vpc.cidr_block]
  }
}

resource "aws_security_group" "nginx_acme" {
  name_prefix = "nginx-acme"
  vpc_id      = aws_vpc.build_vpc.id
  
  # HTTP for ACME challenges
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.build_vpc.cidr_block]
  }
  
  # HTTPS for proxied services
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.build_vpc.cidr_block]
  }
}