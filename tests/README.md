# Sanager tests

## Run
Make sure you have ~50GB of free disk space before running the tests.

```bash
# cd sanagerRoot

# install prerequisities
sudo -E ./systemInstall.sh lowLevel pkg_sanager_tests_prerequisities

./tests/scripts/virtualBoxMachineInstall.sh

# alternatively log everything into file
./tests/scripts/virtualBoxMachineInstall.sh >tmp.txt 2>&1

```

### Custom VM folder
By default, Sanager creates VMs inside of `./.sanagerTests` folder. The content of this folder might get very large. 
In case you need to change it, create a symlink pointing to your desired path at `./.sanagerTests`.
```bash
ln -s /my/desired/path .sanagerTests
```

## Fork test VM and build upon it
Firstly, make sure to run tests. Then adjust and run the following command to fork the desired VM and save it
to selected folder while adjusting it's SSH and VDRE ports.
```bash
./tests/scripts/vmMaker Sanager_Testing_Runner_1_Unstable_pc Sanager_MySpecificUse 2223 10002 /path/to/virtual/machines
```
