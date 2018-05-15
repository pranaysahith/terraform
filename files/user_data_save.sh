#cloud-config
echo "##################################################################################"
echo "##### EJ's user_data.sh ##########################################################"
echo "##################################################################################"
#package_update: true
#package_upgrade: true
#packages:
sudo yum upgrade python-pip jq bc git httpd6 php56-mysqlnd httpd
  echo "##################################################################################"
  echo "##### copy keys ##################################################################"
  echo "##################################################################################"
  #retry() {
  #  for i in {1..15}; do
  #    eval $@ && return_status=$? && break || return_status=$? && sleep 30;
  #  done
  #  return $${return_status}
  #}
  sudo cp /home/ec2-user/.ssh/id_rsa          /root/.ssh/id_rsa
  sudo cp /home/ec2-user/.ssh/id_rsa.pub      /root/.ssh/id_rsa.pub
  sudo cp /home/ec2-user/.ssh/ej_key_pair.pem /root/.ssh/ej_key_pair.pem
  sudo chmod -v 400 /root/.ssh/*
  echo "##################################################################################"
  echo "##### Setting Host Details #######################################################"
  echo "##################################################################################"
  sudo mkdir /etc/chef
  sudo sed -i "s/localhost.localdomain/apache/g" /etc/sysconfig/network
  sudo echo "$(curl 'http://169.254.169.254/latest/meta-data/public-ipv4') apache" > /etc/hosts
  sudo hostname apache
  #### setup redhat ####
  sudo chmod 600 /ec2-user/.ssh/ej_key_pair.pem
  sudo touch     /ec2-user/ssa.pem
  sudo chmod 777 /ec2-user/ssa.pem
  sudo touch     /etc/chef/ssa.pem
  sudo chmod 777 /etc/chef/ssa.pem
  echo "##################################################################################"
  echo "#### getting ssa.pem #############################################################"
  echo "##################################################################################"
  sudo scp -o "StrictHostKeyChecking no" -i ~/.ssh/ej_key_pair.pem ec2-user@chefserver.erich.com:/home/ec2-user/.chef/ssa.pem /etc/chef
  sudo chmod -v 400 /etc/chef/*
  ls -latr /etc/chef
  echo "##################################################################################"
  echo "#### sudo rm /var/lib/rpm/.rpm.lock ##############################################"
  echo "##################################################################################"
  sudo rm /var/lib/rpm/.rpm.lock
  echo "##################################################################################"
  echo "#### sudo su #####################################################################"
  echo "##################################################################################"
  sudo su
  echo "##################################################################################"
  echo "#### whoami ######################################################################"
  echo "##################################################################################"
  whoami
  echo "##################################################################################"
  echo "#### curl -L https://www.opscode.com/chef/install.sh | bash ######################"
  echo "##################################################################################"
  sudo curl -L https://www.opscode.com/chef/install.sh | bash
  echo "##################################################################################"
  echo "##### config chef client #########################################################"
  echo "##################################################################################"
  sudo touch /etc/chef/client.rb
  sudo chmod -R 777 /etc/chef/
  sudo echo "log_level        :info" >> /etc/chef/client.rb
  sudo echo "log_location     STDOUT" >> /etc/chef/client.rb
  sudo echo "chef_server_url  \"https://chefserver.erich.com/organizations/ssa\"" >> /etc/chef/client.rb
  sudo echo "validation_client_name \"ssa-validator\""  >> /etc/chef/client.rb
  sudo echo "ssl_verify_mode :verify_none " >> /etc/chef/client.rb
  echo "##################################################################################"
  echo "##### #### run chef client #######################################################"
  echo "##################################################################################"
  sudo chef-client -S https://chefserver.erich.com/organizations/ssa -K /etc/chef/ssa.pem
  sudo service httpd start
  sudo chkconfig httpd on

#runcmd:
#- [ bash, -c, *chef_bootstrap ]

#output: { all: '| tee -a /var/log/cloud-init-output.log' }
