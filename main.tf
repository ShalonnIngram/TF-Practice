resource "aws_s3_bucket" "shalonn-tf" {
  bucket = "shalonn2023tfprojects"

}

resource "aws_s3_bucket_versioning" "version_my_bucket" {
  bucket = aws_s3_bucket.shalonn-tf.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "main_vpc"

  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"

  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet"
  }

}

resource "aws_subnet" "data" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "data-subnet"
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }

}

resource "aws_eip" "nat_eip" {
  vpc = true

}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id     = aws_eip.nat_eip.id
  connectivity_type = "public"
  subnet_id         = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]

}

resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "nat-route-table"
  }
}

resource "aws_route_table" "aws_internet_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "internet-route-table"
  }
}

resource "aws_route_table_association" "route_tbl_assoc_private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.nat_route_table.id
}

resource "aws_route_table_association" "route_tbl_assoc_public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.aws_internet_route_table.id
}

resource "aws_route_table_association" "route_tbl_assoc_data" {
  subnet_id      = aws_subnet.data.id
  route_table_id = aws_route_table.nat_route_table.id
}
