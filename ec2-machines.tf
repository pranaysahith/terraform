
resource "aws_instance" "apache" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  # TODO: make this instance profile have access to private chef bucket
  iam_instance_profile        = "${aws_iam_instance_profile.ssm_profile.id}"

  tags {
        Name                  = "apache"
        Environment           = "Test"
  }

  provisioner "file" {
    source      = "/Users/ej/.ssh/ej_key_pair.pem"
    destination = "/root/.ssh/ej_key_pair.pem"
  }

  provisioner "file" {
    source      = "/vol1/mytest.txt"
    destination = "/tmp/mytest.txt"
  }
  provisioner "file" {
    source      = "/vol1/deployments"
    destination = "/tmp/deployments"
  }

  user_data                   = <<EOF
  #!/bin/bash
  echo "##################################################################################"
  echo "##### yum ########################################################################"
  echo "##################################################################################"
  yum update -y
  echo "##################################################################################"
  echo "##### Setting Host Details #######################################################"
  echo "##################################################################################"
  sed -i "s/localhost.localdomain/apache/g" /etc/sysconfig/network
  myip=$(nslookup apache.erich.com | grep Address | tail -1 | cut -f2 -d ":")
  echo "$myip apache apache.erich.com" > /etc/hosts
  hostname apache

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
    source      = "~/.ssh/ej_key_pair.pem"
    destination = "/root/.ssh/ej_key_pair.pem"
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
  echo "##################################################################################"
  echo "##### rsa keys ###################################################################"
  echo "##################################################################################"
  cd /root/.ssh
  python rsassm_id_rsa.py > id_rsa
  python rsassm_ej_key_pair.pem > ej_key_pair.pem
  cd /home/ec2-user/
  python ret-ssm.py


  echo "# getting rsa keys and giving them to both root and ec2-user ##############################"
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'id_rsa' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed -e $'s/,/\\n/g') " > /root/.ssh/id_rsa
  yum -y install jq bc git
  ssh-keyscan github.com >>/root/.ssh/known_hosts
  chmod 400 /root/.ssh/id_rsa
  chmod 700 /root/.ssh
  ls -lS    /root/.ssh/*
  echo -e "Host github.com           " > ~/.ssh/config
  echo -e " StrictHostKeyChecking no " >> ~/.ssh/config
  echo -e "                          " >> ~/.ssh/config
  sudo chmod 600 ~/.ssh/config
  cd /tmp
  echo "#####################  doing now the clone #####################################################################"
  git config --global user.name  'EJ Best'
  git config --global user.email 'ejbest@alumni.rutgers.edu'
  git clone git@github.com:ejbest/deployments.git
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
