resource "aws_instance" "ChefMaster" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.small"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids      = ["${aws_security_group.FrontEnd.id}"]
  key_name = "${var.key_name}"
  tags {
        Name = "ChefMasterTag"
  }
  user_data = <<EOF
  #!/bin/bash
  yum update -y
EOF
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mysql"
  username             = "sqladmin "
  password             = "123456"
  parameter_group_name = "default.mysql5.7"
}

resource "aws_instance" "apache" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.FrontEnd.id}"]
  key_name = "${var.key_name}"
  tags {
        Name = "apachetTag"
  }
  user_data = <<EOF
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
