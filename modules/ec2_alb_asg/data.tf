data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-05ffe3c48a9991133"]
  }

}

data "aws_availability_zones" "available_az" {
  state = "available"
}