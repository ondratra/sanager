# Sanager - System Manager

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

Installs all applications and libraries used by autor on local computer. Script targets Debian unstable distribution
but should provide similar(hopefully identical) environmnent of all on all Debian-based distributions.

# Prerequisites
1) Install minimal Debian distribution (known as "net install") from https://www.debian.org/CD/http-ftp/ . 
More robust installation medium is also ok.

2) Put this to /etc/apt/sources.list
```
deb http://merlin.fit.vutbr.cz/debian/ unstable main contrib non-free
deb-src http://merlin.fit.vutbr.cz/debian/ unstable main contrib non-free
```
You can replace **unstable** with **testing** or boring **stable** if you like - there might be some glithes if you do so as this install is focused on bleeding edge Debian.
You should also replace **merlin.fit.vutbr.cz** with your preferred repository mirror.

3) install all your ssh files into ~/.ssh of your regular user

# Install
You will need to somehow download files on your fresh Debian install. Preferred way is by cloning git repository.
Run as root
```
apt-get install git
git clone https://github.com/ondratra/sanager /opt/sanager
```

# Use
```
# use your actual username in following command
# following command is needed only once (will not break anything when run repeatedly)
YOUR_NON_ROOT_USERNAME=ondratra su -c ./rootInit.sh

# following command must be run as regular user($YOUR_NON_ROOT_USERNAME)
# it install all packages and restores all configurations from Sanager
sudo -E ./systemInstall.sh

# you can now restart pc(preferred) or start graphical interface via
lightdm
```
Running this script on regular user account with `sudo -E` ensuring your git keys, etc. will be available for the script.

## Logging
If you need to log system install run command with additional parameter `--verbose`.
```
sudo -E ./systemInstall.sh --verbose | tee systemInstall.log
```


## Notes
All scripts are meant to be non-destructive when run repeatedly.
Script has limited to no error handeling, when problem occurs fix it manually and update script.
All script are meant to be quite by default; messages to stderr are enabled always.
