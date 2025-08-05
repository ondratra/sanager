# Sanager - System Manager

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

Installs all applications and libraries used by autor on local computer. Script targets Debian unstable distribution
but should provide similar(hopefully identical) environmnent on all Debian-based distributions.

# Prerequisites
1) Install minimal Debian distribution (known as "net install") from https://www.debian.org/CD/http-ftp/ .
More robust installation medium is also ok.

2) Put this to /etc/apt/sources.list
```
deb http://merlin.fit.vutbr.cz/debian/ unstable main contrib non-free-firmware
deb-src http://merlin.fit.vutbr.cz/debian/ unstable main contrib non-free-firmware
```
You can replace **unstable** with **testing** or boring **stable** if you like - there might be some glithes if you do so as this install is focused on bleeding edge Debian.
You should also replace **merlin.fit.vutbr.cz** with your preferred repository mirror.

3) install all your ssh files into ~/.ssh of your regular user

# Install
You will need to somehow download files on your fresh Debian install. Preferred way is by cloning git repository.
Run as root
```sh
apt-get install git
git clone https://github.com/ondratra/sanager /opt/sanager
```

## Install globally
To install sanager globally to the local system run:
```sh
sudo -E ./sanager.sh lowLevel installSanagerGlobally
```

After that, you can use `sanager` anywhere instead of `./systemInstall.sh`.


# Use
```sh
# use your actual username in following command
# following command is needed only once (will not break anything when run repeatedly)
NON_ROOT_USERNAME=ondratra su -c ./rootInit.sh

# following command must be run as regular user($NON_ROOT_USERNAME)
# it install all packages and restores all configurations from Sanager
# you can select from various bluenprints in 1st parameter('pc' in example)
sudo -E ./systemInstall.sh pc


# you can now restart pc(preferred) or start graphical interface via
lightdm
```sh
Running this script on regular user account with `sudo -E` ensuring your git keys, etc. will be available for the script.

## Logging
If you need to log system install run command with additional parameter `--verbose`.
```sh
sudo -E ./systemInstall.sh pc --verbose |& sudo -E tee systemInstall.log
```


## Notes
All scripts are meant to be non-destructive when run repeatedly.
Script has limited to no error handeling, when problem occurs fix it manually and update script.
All script are meant to be quite by default; messages to stderr are enabled always.

# Troubleshooting
When somethings goes wrong try to rerun `systemInstall.sh`.
Additionally you can delete content of some config folders before rerun.
```sh
rm -rf /etc/apt/sources.list.d/__sanager*
rm -rf /opt/__sanager/*
# or selectively
rm -rf /opt/__sanager/install
rm -rf /opt/__sanager/gpgKeys
rm -rf /opt/__sanager/tmp

```

# Updating configuration

## Mate
```sh
# export Mate configuration
./utilities/exportMateConfig.sh
# this dumps the current profile; if you need to dump the old backup, you can set the db path by prepending `DCONF_PROFILE=~/oldMateBackupPath`

# import Mate configuration
sudo -E ./systemInstall.sh lowLevel restoreMateConfig
```
After export, commit changes to git.

Running one of the high-level installs via `systemInstall.sh` also sets Mate configuration to state saved in Sanager.
This process might be destructive if you made changes to your Mate and didn't update them in Sanager files.





TODO:
http://guacamole.incubator.apache.org/
https://discussion.dreamhost.com/thread-133929

