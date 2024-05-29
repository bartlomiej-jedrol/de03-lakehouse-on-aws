output "bronze_folder_uri" {
  value = "s3://${aws_s3_bucket.lakehouse_bucket.bucket}/${aws_s3_object.bronze_folder.key}"
}

output "silver_folder_uri" {
  value = "s3://${aws_s3_bucket.lakehouse_bucket.bucket}/${aws_s3_object.silver_folder.key}"
}

output "gold_folder_uri" {
  value = "s3://${aws_s3_bucket.lakehouse_bucket.bucket}/${aws_s3_object.gold_folder.key}"
}
