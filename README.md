# Sanager - System Manager
Installs all applications and libraries used by autor on local computer. Creates (almost) identical enviroments
on all Debian-like distributions.


# Use
`sudo -E ./systemInstall.sh`
run this script on regular user account with -E ensures your git keeps, etc. will be available


## Not handeled by this script
- running `sudo apt-get update` before script
- enabling sudo for user; run `adduser yourNonRootUserName sudo` as root manually

## Notes
script is meant to be non-destructive when run repeatedly
script has no fail handeling, when problem occurs fix it manually and update script
