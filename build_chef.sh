#!/bin/bash
#########################################################################
# spawnservers.sh                                                       #
#                                                                       #
# Sets up a Chef Environment                                            #
#    Server 1 t2.small Amazon Linux (RedHat) ami-f973ab84               #
#    Server 2 t2.micro Amazon Linux (RedHat) ami-f973ab84               #
#                                                                       #
# Set the small to be Chef Server and Workstation                       #
#    www.chefconsole.erich.com                                          #
#                                                                       #
# Set the micro server to be bootstraped to chefconsole and setup       #
#    www.chefnode.erich.com                                             #
#                                                                       #
#    Apply Jenkins aMAKE_CHEF_1.0.0.2                                   #
#                                                                       # 
#       Base Infrastructure Receipe  "ejs"                              #
#       Apache WebServer and WebPage "apache"                           #
#       (knife cookbook upload ejs)                                     #
#       (sudo chef-client)                                              #
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

echo "##################################################################"
echo "# Building on live AWS EC2 servers ###############################"
echo "##################################################################"
echo " show output"
cat workdata.txt

cat /vol1/spawnservers/workdata.txt | grep "InstanceType" | cut -f 2 -d "."  | awk '{print $1}' > Part1
cat /vol1/spawnservers/workdata.txt | grep "PublicIpAddress" | grep -o '\d\+.\d\+.\d\+.\d\+' > Part2
cat /vol1/spawnservers/workdata.txt | grep "InstanceId" | grep -o 'i-\w\+' > Partb

paste Part1 Part2 Partb | awk '{print $1,$2,$3}' > Part3 
mv Part3 Fixme
awk 'length($0)>7' Fixme > Part3
#echo "$cat Part3"
#cat Part3

#cat Part3 | while read -r line
while read -r line 
do	
	#echo "Inside loop"
	NAME=$(echo ${line} | awk '{print $1}' )
	VALUE=$(echo ${line} | awk '{print $2}' )
	InstanceId=$(echo ${line} | awk '{print $3}' )
        if [[ ${NAME} == "small" ]]; then
	#echo " "
        #echo $NAME
	#Do something
		ChefServIP="${VALUE}"
       	echo "ChefServIP: $ChefServIP"
		echo "ChefServIP=${VALUE}" > chefmaster.def
		echo "ChefServName=chefmaster" >> chefmaster.def
		echo "ChefServFQDN=chefmaster.erich.com" >> chefmaster.def
        echo "*************************************************************"
        echo "aws ec2 create-tags --resources $InstanceId  --tags 'Key="Name",Value=ChefMaster'"
        aws ec2 create-tags --resources $InstanceId  --tags 'Key="Name",Value=ChefMaster'
        echo "*************************************************************"
	fi
done < Part3

echo " "

if [ -z $ChefServIP ]
  then 
    echo "problem the ChefServIP is not found"
	exit 1
fi
#
echo "##################################################################" 
echo "# Check the ChefMaster server is up before proceeding ############" 
echo "##################################################################"  
echo ""Checking if ChefMaster is up""
until ssh -o 'StrictHostKeyChecking=no' -i $mykey ec2-user@$ChefServIP "ls"
 do
   sleep 10
   echo "Try again"
done
echo "##################################################################"  
echo "# ChefMaster server online and now proceeding ####################"  
echo "# Calling Jenkins aMAKE_CHEF_1.0.0.2 via curl now ################"
echo "##################################################################" 
curl -u 'ej:x'  http://localhost:8080/job/CHEF/job/aMAKE_CHEF_1.0.0.2/build?token=EJ_WANTS_IT
#
#
echo "##################################################################" 
echo "# Update DNS with Route 53 #######################################" 
echo "##################################################################"  
cd ../route53
echo "sh update_route53_dns.sh chefconsole.erich.com $ChefSerIP"
sh update_route53_dns.sh chefconsole.erich.com $ChefServIP
cd ../spawnservers
echo "dns for $ChefServIP on ChefServer is Finished" 
echo " "
#
#
num=0
cat Part3 | while read line
 do
    #num=$((num+1))
    NAME=$(echo ${line} | awk '{print $1}' )
    VALUE=$(echo ${line} | awk '{print $2}' )
    InstanceId=$(echo ${line} | awk '{print $3}' )
    #
    if [[ ${NAME} == "micro" ]]; then
	num=$((num+1))
	    echo "-------------------------------------------------------------------------------------------"
    	echo "--- Adding a node -------------------------------------------------------------------------"
    	echo "-------------------------------------------------------------------------------------------" 
        #Create a new file with a number in the filename
		echo "num is $num"
		NodeIP="${VALUE}"
		echo "NodeIP=${VALUE}" > node$num.prop

		if [[ $num -lt 10 ]]; then
          #echo "Setting lower Number:$num"
		  echo "NodeName=chefnode0$num" >> node$num.prop
		  echo "NodeFQDN=chefnode0$num.erich.com" >> node$num.prop
		  NodeName="chefnode0$num"
		  NodeFQDN="chefnode0$num.erich.com"
		else 
          echo "Setting higher Number:$num"
		  echo "NodeName=chefnode$num" >> node$num.prop
		  echo "NodeFQDN=chefnode$num.erich.com" >> node$num.prop
          NodeName="chefnode$num"
          NodeFQDN="chefnode$num.erich.com"		
        fi

    	echo chefmaster.def >> node$num.prop 
    	echo "*************************************************************"
	echo "aws ec2 create-tags --resources $InstanceId  --tags 'Key="Name",Value=$NodeName'"
	aws ec2 create-tags --resources $InstanceId  --tags "Key=\"Name\",Value=$NodeName"
    echo "*************************************************************"
	cd ../route53
	echo "sh update_route53_dns.sh $NodeFQDN $NodeIP" 	
   	sh update_route53_dns.sh $NodeFQDN $NodeIP 
	cd ../spawnservers   
 	echo "*************************************************************"
	echo "#cat node$num.prop"
	cat node$num.prop
    echo "DNS entry $NodeFQDN created "
	echo "##################################################################"
    echo "# Done with DNS ##################################################"
	echo "##################################################################"
	fi
done

echo "cleaning up work files"
set -x
rm Part*
rm node*.prop
#rm zentry.txt
rm Fixme
rm rawdata.txt
rm term*.txt
rm chefmaster.def
set +x
echo "##################################################################"
echo "# end of job #####################################################"
echo "##################################################################"

