resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.amazonlinux.id
  availability_zone           = "${var.region}a"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  depends_on                  = [aws_iam_role.access_s3]
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
