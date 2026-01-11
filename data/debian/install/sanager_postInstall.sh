DEBIAN_FRONTEND="noninteractive" apt-get install openssh-server -y -qq
sed -i -r "s~#PermitRootLogin [-a-z]+~PermitRootLogin yes~g" /etc/ssh/sshd_config
sed -i -r "s~#PasswordAuthentication yes~PasswordAuthentication yes~g" /etc/ssh/sshd_config
ssh-keygen -A # ensure mandatory ssh server folders and files exist
systemctl restart sshd
