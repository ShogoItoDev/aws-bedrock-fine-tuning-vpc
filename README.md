# はじめに

- 本レポジトリは作成者が個人的に考案・作成したものであり、所属組織等を代表するものではありません。
- 本レポジトリは検証目的であり、利用による損害等の発生には対応致しかねます。
- 参考にした文献・Webサイトは脚注に記載しています（2024/6閲覧）

# 本レポジトリの目的
AWS Bedrockの導入において、以下を実現したいケースを想定する
- 基盤モデルをファインチューニングして利用したい。
- セキュリティ・ガバナンス上の理由から、ファインチューニングジョブをユーザー指定のVPCで起動させたい

こうしたケースを想定し、以下のアーキテクチャパターンを検討してみる
- 共通基盤となるVPCを1つ作成し、トレーニングジョブのデータ入出力先となるVPCエンドポイントを配置する。
- ファインチューニングのジョブ起動時に、このVPCを指定して起動させる。

本記事の執筆時点（2024/6）時点では公式ドキュメントの情報が不足しているため、上記アーキテクチャを実装するに際し、具体的なパラメータを検証した。


# 利用方法
1. クローンしたディレクトリに移動する

    ```bash
    cd aws-bedrock-fine-tuning-vpc
    ```

2. Terraformを初期化する

    ```bash
    terraform init
    ```

3. `main.tf` 内の `system_identifier` を一意の値に変更する（S3バケット名が一意になるように）

4. terraform applyを実行

    ```bash
    terraform apply
    ```

# ファインチューニングの利用方法（Titan Text G1 Expressの場合）

1. 本レポジトリ内の `dataset.jsonl` を、S3にアップロードしておく[^1]

2. 以下の手順で項目を指定する（画面は2024/6時点のもの）

![スクリーンショット (2149)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/d980df32-5fb5-4bbc-a3f8-d00b6834c6ab)

![スクリーンショット (2150)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/88d9522a-ad1a-4ca1-9366-25e565be62b0)

![スクリーンショット (2151)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/5d3e850c-b75f-4bf1-a1ee-df218235ffba)

![スクリーンショット (2156)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/f0e902c7-972e-48e4-92bb-2bb324a62e15)

![スクリーンショット (2152)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/cf3c93c0-f30e-4069-a8d9-1e6cd77cf0aa)

ここで、トレーニングジョブが起動するVPC・サブネット・セキュリティグループを指定する。
この時、公式ドキュメントには記載が無いが、以下2点に注意が必要
- サブネットは、利用リージョン内のすべてのAZを指定する必要がある。例としてus-east-1の場合、6AZ中2～3AZだけを指定した場合はエラーとなり、6AZ全ての指定が必要だった。
- トレーニングジョブはSagemakerと同様にEFA有効インスタンスが採用されているようである（エラーメッセージからの推測）。そのため、同一セキュリティグループ内ではAllで許可しておく[^2]

![スクリーンショット (2153)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/ace8a466-686e-41eb-8568-c8096d260e4a)
![スクリーンショット (2154)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/81adb66e-4ba3-45ea-a33f-e797a4a78ef2)

トレーニングジョブが利用するサービスロールを指定する。
![スクリーンショット (2155)](https://github.com/ShogoItoDev/aws-bedrock-fine-tuning-vpc/assets/30908643/6fefcf36-ccae-4b4f-8af7-b70a1f96c82a)

この時、VPC指定の場合は追加で許可が必要になる[^3]
検証済みのポリシーは下記（AWSアカウントID、リージョン、S3バケット名を置換する）

<details>

```
{
    "Statement": [
        {
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::<bucket-name>",
                "arn:aws:s3:::<bucket-name>/*"
            ]
        },
        {
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeVpcs",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "ec2:CreateNetworkInterface"
            ],
            "Condition": {
                "ArnEquals": {
                    "aws:RequestTag/BedrockModelCustomizationJobArn": [
                        "arn:aws:bedrock:<region>:<Account ID>:model-customization-job/*"
                    ]
                },
                "StringEquals": {
                    "aws:RequestTag/BedrockManaged": [
                        "true"
                    ]
                }
            },
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ec2:<region>:<Account ID>:network-interface/*"
            ]
        },
        {
            "Action": [
                "ec2:CreateNetworkInterface"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ec2:<region>:<Account ID>:subnet/*",
                "arn:aws:ec2:<region>:<Account ID>:security-group/*"
            ]
        },
        {
            "Action": [
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteNetworkInterfacePermission"
            ],
            "Condition": {
                "ArnEquals": {
                    "ec2:ResourceTag/BedrockModelCustomizationJobArn": [
                        "arn:aws:bedrock:<region>:<Account ID>:model-customization-job/*"
                    ],
                    "ec2:Subnet": [
                        "arn:aws:ec2:<region>:<Account ID>:subnet/*"
                    ]
                },
                "StringEquals": {
                    "ec2:ResourceTag/BedrockManaged": "true"
                }
            },
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "ec2:CreateTags"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "BedrockManaged",
                        "BedrockModelCustomizationJobArn"
                    ]
                },
                "StringEquals": {
                    "ec2:CreateAction": [
                        "CreateNetworkInterface"
                    ]
                }
            },
            "Effect": "Allow",
            "Resource": "arn:aws:ec2:<region>:<Account ID>:network-interface/*"
        }
    ],
    "Version": "2012-10-17"
}
```
</details>


[^1]:入力データの形式は https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/model-customization-prepare.html を参照
[^2]:https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/efa-start-nccl-dlami.html#nccl-start-dlami-sg
[^3]:https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/vpc-model-customization.html#vpc-data-access-role
