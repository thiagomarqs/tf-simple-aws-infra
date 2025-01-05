resource "aws_vpc" "vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available_az.names, count.index)
  count                   = 3
}

resource "aws_launch_template" "launch_template" {
  name                   = "launch_template"
  image_id               = data.aws_ami.amazonlinux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = filebase64("./user-data.sh")
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
  for_each       = { for i, subnet in aws_subnet.public_subnet : "subnet${i}" => subnet.id }
  route_table_id = aws_route_table.rt.id
  subnet_id      = each.value
}

# instances SG
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Security group for the EC2 instances."
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_alb" {
  referenced_security_group_id = aws_security_group.alb_sg.id
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.ec2_sg.id
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_anywhere_http" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.ec2_sg.id
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_anywhere_https" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.ec2_sg.id
  from_port         = 443
  to_port           = 443
}

# TG
resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    protocol            = "HTTP"
    port                = "80"
    interval            = "20"
    timeout             = "10"
    unhealthy_threshold = "5"
    healthy_threshold   = "3"
    matcher             = "200-399"
  }
}

# ASG
resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 3
  min_size            = 3
  max_size            = 9
  vpc_zone_identifier = [for subnet in aws_subnet.public_subnet : subnet.id]
  target_group_arns   = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}

# ALB SG
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security group for the ASG"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_anywhere" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_to_ec2_sg" {
  referenced_security_group_id = aws_security_group.ec2_sg.id
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.alb_sg.id
  from_port                    = 80
  to_port                      = 80
}

# ALB
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
