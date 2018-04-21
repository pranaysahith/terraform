resource "aws_instance" "phpapp" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.FrontEnd.id}"]
  key_name = "${var.key_name}"
  tags {
        Name = "Linuxinstance"
  }
  user_data = <<EOF
  #!/bin/bash
  yum update -y
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