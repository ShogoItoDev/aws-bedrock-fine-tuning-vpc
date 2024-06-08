resource "aws_vpc_endpoint" "s3" {

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_availability_zones.available.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.main.id]
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rtb-${var.system_identifier}"
  }
}

resource "aws_route_table_association" "subnet_assoc" {
  for_each = { for subnet in aws_subnet.main : subnet.id => subnet }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}

#resource "aws_vpc_endpoint" "ec2" {
#  vpc_id             = aws_vpc.main.id
#  service_name       = "com.amazonaws.${data.aws_availability_zones.available.id}.ec2"
#  vpc_endpoint_type  = "Interface"
#  security_group_ids = [aws_security_group.bedrock_customization_job.id]
#  subnet_ids         = [for subnet in aws_subnet.main : subnet.id]
#}