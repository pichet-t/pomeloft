#terraform {
#  backend "s3" {
#    bucket = "my-backbone-bucket"
#    key    = "poml/state"
#    region = "us-east-1"
#  }
#}


provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  
}

locals {
    internet_cidr = "0.0.0.0/0"
    az = "us-east-1b"
    secondary_az = "us-east-1a"
}

variable "RDS_PASSWORD" {}

resource "aws_ebs_volume" "poml_userdata_backup" {
  availability_zone = local.az
  size              = 1
  type              = "standard"
tags = {
      "Name" = "poml-userbackup"
      "product" = "poml"
  }
}

#resource "aws_key_pair" "penpen" {
#  key_name   = "penpen"
#  public_key = "ssh-rsa ///+L2rBHWW/+Kc/"
#}

resource "aws_vpc" "poml_prod" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

tags = {
      "product" = "poml"
  }

}

resource "aws_subnet" "poml_prod" {
  availability_zone = local.az
  vpc_id     = aws_vpc.poml_prod.id
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = true

tags = {
      "product" = "poml"
  }
}

resource "aws_subnet" "poml_secondary_az" {
  availability_zone = local.secondary_az
  vpc_id     = aws_vpc.poml_prod.id
  cidr_block = "192.168.2.0/24"
  map_public_ip_on_launch = true

tags = {
      "product" = "poml"
  }

}


resource "aws_internet_gateway" "poml_prod" {
  vpc_id = aws_vpc.poml_prod.id

tags = {
      "product" = "poml"
  }
}

resource "aws_route_table" "poml_prod" {
 vpc_id = aws_vpc.poml_prod.id
 route {
    cidr_block = local.internet_cidr
    gateway_id = aws_internet_gateway.poml_prod.id
 }
 tags = {
      "product" = "poml"
 }
}
resource "aws_route_table_association" "poml_prod" {
  subnet_id      = aws_subnet.poml_prod.id
  route_table_id = aws_route_table.poml_prod.id
}

resource "aws_network_acl" "poml_prod" {
  vpc_id = aws_vpc.poml_prod.id
  subnet_ids = [ aws_subnet.poml_prod.id ]

  ingress {
      protocol = "all"
      rule_no = 900
      action = "allow"
      cidr_block = local.internet_cidr
      from_port = 0
      to_port = 0
  }

  egress {
      protocol = "all"
      rule_no = 900
      action = "allow"
      cidr_block = local.internet_cidr
      from_port = 0
      to_port = 0
  }

   ingress {
     protocol   = "tcp"
     rule_no    = 100
     action     = "allow"
     cidr_block = local.internet_cidr
     from_port  = 22
     to_port    = 22
   }
  
   ingress {
     protocol   = "tcp"
     rule_no    = 200
     action     = "allow"
     cidr_block = local.internet_cidr
     from_port  = 80
     to_port    = 80
   }

    ingress {
     protocol   = "tcp"
     rule_no    = 300
     action     = "allow"
     cidr_block = local.internet_cidr
     from_port  = 443
     to_port    = 443
   }

   egress {
     protocol   = "tcp"
     rule_no    = 100
     action     = "allow"
     cidr_block = local.internet_cidr
     from_port  = 22 
     to_port    = 22
   }
  
   egress {
     protocol   = "tcp"
     rule_no    = 200
     action     = "allow"
     cidr_block = local.internet_cidr
     from_port  = 80  
     to_port    = 80 
   }

   egress {
     protocol   = "tcp"
     rule_no    = 300
     action     = "allow"
     cidr_block = local.internet_cidr
     from_port  = 443  
     to_port    = 443 
   }

   tags = {
    "product" = "poml"
   }
}

resource "aws_security_group" "poml" {
  name        = "sg_poml"
  description = "SG for poml"
  vpc_id      = aws_vpc.poml_prod.id

  ingress {
    description = "SSH from the world"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.internet_cidr]
  }

  ingress {
    description = "HTTP from the world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.internet_cidr]
  }

  ingress {
    description = "RDS  from the world"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.internet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.internet_cidr]
  }

tags = {
      "product" = "poml"
  }

}

resource "aws_db_subnet_group" "poml_mysql" {
    name = "poml-mysql-subnet"
    description = "RDS subnet group"
    subnet_ids = [aws_subnet.poml_prod.id, aws_subnet.poml_secondary_az.id]
}


