/var/lib/jenkins/workspace/terraform-ami/build.sh
AWS_ACCOUNT_ID=207880003428
AWS_DEFAULT_REGION=ap-south-1
export AWS_ACCOUNT_ID
export AWS_DEFAULT_REGION
terraform init
terraform apply -auto-approve
aws autoscaling start-instance-refresh --auto-scaling-group-name "DFSC FrontEnd ASG"
