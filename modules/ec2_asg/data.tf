data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-01816d07b1128cd2d"]
  }

}

data "aws_availability_zones" "available_az" {
  state = "available"
}