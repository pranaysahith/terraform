

resource "aws_instance" "chefserver" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.small"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  # TODO: make this instance profile have access to private chef bucket
  iam_instance_profile        = "${aws_iam_instance_profile.ssm_profile.id}"
  tags {
        Name                  = "chefserver"
        Environment           = "Test"
  }
  user_data                   = <<EOF
  #!/bin/bash
  set +x
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  yum update -y
  yum -y install jq bc git
  echo "##################### setting the hostname ####################################################################"
  sed -i "s/localhost.localdomain/chefserver/g" /etc/sysconfig/network
  myip=$(nslookup chefserver.erich.com | grep Address | tail -1 | cut -f2 -d ":")
  echo "$myip chefserver chefserver.erich.com" > /etc/hosts
  hostname chefserver
  echo "#####################  setting home to /root don't tell me it is not set #######################################"
  echo "#####################  doing now the clone #####################################################################"
  HOME=/root
  runuser -l ec2-user -c 'whoami'
  echo "User executing commands is"
  whoami
  echo "# getting rsa keys and giving them to both root and ec2-user ##############################"
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'ejs'       --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/ej_key_pair.pem
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpubkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa.pub
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpvtkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'ejs'       --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /root/.ssh/ej_key_pair.pem
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpubkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /root/.ssh/id_rsa.pub
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpvtkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /root/.ssh/id_rsa

  echo "setting protections on ec2-user/.ssh"
  chown ec2-user /home/ec2-user/.ssh/*
  chmod 600 /home/ec2-user/.ssh/ej_key_pair.pem
  chmod 600 /home/ec2-user/.ssh/id_rsa.pub
  chmod 600 /home/ec2-user/.ssh/id_rsa
  ls -lS    /home/ec2-user/.ssh/*

  echo "setting protections on root/.ssh"
  chown root /root/.ssh/*
  chmod 600 /root/.ssh/ej_key_pair.pem
  chmod 600 /root/.ssh/id_rsa.pub
  chmod 600 /root/.ssh/id_rsa
  ls -lS    /root/.ssh/*

  echo "starting Chef Installation in folder"
  pwd
  echo "creating folder .chef"
  mkdir /home/ec2-user/.chef
  mkdir /root/.chef
  echo "making testfile"
  touch /home/ec2-user/.chef/mytestfile
  touch /root/.chef/mytestfile
  echo "User executing commands is"
  whoami
  cd /tmp
  echo "#####################  doing now the clone #####################################################################"
  sudo chmod 400 ~/.ssh/*
  sudo chown -R root ~/.ssh/*
  git config --global user.name  'EJ Best'
  git config --global user.email 'ejbest@alumni.rutgers.edu'
  sudo touch ~/.ssh/config
  sudo rm    ~/.ssh/config
  echo -e "Host github.com           " > ~/.ssh/config
  echo -e " StrictHostKeyChecking no " >> ~/.ssh/config
  echo -e "                          " >> ~/.ssh/config
  sudo chmod 600 ~/.ssh/config
  git clone git@github.com:ejbest/deployments.git
  sh /tmp/deployments/ChefMaster/ChefServerInstall_RedHat.sh
EOF
}

resource "aws_instance" "chefworkstation" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.small"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.ssm_profile.id}"
  tags {
        Name                  = "chefworkstation"
        Environment           = "Test"
  }
  user_data                   = <<EOF
  #!/bin/bash
  set +x
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  echo "#######################################################################################################################################"
  yum update -y
  yum -y install jq bc git
  echo "##################### setting the hostname ####################################################################"
  sed -i "s/localhost.localdomain/chefworkstation/g" /etc/sysconfig/network
  myip=$(nslookup chefworkstation.erich.com | grep Address | tail -1 | cut -f2 -d ":")
  echo "$myip chefserver chefworkstation.erich.com" > /etc/hosts
  hostname chefworkstation
  echo "#####################  setting home to /root don't tell me it is not set #######################################"
  HOME=/root
  runuser -l ec2-user -c 'whoami'
  echo "User executing commands is"
  whoami
  sudo su ej2-user
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'ejs'       --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/ej_key_pair.pem
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpubkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa.pub
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpvtkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'ejs'       --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /root/.ssh/ej_key_pair.pem
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpubkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /root/.ssh/id_rsa.pub
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpvtkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /root/.ssh/id_rsa

  echo "setting protections on .ssh folder in ec2-user"
  cd
  sudo chown ec2-user /home/ec2-user/.ssh/*
  chmod 600 /home/ec2-user/.ssh/ej_key_pair.pem
  echo "setting protections on id_rsa"
  chmod 600 /home/ec2-user/.ssh/id_rsa
  echo "settting protetions on id_pub"
  chmod 600 /home/ec2-user/.ssh/id_pub
  echo "starting Chef Installation in folder"
  pwd
  # aws s3api get-object --bucket chef-server-test --key chefserver.pub /etc/chef/chef-validator.pem
  mkdir /home/ec2-user/.chef
  touch /home/ec2-user/.chef/mytestfile
  ls -latr /home/ec2-user/.chef
  ls -latr /home/ec2-user/.ssh
  cd /tmp
  cd /tmp
  git config --global user.name "ejbest"
  git config --global user.email "ejbest@alumni.rutgers.edu"
  git config --global push.default matching
  # curl -L https://www.chef.io/chef/install.sh | bash -s -- -v 12.12.13
  # chef-client -j <(echo "{"run_list": ["role[apache]"]}")
  # rm -rf /etc/chef/chef-validator.pem
  echo "nxec id_rsa"
  echo -e '#!/bin/bash\nexec /usr/bin/ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa $@' > /tmp/git_ssh
  echo "chmod on git_sh"
  chmod +x /tmp/git_ssh
  export GIT_SSH="/tmp/git_ssh
  echo "#####################  doing now the clone #####################################################################"
  sudo chmod 400 ~/.ssh/*
  sudo chown -R root ~/.ssh/*
  git config --global user.name  'EJ Best'
  git config --global user.email 'ejbest@alumni.rutgers.edu'
  sudo touch ~/.ssh/config
  sudo rm    ~/.ssh/config
  echo -e "Host github.com           " > ~/.ssh/config
  echo -e " StrictHostKeyChecking no " >> ~/.ssh/config
  echo -e "                          " >> ~/.ssh/config
  sudo chmod 600 ~/.ssh/config
  git clone git@github.com:ejbest/deployments.git
  echo "executing chef node install"
  sh /tmp/deployments/ChefNode/ChefNodeInstall.sh
  echo "Executing chef workstation install"
  sh /tmp/deployments/ChefMaster/ChefWorkInstall_RedHat.sh
  retry() {
    for i in {1..15}; do
      eval $@ && return_status=$? && break || return_status=$? && sleep 30;
    done
    return $${return_status}
  }
  retry /tmp/deployments/ChefNode/ChefNodeInstall.sh
  cd /tmp
  sudo yum install -y httpd6 php56-mysqlnd
  echo "doing mysql install"
  sudo yum install mysql -y
  git clone git@github.com:ejbest/ejs.git
  mysql -u sa -pinitial123 -h mysql.erich.com --database="ejs" < ~/ejs/ejs.sql
  cd /tmp
  EOF
}

resource "aws_route53_record" "chefserver" {
  zone_id                     = "ZBVO8OQHTFSNO"
  name                        = "chefserver.erich.com"
  type                        = "CNAME"
  ttl                         = "60"
  records                     = ["${aws_instance.chefserver.public_dns}"]
}

resource "aws_route53_record" "chefworkstation" {
  zone_id                     = "ZBVO8OQHTFSNO"
  name                        = "chefworkstation.erich.com"
  type                        = "CNAME"
  ttl                         = "60"
  records                     = ["${aws_instance.chefserver.public_dns}"]
}


resource "aws_instance" "windows" {
  ami                         = "${lookup(var.Amiwindows, var.region)}"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  tags {
        Name                  = "windows"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage           = 10
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t2.micro"
  name                        = "ejs"
  username                    = "sa"
  password                    = "initial123"
  parameter_group_name        = "default.mysql5.7"
  db_subnet_group_name        = "${aws_db_subnet_group.dbsubnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  skip_final_snapshot         = true
}

resource "aws_route53_record" "ejs" {
  zone_id                     = "ZBVO8OQHTFSNO"
  name                        = "mysql.erich.com"
  type                        = "CNAME"
  ttl                         = "60"
  records                     = ["${aws_db_instance.default.address}"]
}

resource "aws_db_subnet_group" "dbsubnet" {
  subnet_ids                  = ["${aws_subnet.PublicAZA.id}", "${aws_subnet.PublicAZB.id}"]
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name                        = "ssm_profile"
  role                        = "${aws_iam_role.ssm_role.name}"
}

resource "aws_iam_role" "ssm_role" {
  name                        = "ssm_role"
  path                        = "/"
  assume_role_policy          = <<EOF
{
  	  "Version": "2012-10-17",
  	  "Statement": [
      {	      "Action": "sts:AssumeRole",
        "Principal": {
         "Service": "ec2.amazonaws.com"
       },
       "Effect": "Allow",
      "Sid": ""
      }
    ]
  }
EOF
}

data "aws_iam_policy" "ReadOnlyAccess"
{
arn                           =  "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_readonly_policy_attach"{
role                          = "${aws_iam_role.ssm_role.name}"
policy_arn                    = "${data.aws_iam_policy.ReadOnlyAccess.arn}"

}
