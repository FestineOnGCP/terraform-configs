# terraform {
#     backend "s3" {
#         bucket = "festine-tf-985729960198-bucket"
#         key = "dev/terraform.tfstate"
#         region = "eu-north-1"
#         dynamodb_table = "tfstate-lock"
#     }
# }

terraform {
    backend "local" {
        path = "/mnt/d/projects/devops/terraform/terraform.tfstate"
    }
}