// Where terraform will store the status file
terraform {
  backend "s3" {
    bucket = ""
    key    = ""
    region = "us-east-1"
  }
}