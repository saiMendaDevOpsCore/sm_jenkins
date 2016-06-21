#!/bin/bash

## Source Common Functions
curl -s "https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh" >/tmp/common-functions.sh
#source /root/scripts/common-functions.sh
source /tmp/common-functions.sh

## Checking Root User or not.
CheckRoot

## Checking SELINUX Enabled or not.
CheckSELinux

## Checking Firewall on the Server.
CheckFirewall

Check_Jenkins_Start() {
    i=180 # 100 Seconds
    while [ $i -gt 0 ]; do 
        netstat -lntp | grep 8080 &>/dev/null 
        if [ $? -eq 0 ]; then 
            j=180
            while [ $j -gt 0 ]; do 
                grep isSetupComplete /var/lib/jenkins/config.xml &>/dev/null && break 
                j=$(($j-10))
                sleep 10
                continue
            done
            [ ! -f  /var/lib/jenkins/config.xml ] && return 1
            return 0
        else
            i=$(($i-10))
            sleep 10
            continue 
        fi 
    done
    return 1
}

Check_Jenkins_Stop() {
    i=180 # 100 Seconds
    while [ $i -gt 0 ]; do 
        netstat -lntp | grep 8080 &>/dev/null 
        if [ $? -ne 0 ]; then 
            return 0
        else
            i=$(($i-10))
            sleep 10
            continue 
        fi 
    done
    return 1
}

### Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo &>/dev/null
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key &>/dev/null
yum install jenkins java -y &>/dev/null
Stat $? "Installing Jenkins"
systemctl enable jenkins &>/dev/null
systemctl start jenkins
Check_Jenkins_Start
Stat $? "Starting Jenkins"
systemctl stop jenkins
Check_Jenkins_Stop
[ $? -ne 0 ] && Stat 1 "Configuring Jenkins"
sed -i -e '/isSetupComplete/ s/false/true/' -e '/name/ s/NEW/RUNNING/' /var/lib/jenkins/config.xml
mkdir -p /var/lib/jenkins/users/admin 
curl -s https://raw.githubusercontent.com/linuxautomations/jenkins/master/admin.xml >/var/lib/jenkins/users/admin/config.xml
chown jenkins:jenkins /var/lib/jenkins/users -R 
systemctl start jenkins
Stat $? "Configuring Jenkins"

### Final Status
PU_IP=$(curl -s ifconfig.co)
sleep 30
systemctl restart jenkins &>/dev/null
head_bu "Access the Jenkins using following URL and Credentials"
info "http://$PU_IP:8080"
info "Username : admin"
info "Password : admin"

#
