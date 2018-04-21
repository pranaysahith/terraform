#!/bin/bash
#########################################################################
# tag_terminated.sh                                                     #
#                                                                       #
# Will clean up Terminated EC2 instances                                #
#                                                                       #
#                                                                       #
#                                                                       #
#########################################################################
echo "##################################################################"
echo "# spawnservers.sh ################################################"
echo "##################################################################"
#
echo "##################################################################"
echo "# cleaning up work files #########################################"
echo "##################################################################"
set -x
sudo rm -fv workdata.txt
set +x
echo "##################################################################"
echo "# setting up environment #########################################"
echo "##################################################################"
PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
echo $PATH
pwd
set +x
#
mykey="~/.ssh/ej_key_pair.pem"
#
export AWS_DEFAULT_OUTPUT="table"
echo "get all the server details from aws"
sudo aws ec2 describe-instances | grep -A 7 "InstanceId" > rawdata.txt
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
#
#
echo " clean up if there are any orphan records"
# if "PublicDnsName is blank, assume orphaned and junk
grep 'PublicDnsName\s*|\s*ec' rawdata.txt  -A 1 -B 7 | uniq  > workdata.txt
grep 'PublicDnsName\s*|\s*|' rawdata.txt  -A 3 -B 5 | uniq  > termdata.txt
#
echo "##################################################################"
echo "# Find servers shutdown and mark as terminated ###################"
echo "##################################################################"
cat /vol1/spawnservers/termdata.txt | grep "InstanceType" | cut -f 2 -d "."  | awk '{print $1}' > Part1
cat /vol1/spawnservers/termdata.txt | grep "InstanceId" | grep -o 'i-\w\+' > Partb
paste Part1 Partb | awk '{print $1,$2}' > Partt
#
# reading Partt and process node details
while read -r line
do
    InstanceId=$(echo ${line} | awk '{print $2}' )
    echo "*************************************************************"
    set -x
	aws ec2 create-tags --resources $InstanceId  --tags "Key=\"Name\",Value=zterminated"
    set +x
	echo "*************************************************************"
done < Partt
