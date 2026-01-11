# Sanager tests

## Run
Make sure you have ~50GB of free disk space before running the tests.

```bash
# cd sanagerRoot
./tests/virtualBoxMachineInstall.sh

# alternatively log everything into file
./tests/virtualBoxMachineInstall.sh >tmp.txt 2>&1

```

### Prerequisities
Since creating installation medium is not yet working you need to create a bare VM with OS installed manually.
This needs to be done only once. Look into `buildRoutines.vmWithOs` to see what needs to be done.

To create such VM, first run `virtualBoxMachineInstall.sh` as described above. It will result in an error, but that's
expected. Then go to VirtualBox GUI and manually duplicate/clone the `Sanager_Testing_Bare` VM to a new one called
`Sanager_Testing_WithOS`. After that manually install OS into that VM and then you can run `virtualBoxMachineInstall`
once again. Rest of the VMs should be created automatically without problems.

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
./tests/vmMaker Sanager_Testing_Runner_1_Unstable_pc Sanager_MySpecificUse 2223 10002 /path/to/virtual/machines
```
