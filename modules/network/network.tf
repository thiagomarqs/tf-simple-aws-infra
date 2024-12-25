resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Basic security group that allows inbound SSH traffic and outbound HTTPS traffic."
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "sg-ingress_rule_ssh" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg.id
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "sg-egress_rule_https" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg.id
  from_port         = 443
  to_port           = 443
}