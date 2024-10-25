# Sanager tests

## Run
Make sure you have ~50GB of free disk space before running the tests.

```
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
