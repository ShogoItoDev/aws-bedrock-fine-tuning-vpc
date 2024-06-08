resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.system_identifier}-bedrock-fine-tuning"
  }
}

# Get Availability Zones 
data "aws_availability_zones" "available" {}

# Create Subnets in each AZ
resource "aws_subnet" "main" {
  for_each = { for zone in data.aws_availability_zones.available.names : zone => zone }

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, index(data.aws_availability_zones.available.names, each.value))
  availability_zone = each.value

  tags = {
    Name = "subnet-${var.system_identifier}-${each.value}"
  }
}