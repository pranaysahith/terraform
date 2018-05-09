
resource "aws_instance" "apache" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  # TODO: make this instance profile have access to private chef bucket
  iam_instance_profile        = "${aws_iam_instance_profile.ssm_profile.id}"

  provisioner "file" {
    source                    = "/Users/ej/.ssh/id_rsa"
    destination               = "/home/ec2-user/.ssh/id_rsa"
    connection {
      user                    = "ec2-user"
      agent                   = "false"
      type                    = "ssh"
      private_key             = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
      timeout                 = "300s"
    }
  }

  provisioner "file" {
    source                    = "/Users/ej/.ssh/ej_key_pair.pem"
    destination               = "/home/ec2-user/.ssh/ej_key_pair.pem"
    connection {
      user                    = "ec2-user"
      agent                   = "false"
      type                    = "ssh"
      private_key             = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
      timeout                 = "300s"
    }
  }

  provisioner "file" {
      source                    = "/tmp/myfile.txt"
      destination               = "/tmp/myfile.txt"
      connection {
        user                    = "ec2-user"
        agent                   = "false"
        type                    = "ssh"
        private_key             = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
        timeout                 = "300s"
      }
  }
  tags {
        Name                  = "apache"
        Environment           = "Test"
  }
  user_data                   = <<EOF
  #cloud-config
  write_files:
  - path: /tmp/test-file.txt
    owner: root:root
    permissions: '0644'
    content: |
      This is a sample text!
  #!/bin/bash
  echo "##################################################################################"
  echo "##### yum ########################################################################"
  echo "##################################################################################"
  yum update -y
  echo "##################################################################################"
  echo "##### copy keys ##################################################################"
  echo "##################################################################################"
  retry() {
    for i in {1..15}; do
      eval $@ && return_status=$? && break || return_status=$? && sleep 30;
      cp /home/ec2-user/.ssh/id_rsa      /root/.ssh/id_rsa
    done
    return $${return_status}
  }
  cp /home/ec2-user/.ssh/id_rsa          /root/.ssh/id_rsa
  cp /home/ec2-user/.ssh/id_rsa.pub      /root/.ssh/id_rsa.pub
  cp /home/ec2-user/.ssh/ej_key_pair.pem /root/.ssh/ej_key_pair.pem
  echo "##################################################################################"
  echo "##### Setting Host Details #######################################################"
  echo "##################################################################################"
  sed -i "s/localhost.localdomain/apache/g" /etc/sysconfig/network
  myip=$(nslookup apache.erich.com | grep Address | tail -1 | cut -f2 -d ":")
  echo "$myip apache apache.erich.com" > /etc/hosts
  hostname apache
  echo "##################################################################################"
  echo "##### git clone ##################################################################"
  echo "##################################################################################"
  chmod 700 /root/.ssh/*
  ls -lS    /root/.ssh/*
  echo -e "Host github.com           " > ~/.ssh/config
  echo -e " StrictHostKeyChecking no " >> ~/.ssh/config
  echo -e "                          " >> ~/.ssh/config
  sudo chmod 400 /root/.ssh/config
  cd /tmp
  echo "#####################  doing now the clone #####################################################################"
  git config --global user.name  'EJ Best'
  git config --global user.email 'ejbest@alumni.rutgers.edu'
  git clone git@github.com:ejbest/deployments.git
  echo "##################################################################################"
  echo "##### Chef Node Install ##########################################################"
  echo "##################################################################################"
  retry() {
    for i in {1..15}; do
      eval $@ && return_status=$? && break || return_status=$? && sleep 30;
      retry /tmp/deployments/ChefNode/ChefNodeInstall.sh
    done
    return $${return_status}
  }
  cd $${HOME}

  yum install -y httpd6 php56-mysqlnd
  service httpd start
  chkconfig httpd on
  EOF
}

resource "aws_route53_record" "apache" {
  zone_id                     = "ZBVO8OQHTFSNO"
  name                        = "apache.erich.com"
  type                        = "CNAME"
  ttl                         = "60"
  records                     = ["${aws_instance.apache.public_dns}"]
}

resource "aws_instance" "chefserver" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.small"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  # TODO: make this instance profile have access to private chef bucket
  iam_instance_profile        = "${aws_iam_instance_profile.ssm_profile.id}"

  provisioner "file" {
    source                    = "/Users/ej/.ssh/id_rsa"
    destination               = "/home/ec2-user/.ssh/id_rsa"
    connection {
      user                    = "ec2-user"
      agent                   = "false"
      type                    = "ssh"
      private_key             = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
      timeout                 = "300s"
    }
  }

  provisioner "file" {
    source                    = "/Users/ej/.ssh/id_rsa.pub"
    destination               = "/home/ec2-user/.ssh/id_rsa.pub"
    connection {
      user                    = "ec2-user"
      agent                   = "false"
      type                    = "ssh"
      private_key             = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
      timeout                 = "300s"
    }
  }

  provisioner "file" {
    source                    = "/Users/ej/.ssh/ej_key_pair.pem"
    destination               = "/home/ec2-user/.ssh/ej_key_pair.pem"
    connection {
      user                    = "ec2-user"
      agent                   = "false"
      type                    = "ssh"
      private_key             = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
      timeout                 = "300s"
    }
  }

  provisioner "file" {
      source                    = "/tmp/myfile.txt"
      destination               = "/tmp/myfile.txt"
      connection {
        user                    = "ec2-user"
        agent                   = "false"
        type                    = "ssh"
        private_key             = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
        timeout                 = "300s"
      }
  }

  tags {
        Name                  = "chefserver"
        Environment           = "Test"
  }
  user_data                   = <<EOF
  #!/bin/bash
  echo "##################################################################################"
  echo "##### yum ########################################################################"
  echo "##################################################################################"
  yum update -y
  yum install jq bc git -y
  echo "##################################################################################"
  echo "##### copy keys ##################################################################"
  echo "##################################################################################"
  retry() {
    for i in {1..15}; do
      eval $@ && return_status=$? && break || return_status=$? && sleep 30;
      cp /home/ec2-user/.ssh/id_rsa      /root/.ssh/id_rsa
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
  myip=$(nslookup chefserver.erich.com | grep Address | tail -1 | cut -f2 -d ":")
  echo "$myip apache apache.erich.com" > /etc/hosts
  hostname chefserver
  echo "##################################################################################"
  echo "##### github details #############################################################"
  echo "##################################################################################"
  ssh-keyscan github.com >>/root/.ssh/known_hosts
  echo -e "Host github.com           " > ~/.ssh/config
  echo -e " StrictHostKeyChecking no " >> ~/.ssh/config
  echo -e "                          " >> ~/.ssh/config
  sudo chmod 600 ~/.ssh/config
  cd /tmp
  git config --global user.name  'EJ Best'
  git config --global user.email 'ejbest@alumni.rutgers.edu'
  chmod 400 /root/.ssh/*
  ls -lS    /root/.ssh/
  echo "##################################################################################"
  echo "##### doing git clone ############################################################"
  echo "##################################################################################"
  git clone git@github.com:ejbest/deployments.git
  echo "##################################################################################"
  echo "##### ChefServerInstall_RedHat.sh ################################################"
  echo "##################################################################################"
  sh /tmp/deployments/ChefMaster/ChefServerInstall_RedHat.sh
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
