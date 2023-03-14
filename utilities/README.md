# Useful commands
WIP

## Misc
See used ports
```
netstat -tulpn
```

Generate SSH key
```
ssh-keygen -t rsa -b 4096 -f myKey
```

## Package management

Get package that installed the inspected file/command
```
dpkg -S /usr/bin/vim
```

Mark package as manually installed:
```
sudo apt-mark manual my-package-name
```
or mark it as automatically installed (may remove package if no other package depends on it)
```
sudo apt-mark auto my-package-name
```

See what packages depend on selected package
```
apt-cache rdepends my-package-name
```

List *non-free* packages and packages that rely on *non-free* packages (aka *contrib*)
```
aptitude search '~i ?section(non-free)
aptitude search '~i ?section(contrib)
```
