# Sanager - System Manager

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

Installs all applications and libraries used by autor on local computer. Creates (almost) identical enviroments
on all Debian-like distributions.


# Use
```
sudo -E ./systemInstall.sh`
```
Run this script on regular user account with -E ensuring your git keys, etc. will be available


## Not handeled by this script
- running `sudo apt-get update` before script
- enabling sudo for user; run `adduser yourNonRootUserName sudo` as root manually

## Notes
script is meant to be non-destructive when run repeatedly
script has no fail handeling, when problem occurs fix it manually and update script
