resource "aws_instance" "ChefMaster" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.small"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name                    = "${var.key_name}"
  tags {
        Name                  = "ChefMaster"
        Environment           = "Test"
  }
  user_data = <<EOF
  #!/bin/bash
  yum update -y
EOF
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
}

resource "aws_db_subnet_group" "dbsubnet" {
  subnet_ids  = ["${aws_subnet.PublicAZA.id}", "${aws_subnet.PublicAZB.id}"]
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
  ami           = "${lookup(var.Amiwindows, var.region)}"
  instance_type = "t2.micro"
  associate_public_ip_address = "false"
  subnet_id = "${aws_subnet.PrivateAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.Backend.id}"]
  key_name = "${var.key_name}"
  tags {
        Name = "windows"
  }

}
