resource "aws_security_group" "bedrock_customization_job" {
  name        = "bedrock_customization_job_sg"
  description = "Security group for Bedrock customization job"
  vpc_id      = aws_vpc.main.id

  #  ingress {
  #    from_port   = 443
  #    to_port     = 443
  #    protocol    = "tcp"
  #    cidr_blocks = [aws_vpc.main.cidr_block]
  #  }

  #  egress {
  #    from_port   = 443
  #    to_port     = 443
  #    protocol    = "tcp"
  #    cidr_blocks = [aws_vpc.main.cidr_block]
  #  }

  # Allow outbound to S3.
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [var.s3_managed_prefix_id]
  }

  # Allow inbound and outbound to All, including 
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = {
    Name = "bedrock_customization_job_sg"
  }
}


# Data download failed:Failed to download data. Error downloading manifest for channel train. The communication between worker nodes and leader node is broken. Please ensure that the subnet's security group inbound and outbound connections are allowed between members of the same security group. For inter-container traffic encryption, you must allow UDP 500 and Protocol 50 between members of the same security group. For EFA-enabled instances, ensure that both inbound and outbound connections allow all traffic from the same security group. For information, see Security Group Rules in the Amazon Virtual Private Cloud User Guide. https://docs.aws.amazon.com/sagemaker/latest/dg/train-vpc.html#train-vpc-groups
