#!/bin/bash
# 予めローカルにaws-cliとjqのインストールが必要

# terraform.tfvars から環境変数を読み込む
tfvars=`cat terraform.tfvars | tr -d ' ' | tr -d '"'`
# main.tfbackend からtfstateを保存するバケットの変数を読み込む
tfbackend=`cat main.tfbackend | tr -d ' ' | tr -d '"'`

# terraform.tfvars の環境変数を変数として読み込む
while read line; do
  while IFS== read f1 f2; do
    if [ -n "$f1" ] && [ -n "$f2" ]; then
      eval ${f1}=${f2}
    fi
  done
done << END
\n # terraform.tfvarsの最初の1行目が読み込まれないため改行を入れる 他にいい方法があるかも
$tfvars
$tfbackend
END

# S3のバケット一覧を読み込む
list_buckets=$(aws s3api list-buckets --profile $aws_profile) > /dev/null
bucket_names=$(echo $list_buckets | jq ".Buckets[].Name" | tr -d '"')

# 既に同名のバケットがある場合は処理終了
for bucket_name in $bucket_names
do 
  if [ $bucket_name = $bucket ]; then
    echo "バケットが既に作成されているため処理を終了します" 
    exit 0
  fi
done

# バケットの作成
aws s3api create-bucket \
  --profile $aws_profile \
  --region $region \
  --create-bucket-configuration LocationConstraint=$region \
  --bucket $bucket \
   > /dev/null

aws s3api put-bucket-versioning \
  --profile $aws_profile \
  --bucket $bucket \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --profile $aws_profile \
  --bucket $bucket \
  --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

aws s3api put-public-access-block \
  --profile $aws_profile \
  --bucket $bucket \
  --public-access-block-configuration '{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}'

echo "create_bucket: ${bucket}"
