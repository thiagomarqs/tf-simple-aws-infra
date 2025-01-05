## VPC + subnets

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




## Public EC2 instance with internet and S3 access

resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.amazonlinux.id
  availability_zone           = "${var.region}a"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.public_instance_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  depends_on                  = [aws_iam_role.access_s3]
  subnet_id                   = aws_subnet.public_subnet.id
  user_data                   = file("./user-data.sh")
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

resource "aws_security_group" "public_instance_sg" {
  name        = "public-instance-sg"
  description = "Basic security group that allows SSH traffic and outbound HTTPS traffic."
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "sg-ingress_rule_ssh" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.public_instance_sg.id
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "sg-egress_rule_https" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.public_instance_sg.id
  from_port         = 443
  to_port           = 443
}

resource "aws_iam_role" "access_s3" {
  name               = "access-s3"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_policy" "access_s3_policy" {
  name = "s3-read-only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:List*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.access_s3.name
  policy_arn = aws_iam_policy.access_s3_policy.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "access-s3"
  role = aws_iam_role.access_s3.name
}

resource "aws_s3_bucket" "bucket" {
  force_destroy = true
}

data "aws_iam_policy_document" "allow_ec2" {

  statement {
    actions = ["s3:List*"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    resources = [aws_s3_bucket.bucket.arn]
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.allow_ec2.json
}