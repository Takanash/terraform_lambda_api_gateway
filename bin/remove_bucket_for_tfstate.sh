BUCKET_NAME="rw-s3-app-terraform"
AWS_PROFILE="s3_app_terraform"

list_buckets=$(aws s3api list-buckets --profile $AWS_PROFILE) > /dev/null
bucket_names=$(echo $list_buckets | jq ".Buckets[].Name" | tr -d '"')

for bucket_name in $bucket_names
do 
  if [ $bucket_name = $BUCKET_NAME ]; then
    aws s3 rb --force s3://$BUCKET_NAME --profile $AWS_PROFILE
    exit 0
  fi
done

echo "バケットが存在しないため削除を行いませんでした" 
exit 0


