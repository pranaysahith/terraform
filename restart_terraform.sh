#!/bin/bash
#########################################################################
# start_terraform.sh                                                    #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#########################################################################
set +x
terraform destroy -auto-approve
date
terraform init
terraform validate
terraform plan
terraform apply -auto-approve | tee terraform_apply.txt
date
