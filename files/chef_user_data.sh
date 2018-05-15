#cloud-config

package_update: true
package_upgrade: true
packages:
- python-pip
- jq
- bc
- git

chef_bootstrap:
- &chef_bootstrap |
  echo "##################################################################################"
  echo "##### copy keys ##################################################################"
  echo "##################################################################################"
  retry() {
    for i in {1..15}; do
      eval $@ && return_status=$? && break || return_status=$? && sleep 30;
    done
    return $${return_status}
  }
  cp /home/ec2-user/.ssh/id_rsa          /root/.ssh/id_rsa
  cp /home/ec2-user/.ssh/id_rsa.pub      /root/.ssh/id_rsa.pub
  cp /home/ec2-user/.ssh/ej_key_pair.pem /root/.ssh/ej_key_pair.pem
  echo "##################################################################################"
  echo "##### Setting Host Details #######################################################"
  echo "##################################################################################"
  sed -i "s/localhost.localdomain/chefserver/g" /etc/sysconfig/network
  echo "$(curl 'http://169.254.169.254/latest/meta-data/public-ipv4') chefserver" > /etc/hosts
  hostname chefserver
  echo "##################################################################################"
  echo "##### install chef ###############################################################"
  echo "##### install chef ###############################################################"
  echo "##################################################################################"
  mkdir /usr/lib/systemd
  mkdir /usr/lib/systemd/system
  wget https://packages.chef.io/files/stable/chef-server/12.17.33/el/7/chef-server-core-12.17.33-1.el7.x86_64.rpm
  rpm -ivh chef-server-core-12.17.33-1.el7.x86_64.rpm
  echo "##################################################################################"
  echo "##### chef-server-ctl reconfigure ###########################################"
  echo "##################################################################################"
  chef-server-ctl reconfigure
  chef-server-ctl reconfigure
  chef-server-ctl reconfigure
  echo "##################################################################################"
  echo "##### chef-server-ctl status ################################################"
  echo "##################################################################################"
  cp /opt/opscode/embedded/service/omnibus-ctl/spec/fixtures/pivotal.pem /etc/opscode/
  chef-server-ctl status
  echo "##################################################################################"
  echo "##### rm/mkdir /{root,home/ec2-user}/.chef #######################################"
  echo "##################################################################################"
  rm -Rf /root/.chef
  mkdir /root/.chef
  mkdir /home/ec2-user/.chef
  echo "##################################################################################"
  echo "##### chef-server-ctl user-create ej ej best ej@erich.com 666666 --filename /home/ec2-user/.chef/ej.pem"
  echo "##### chef-server-ctl org-create ssa SSA --association_user ej --filename   /home/ec2-user/.chef/ssa.pem"
  echo "##################################################################################"
  chef-server-ctl user-create ej ej best ej@erich.com 666666 --filename /home/ec2-user/.chef/ej.pem
  chef-server-ctl org-create ssa SSA --association_user ej --filename   /home/ec2-user/.chef/ssa.pem
  chown -R ec2-user: /home/ec2-user/.chef
  echo "##################################################################################"
  echo "##### chef-server-ctl install chef-manage ########################################"
  echo "##################################################################################"
  chef-server-ctl install chef-manage
  chef-server-ctl reconfigure
  opscode-manage-ctl reconfigure --accept-license
  echo "******************************************"
  echo "* Installed Chef Server: COMPLETED       *"
  echo "******************************************"

runcmd:
- [ bash, -c, *chef_bootstrap ]

output: { all: '| tee -a /var/log/cloud-init-output.log' }
