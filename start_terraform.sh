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
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
