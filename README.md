# 概要
Terraform の Tutorials Serverless applications をベースに、
Lambda + ApiGateway でのAPIを作成しました。
https://developer.hashicorp.com/terraform/tutorials/aws/lambda-api-gateway

# 前提
- Arm Macでのみ動作確認を行っています
- aws-cli, jqがローカルで使用できること
- AWSで以下のポリシーを付与したアカウントおよびアクセスキーを発行すること  
  （検証用なので実運用ではもう少し権限を絞った方が良い）
```
AmazonAPIGatewayAdministrator
AmazonS3FullAccess
AWSLambda_FullAccess
CloudWatchFullAccessV2
IAMFullAccess
```

# 前準備
## 環境変数の設定
### tfstate bucket用
```
touch main.tfbackend
```

以下を記載

```
bucket  = "my-bucket"      # 任意のバケット名
key     = "main.tfstate"   # 任意のtfstateのファイル名
region  = "ap-northeast-1" # AWS region
profile = "my-profile"     # 任意のaws-cliのプロファイル
```

### main.tf用
```
touch terraform.tfvars
```

以下を記載

```
access_key         = ******       # AWSのアクセスキー
secret_key         = ******       # AWSのシークレットキー
aws_profile        = "my-profile" # aws-cliのプロファイル
region             = "ap-northeast-1" # AWS region
```

## tfstate bucketの作成
```
sh bin/create_bucket_for_tfstate.sh
```

# terraform init
```
terraform init -backend-config="main.tfbackend"
```

# terraform apply
```
terraform apply
```

# APIの呼び出し
```
curl "$(terraform output -raw base_url)/hello?Name=(nameの文字列)"
```
