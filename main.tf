terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
access_key = "${var.aws_access_key}"
secret_key = "${var.aws_secret_key}"
region     = "ap-south-1"
}

#Creating VPC, public & Private Suvnet and NatGateway and RouteTable

resource "aws_vpc" "ESvpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true

    tags = {
        Name = "ESVPC"
    }
}

resource "aws_internet_gateway" "ESNATGateway" {
  vpc_id = aws_vpc.ESvpc.id
}

resource "aws_subnet" "PublicSubnetforES" {
    vpc_id = "${aws_vpc.ESvpc.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "ap-south-1a"

    tags= {
        Name = "Public Subnet"
    }
}

resource "aws_subnet" "PrivateSubnetForES" {
    vpc_id = "${aws_vpc.ESvpc.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "ap-south-1a"

    tags ={
        Name = "Private Subnet"
    }
}

resource "aws_route_table" "ESroutetable" {
  vpc_id = aws_vpc.ESvpc.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ESNATGateway.id
  }


}

# Subnet - Route Table associations
resource "aws_route_table_association" "PublicSubnetforES" {
  subnet_id      = aws_subnet.PublicSubnetforES.id
  route_table_id = aws_route_table.ESroutetable.id
}

#Creating Security Group for the Elasticsearch

resource "aws_security_group" "ESSecurityGroup" {
    name = "ElasticseaarchSecurityGroup"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        #cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 9200
        to_port = 9200
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 9300
        to_port = 9300
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   vpc_id = "${aws_vpc.ESvpc.id}"

    tags= {
        Name = "NATSG"
    }
}

resource "aws_instance" "elasticserchserver" {
  ami           = var.ami
  instance_type = var.instance_type
  #count = "${var.instance_count}"
  availability_zone = "ap-south-1a"
  key_name = "eskey"
  vpc_security_group_ids = ["${aws_security_group.ESSecurityGroup.id}"]
  subnet_id = "${aws_subnet.PublicSubnetforES.id}"
  #subnet_id = "${element(list("${aws_subnet.PublicSubnetforES.id}", "${aws_subnet.PrivateSubnetForES.id}"), count.index)}"
  associate_public_ip_address = true
  source_dest_check = false

provisioner "remote-exec" {
     inline = ["sudo yum update -y", "sudo yum install unzip -y", "echo Done!"]


  connection {
      type        = "ssh"
      agent       = false
      host        = self.public_ip
      user        = "centos"
      private_key = file(var.aws_key_path)
  }
}
provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos -i '${self.public_ip},' --private-key ${var.aws_key_path} /home/himanshu/Elasticsearchcluster/esearch.yml"
  }


  tags = {
    Name = var.instance_name
  }
}
