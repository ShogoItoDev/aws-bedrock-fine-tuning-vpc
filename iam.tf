data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_iam_role" "bedrock_model_customization" {
  name = "bedrock_model_customization_role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:model-customization-job/*"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "bedrock_model_customization_policy" {
  name = "bedrock_model_customization_policy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
        ],
        Condition = {
          StringEquals = {
            "aws:RequestTag/BedrockManaged" : ["true"]
          },
          ArnEquals = {
            "aws:RequestTag/BedrockModelCustomizationJobArn" : ["arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:model-customization-job/*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*",
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission"
        ]
        Resource = "*",
        Condition = {
          ArnEquals = {
            "ec2:Subnet" : [
              "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*"
            ],
            "ec2:ResourceTag/BedrockModelCustomizationJobArn" : ["arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:model-customization-job/*"]
          },
          StringEquals = {
            "ec2:ResourceTag/BedrockManaged" : "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" : [
              "CreateNetworkInterface"
            ],
          },
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" : [
              "BedrockManaged",
              "BedrockModelCustomizationJobArn"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_model_customization_attachment" {
  role       = aws_iam_role.bedrock_model_customization.name
  policy_arn = aws_iam_policy.bedrock_model_customization_policy.arn
}