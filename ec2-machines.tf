
# this is a marker

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
      source                  = "/tmp/myfile.txt"
      destination             = "/tmp/myfile.txt"
      connection {
        user                  = "ec2-user"
        agent                 = "false"
        type                  = "ssh"
        private_key           = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
        timeout               = "300s"
      }
  }
  tags {
        Name                  = "apache"
        Environment           = "Test"
  }
  #user_data_base64           = "${base64encode(file("./files/user_data.sh"))}"
  provisioner "remote-exec" {
      script                  = "./files/user_data.sh"
      connection {
        user                  = "ec2-user"
        agent                 = "false"
        type                  = "ssh"
        private_key           = "${file("/Users/ej/.ssh/ej_key_pair.pem")}"
        timeout               = "300s"
      }
  }
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
  user_data_base64            = "${base64encode(file("./files/chef_user_data.sh"))}"
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
  name                        = "ssm_profile1"
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

#resource "aws_iam_role_policy_attachment" "ssm_readonly_policy_attach"{
#role                          = "${aws_iam_role.ssm_role.name}"
#policy_arn                    = "${data.aws_iam_policy.ReadOnlyAccess.arn}"
#}
