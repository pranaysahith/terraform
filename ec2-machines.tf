

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
  yum update -y
  yum -y install jq bc git
  su - ec2-user
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'ejs' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" >        /home/ec2-user/.ssh/ej_key_pair.pem
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpubkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa.pub
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpvtkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa
  chmod 600 /home/ec2-user/.ssh/ej_key_pair.pem
  chmod 600 /home/ec2-user/.ssh/id_rsa
  chmod 600 /home/ec2-user/.ssh/id_pub
  #Chef Installation Starts Here
  mkdir /root/.chef
  cd /tmp
  git config --global user.name "ejbest"
  git config --global user.email "ejbest@alumni.rutgers.edu"
  git config --global push.default matching
  echo -e '#!/bin/bash\nexec /usr/bin/ssh -o StrictHostKeyChecking=no -i /home/ec2-user/.ssh/id_rsa $@' > /tmp/git_ssh
  chmod +x /tmp/git_ssh
  export GIT_SSH="/tmp/git_ssh"
  git clone git@github.com:ejbest/deployments.git
  cd $${HOME}
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
  yum update -y
  yum -y install jq bc git
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'ejs' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" >        /home/ec2-user/.ssh/ej_key_pair.pem
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpubkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa.pub
  echo -ne "-$(aws ssm get-parameters --region us-east-1 --names 'chefpvtkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed 's/, /\\n/g')" > /home/ec2-user/.ssh/id_rsa
  chmod 600 /home/ec2-user/.ssh/ej_key_pair.pem
  chmod 600 /home/ec2-user/ssh/id_rsa
  chmod 600 /home/ec2-user/.ssh/id_pub
  # aws s3api get-object --bucket chef-server-test --key chefserver.pub /etc/chef/chef-validator.pem
  cd /tmp
  git config --global user.name "ejbest"
  git config --global user.email "ejbest@alumni.rutgers.edu"
  git config --global push.default matching
  # curl -L https://www.chef.io/chef/install.sh | bash -s -- -v 12.12.13
  # chef-client -j <(echo "{"run_list": ["role[apache]"]}")
  # rm -rf /etc/chef/chef-validator.pem
  echo -e '#!/bin/bash\nexec /usr/bin/ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa $@' > /tmp/git_ssh
  chmod +x /tmp/git_ssh
  export GIT_SSH="/tmp/git_ssh"
  git clone git@github.com:ejbest/deployments.git
  retry() {
    for i in {1..15}; do
      eval $@ && return_status=$? && break || return_status=$? && sleep 30;
    done
    return $${return_status}
  }
cd $${HOME}
retry /tmp/deployments/ChefNode/ChefNodeInstall.sh
sh /tmp/deployments/ChefMaster/ChefWorkInstall_RedHat.sh
EOF
}

resource "aws_route53_record" "chefserver" {
  zone_id                     = "ZBVO8OQHTFSNO"
  name                        = "chefserver.erich.com"
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
