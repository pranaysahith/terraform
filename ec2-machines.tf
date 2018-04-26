resource "aws_instance" "ChefMaster" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.small"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.ssm_profile.id}"
  tags {
        Name                  = "ChefMaster"
        Environment           = "Test"
  }
  user_data                   = <<EOF
  #!/bin/bash
  yum update -y
  yum -y install jq bc git
  echo "`aws ssm get-parameters --region us-east-1 --names 'ejs' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed -r 's/,/\\n/g'`\"> /root/.ssh/ej_key_pair.pem
  echo "`aws ssm get-parameters --region us-east-1 --names 'chefpubkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed -r 's/ /\\n/g'`"> /root/.ssh/id_rsa.pub
  echo "`aws ssm get-parameters --region us-east-1 --names 'chefpvtkey' --with-decryption --output json | jq --raw-output '.Parameters[0].Value' | sed -r 's/ /\\n/g'`"> /root/.ssh/id_rsa
  chmod 600 /root/.ssh/ej_key_pair.pem
  chmod 600 /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_pub
  cd /tmp
  git config --global user.name "ejbest"
  git config --global user.email "ejbest@alumni.rutgers.edu"
  git config --global push.default matching
EOF
}

resource "aws_instance" "apache" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  tags {
        Name                  = "apache"
  }
  user_data                   = <<EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd6 php56-mysqlnd
  service httpd start
  chkconfig httpd on
  EOF
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
      zone_id = "${aws_route53_zone.primary.zone_id}"
      name = "database.erich.com"
      type = "CNAME"
      ttl = "60"
      records = ["${aws_db_instance.default.endpoint}"]
   }

resource "aws_db_subnet_group" "dbsubnet" {
  subnet_ids  = ["${aws_subnet.PublicAZA.id}", "${aws_subnet.PublicAZB.id}"]
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name  = "ssm_profile"
  role = "${aws_iam_role.ssm_role.name}"
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"
  path = "/"
  assume_role_policy = <<EOF
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

data "aws_iam_policy" "ReadOnlyAccess"{
arn =  "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_readonly_policy_attach"{
role       = "${aws_iam_role.ssm_role.name}"
policy_arn =  "${data.aws_iam_policy.ReadOnlyAccess.arn}"

}
