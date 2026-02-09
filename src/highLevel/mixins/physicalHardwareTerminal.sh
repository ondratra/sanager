function mixin_physicalHardwareTerminal_all {
    mixin_physicalHardwareTerminal_drivers
    mixin_physicalHardwareTerminal_cooling
    mixin_physicalHardwareTerminal_virtualization
}

function mixin_physicalHardwareTerminal_drivers {
    if isVirtualMachine; then # physicalHardware in VM does makes sense during testing
        return
    fi

    # TODO: make cpu and gpu vendors configurable(?)
    pkg_amdCpuDrivers
    pkg_amdGpuDrivers
}

function mixin_physicalHardwareTerminal_cooling {
    pkg_hardwareSensors
    effect_setupTempSensors

    pkg_corectrl
    pkg_coolercontrol
}

function mixin_physicalHardwareTerminal_virtualization {
    if isVirtualMachine; then # don't install virtualization recursivelly - at minimum networks will conflict
       return
    fi

    #pkg_virtualbox # TODO: temporary disabled because package is not available in Debian 13 Trixie
    pkg_sanager_tests_prerequisities
}
