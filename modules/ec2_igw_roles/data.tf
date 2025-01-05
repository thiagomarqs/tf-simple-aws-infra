data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-01816d07b1128cd2d"]
  }

}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}