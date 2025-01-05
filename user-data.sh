#!/bin/bash
sudo su
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello world!! $(hostname -f)</h1>" > /var/www/html/index.html