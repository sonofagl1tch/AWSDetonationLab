#!/bin/bash

# install apps for attack
sudo yum install ncat -y -q -e 0
sudo yum install nc -y -q -e 0

# Install Apache
sudo yum install httpd -y -q -e 0
sudo service httpd start

# Install MySQL
sudo rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
sudo yum install mysql-server -y -q -e 0
sudo service mysqld start

#sudo /usr/bin/mysql_secure_installation
#
# Automate mysql secure installation for debian-baed systems
# 
#  - You can set a password for root accounts.
#  - You can remove root accounts that are accessible from outside the local host.
#  - You can remove anonymous-user accounts.
#  - You can remove the test database (which by default can be accessed by all users, even anonymous users), 
#    and privileges that permit anyone to access databases with names that start with test_. 
#  For details see documentation: http://dev.mysql.com/doc/refman/5.7/en/mysql-secure-installation.html
#
# @version 13.08.2014 00:39 +03:00
# Tested on Debian 7.6 (wheezy)
#
# Usage:
#  Setup mysql root password:  ./mysql_secure.sh 'your_new_root_password'
#  Change mysql root password: ./mysql_secure.sh 'your_old_root_password' 'your_new_root_password'"
#

# Delete package expect when script is done
# 0 - No; 
# 1 - Yes.
PURGE_EXPECT_WHEN_DONE=0

#
# Check the bash shell script is being run by root
#
# if [[ $EUID -ne 0 ]]; then
#    echo "This script must be run as root" 1>&2
#    exit 1
# fi

#
# Check input params
#
# if [ -n "${1}" -a -z "${2}" ]; then
#     # Setup root password
#     CURRENT_MYSQL_PASSWORD=''
#     NEW_MYSQL_PASSWORD="${1}"
# elif [ -n "${1}" -a -n "${2}" ]; then
#     # Change existens root password
#     CURRENT_MYSQL_PASSWORD="${1}"
#     NEW_MYSQL_PASSWORD="${2}"
# else
#     echo "Usage:"
#     echo "  Setup mysql root password: ${0} 'your_new_root_password'"
#     echo "  Change mysql root password: ${0} 'your_old_root_password' 'your_new_root_password'"
#     exit 1
# fi


# Setup root password
CURRENT_MYSQL_PASSWORD=''
NEW_MYSQL_PASSWORD="master"

#
# Check is expect package installed
#
if [ $(dpkg-query -W -f='${Status}' expect 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Can't find expect. Trying install it..."
    yum -y install expect -y -q -e 0

fi

SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"root password?\"
send \"y\r\"
expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

#
# Execution mysql_secure_installation
#
# echo "${SECURE_MYSQL}"
# 
# if [ "${PURGE_EXPECT_WHEN_DONE}" -eq 1 ]; then
#     # Uninstalling expect package
#     yum -y purge expect -y -q -e 0
# fi


# Install PHP
sudo yum install php php-mysql -y -q -e 0
sudo yum install php-* -y -q -e 0

# set services to start on boot
sudo chkconfig httpd on
sudo chkconfig mysqld on

# setup first php page
cat > /var/www/html/info.php <<\EOF
<?php
phpinfo();
?>
EOF

#make vulnerable php index
cat > /var/www/html/index.php <<\EOF
<?php
include("header.php");
include($_GET["page"]);
#passthru($_GET'cmd');
include($_GET["cmd"]);
#include("includes/".basename($_GET["page"]).".php");
system($_GET["cmd"]);
?>
EOF

#make html file upload page
cat > /var/www/html/index.html <<\EOF
<!DOCTYPE html>
<html>
<body>

<form action="upload.php" method="post" enctype="multipart/form-data">
    Select image to upload:
    <input type="file" name="fileToUpload" id="fileToUpload">
    <input type="submit" value="Upload Image" name="submit">
</form>

</body>
</html>
EOF

#make file upload php
cat > /var/www/html/upload.php <<\EOF
<?php
$target_dir = "uploads/";
$target_file = $target_dir . basename($_FILES["fileToUpload"]["name"]);
$uploadOk = 1;
$imageFileType = strtolower(pathinfo($target_file,PATHINFO_EXTENSION));
// Check if image file is a actual image or fake image
if(isset($_POST["submit"])) {
    $check = getimagesize($_FILES["fileToUpload"]["tmp_name"]);
    if($check !== false) {
        echo "File is an image - " . $check["mime"] . ".";
        $uploadOk = 1;
    } else {
        echo "File is not an image.";
        $uploadOk = 0;
    }
}
// Check if file already exists
if (file_exists($target_file)) {
    echo "Sorry, file already exists.";
    $uploadOk = 0;
}
// Check file size
if ($_FILES["fileToUpload"]["size"] > 500000) {
    echo "Sorry, your file is too large.";
    $uploadOk = 0;
}
// Allow certain file formats
if($imageFileType != "jpg" && $imageFileType != "png" && $imageFileType != "jpeg"
&& $imageFileType != "gif" ) {
    echo "Sorry, only JPG, JPEG, PNG & GIF files are allowed.";
    $uploadOk = 0;
}
// Check if $uploadOk is set to 0 by an error
if ($uploadOk == 0) {
    echo "Sorry, your file was not uploaded.";
// if everything is ok, try to upload file
} else {
    if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
        echo "The file ". basename( $_FILES["fileToUpload"]["name"]). " has been uploaded.";
    } else {
        echo "Sorry, there was an error uploading your file.";
    }
}
?>
EOF

#make upload directory
mkdir -p /var/www/html/uploads

#add apache to wheel because we want bad things to happen
usermod -aG wheel apache

# restart web service
sudo service httpd restart