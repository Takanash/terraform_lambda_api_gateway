# 概要
Terraform の Tutorials Serverless applications をベースに、
Lambda + ApiGateway でのAPIを作成しました。
https://developer.hashicorp.com/terraform/tutorials/aws/lambda-api-gateway

# 前提
- Arm Macでのみ動作確認を行っています
- aws-cli, jqがローカルで使用できること

# 前準備
## 環境変数の設定
### tfstate bucket用
```
touch main.tfbackend
```

以下を記載

```
bucket  = "my-bucket"      # tfstate保存用バケットの名前
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
lambda_bucket_name = "my-bucket2" # Lambda関数アップロード用バケットの名前 
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
