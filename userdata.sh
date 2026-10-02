#!/bin/bash

#Terraform variables that will be passed by terraform  
file="${file}"
region="${region}"
dbname="${dbname}"
dbusername="${dbusername}"
dbendpoint="${dbendpoint}"
dbpassword="${dbpassword}"
lb_dns="${lb_dns}"

#--Bash variables
mount_point="/var/www/html"



#Logging Error and Output into a file 
exec > /home/ec2-user/myscript.log 2>&1

#Installing NFS Utilities 
sudo dnf install -y nfs-utils


#Installing Git 
sudo dnf install git -y

#SSM agent to put instances in fleet
sudo systemctl start amazon-ssm-agent

#Making /var/www/html Diractly. This is directory where webserver looks at and the EFS filesytem will be mounted in this directory 
sudo mkdir -p "$${mount_point}"

#Changing file ownership
sudo chown ec2-user:ec2-user "$${mount_point}"

#Printing out to standard output while piping the output to into tee command which writes into the file and standard output 
echo "${file}.efs.${region}.amazonaws.com:/ $${mount_point} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" | sudo tee -a /etc/fstab

#Checking Exit status of echo command 
if [ $? == 0 ]
then
    echo "EFS info was written into the /etc/fstab"
else
    echo "EFS info was not written into the /etc/fstab"
fi
sleep 60

#Automatically mounting the Efs everytime system reboots 
sudo mount -a 


#The reason the  above commands are harshed  out is because i couldnt find amazon linux 2 AMI and now am using Amazon linux 2023 and the to install lamp is different which you can see below:
sudo dnf update -y
sudo dnf install -y httpd
sudo dnf install -y mariadb105
sudo dnf install -y php php-mysqlnd

sudo systemctl enable --now httpd

 
##Add ec2-user to Apache group and grant permissions to /var/www
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chown -R ec2-user:ec2-user /home/ec2-user
sudo chmod 755 /home/ec2-user
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;
cd /var/www/html

#Checking to see if wp-config.php exist because you dont want to duplicate it and also you are not sure of what is inside
if [ -f /var/www/html/wp-config.php ]
then
    echo "wp-config.php already exists"
    
else
    echo "wp-config.php does not exist"
    git clone https://github.com/stackitgit/CliXX_Retail_Repository.git
fi
        
#Copying all content of the Clixx repo to /var/www/html to because thath the folder apache loooks to load up the application 
cp -r CliXX_Retail_Repository/* /var/www/html

#Removing the wp-config.php that's currently available because you dont know what is currenlty in it 
rm wp-config.php

#Now you are copying the sample into a new wp-config.php and we will start changing what is in it 
cp -r wp-config-sample.php wp-config.php

#This command here is needed becasue apache wasnt loading the application but it was loading the apache welcome page so I needed to tell apache to ignore the apache welcome page 
sudo mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.disabled

#Restarting apache to get used to the new rule which dont serve your welcome page 
sudo systemctl restart httpd

# Remember we copied the sample into a new wp-config file so now we are changing the content of the new wp-config file to content our database information
sudo sed -i '151s/None/All/' /etc/httpd/conf/httpd.conf
sudo sed -i "s/database_name_here/${dbname}/" /var/www/html/wp-config.php
sudo sed -i "s/username_here/${dbusername}/" /var/www/html/wp-config.php
sudo sed -i "s/localhost/${dbendpoint}/" /var/www/html/wp-config.php
sudo sed -i "s/password_here/${dbpassword}/" /var/www/html/wp-config.php
#sudo sed -i "s/define( 'WP_DEBUG', false );/define( 'WP_DEBUG', false ); \nif (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) \&\& \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\$_SERVER['HTTPS'] = 'on';}/" /var/www/html/wp-config.php
sudo sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php index.html/" /etc/httpd/conf/httpd.conf

#Just checking to see the exist status of the last command 
if [ $? == 0 ]
then
    echo "The last sed command was done"
else
    echo "The last sed command was not done"
fi

#Sleeping for 300 seconds because i need the database to be ready so i can log into it 
sleep 300
output_variable="$(mysql -u "${dbusername}" -p"${dbpassword}" -h "${dbendpoint}" -D "${dbname}" -sse "SELECT option_value FROM wp_options WHERE option_value LIKE 'CliXX-APP-%';")"
echo "$${output_variable}"


if [ "$${output_variable}" == "$${lb_dns}" ]; then
    echo "DNS Address in the table"
else
    echo "DNS Address is not in the table"
    mysql -u "${dbusername}" -p"${dbpassword}" -h "${dbendpoint}" -D "${dbname}" <<EOF
UPDATE wp_options SET option_value ="${lb_dns}" WHERE option_value LIKE "CliXX-APP-%";
EOF
fi



##Grant file ownership of /var/www & its contents to apache user
sudo chown -R apache /var/www

##Grant group ownership of /var/www & contents to apache group
sudo chgrp -R apache /var/www

##Change directory permissions of /var/www & its subdir to add group write 
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;

##Recursively change file permission of /var/www & subdir to add group write perm
sudo find /var/www -type f -exec sudo chmod 0664 {} \;

##Restart Apache
sudo systemctl restart httpd
sudo service httpd restart

##Enable httpd 
sudo systemctl enable httpd 
sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_time=200 net.ipv4.tcp_keepalive_intvl=200 net.ipv4.tcp_keepalive_probes=5