resource "aws_db_instance" "mysql" {
    availability_zone = local.az
    allocated_storage = 20
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t3.micro"
    identifier = "poml-mysql"
    name = "dracidoupe_cz"
    username = "root"
    password = var.RDS_PASSWORD
    parameter_group_name = "default.mysql5.7"
    skip_final_snapshot = true
    final_snapshot_identifier = "poml-mysql-snap"

    multi_az = "false"

    db_subnet_group_name = aws_db_subnet_group.poml_mysql.name
    vpc_security_group_ids = [aws_security_group.poml.id]

    storage_type = "standard"
    publicly_accessible = "true"

    tags = {
        "product" = "poml"
    }
}

#resource "aws_s3_bucket" "poml_uploads_bucket" {
#  bucket = "uploady.pomelo.fsh"
#  acl    = "public-read"
#
#  tags = {
#    "product" = "poml"
#  }
#}


resource "aws_eip" "poml" {
  instance = aws_instance.poml.id
  vpc      = true
  depends_on = [aws_internet_gateway.poml_prod, aws_instance.poml]
}

resource "aws_instance" "poml" {
  ami           = "ami-04c15f19de39e5c0e"
  instance_type = "t2.nano"
  disable_api_termination = "false"
  key_name      = "my-KeyPair"
  availability_zone = local.az

  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.poml.id]
  subnet_id              = aws_subnet.poml_prod.id

  root_block_device {
    volume_type = "standard"
    volume_size = 12
    delete_on_termination = true
  }


#  connection {
#    type        = "ssh"
#    user        = "user"
#    private_key = file("my-KeyPair.pem")
#    host        = self.public_ip
#  }
  
#  user_data = file("setup.sh")
  
#  provisioner "file" {
#    source      = "etc/services/run"
#    destination = "/etc/service/pomelo.fsh/run"
#  }

#  provisioner "file" {
#    source      = "etc/lighttpd.conf"
#    destination = "/etc/lighttpd/lighttpd.conf"
#  }

#  provisioner "file" {
#    source      = "dbcore.php"
#    destination = "/var/www/pomelo.fsh/www_root/www/htdocs/dbcore.php"
#  }

#   provisioner "file" {
#     source      = "etc/modules/custom-access-log"
#     destination = "/etc/lighttpd/modules/custom-access-log"
#   }

#   provisioner "file" {
#     source      = "etc/modules/fcgi-socket-php"
#     destination = "/etc/lighttpd/modules/fcgi-socket-php"
#   }

#   provisioner "file" {
#     source      = "etc/sites/pomelo.fsh"
#     destination = "/etc/lighttpd/sites/pomelo.fsh"
#   }

tags = {
      "product" = "poml"
  }


#   provisioner "remote-exec" {
#     inline = [
#         "mkdir /var/www",
#         "mount -t ext4 /dev/xvdf1 /var/www",
#         "sudo echo 'deb http://archive.debian.org/debian squeeze main' > /etc/apt/sources.list'",
#         "sudo echo 'deb http://archive.debian.org/debian squeeze-lts main' >> /etc/apt/sources.list",
#         "sudo echo 'Acquire::Check-Valid-Until false;' > /etc/apt/apt.conf",
#         "sudo apt-get update",
#         "sudo apt-get -y --force-yes -q install lighttpd php5-cgi php5-cli php5-curl php5-imagick php5-mysql daemontools daemontools-run procps spawn-fcgi",
#         "groupadd w-dracidoupe-cz",
#         "useradd w-dracidoupe-cz -g w-dracidoupe-cz",
#         "groupadd wwwserver",
#         "useradd lighttpd -g www-data -g wwwserver",
#         "mkdir /etc/service/pomelo.fsh",
#         "mkdir -p /var/www/pomelo.fsh/www_root/www/php/",
#         "mkdir -p /var/www/fastcgi/sockets/w-dracidoupe-cz/",
#         "chown -R w-dracidoupe-cz:wwwserver /var/www/fastcgi/sockets/w-dracidoupe-cz/",
#     ]
#   }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.poml_userdata_backup.id
  instance_id  = aws_instance.poml.id
  skip_destroy = true
}
