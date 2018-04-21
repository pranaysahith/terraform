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
if [ $? -eq 1 ]
then
   echo "blah blah blah"
fi
terraform validay
if [ $? -eq 1 ]
then
   echo "blah blah blah"
fi
terraform plan
if [ $? -eq 1 ]
then
   echo "blah blah blah"
fi
terraform apply -auto-approve
if [ $? -eq 1 ]
then
   echo "blah blah blah"
fi
