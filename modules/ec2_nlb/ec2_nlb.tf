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

## NLB routing traffic to EC2 instances

resource "aws_instance" "ec2_nlb" {
  ami                         = data.aws_ami.amazonlinux.id
  availability_zone           = "${var.region}a"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.nlb_ec2_sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  user_data                   = file("./user-data.sh")
  count                       = 3
}

resource "aws_security_group" "nlb_ec2_sg" {
  name        = "nlb_ec2_sg"
  description = "Basic security group that allows inbound traffic only from the load balancer."
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "sg-ingress_rule_nlb_ec2" {
  referenced_security_group_id = aws_security_group.nlb_sg.id
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.nlb_ec2_sg.id
  from_port                    = 80
  to_port                      = 80
}

resource "aws_lb" "nlb" {
  name               = "nlb"
  load_balancer_type = "network"
  ip_address_type    = "ipv4"
  subnets            = [aws_subnet.public_subnet.id]
  security_groups    = [aws_security_group.nlb_sg.id]
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_security_group" "nlb_sg" {
  name        = "nlb-sg"
  description = "NLB security group"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "sg-ingress_rule_http_nlb" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.nlb_sg.id
  from_port         = 80
  to_port           = 80
}

resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    protocol = "HTTP"
    port = "80"
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment_private" {
  for_each         = { for i, instance in aws_instance.ec2_nlb : "instance${i}" => instance.id }
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = each.value
}
