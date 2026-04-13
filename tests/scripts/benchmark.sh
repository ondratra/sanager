#!/bin/bash

set -euo pipefail

# ensure root is running this script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SCRIPT_DIR="`dirname \"$0\"`" # relative

source "$SCRIPT_DIR/../config.sh"
source "$SANAGER_MAIN_DIR/src/lowLevel/utilities.sh"
source "$SCRIPT_DIR/../misc/utils.sh"
source "$SCRIPT_DIR/../benchmarking/systeminfo.sh"
source "$SCRIPT_DIR/../benchmarking/benchmark.sh"

REQUIRED_PACKAGES=`listBenchmarkingDependencies`
ensurePackagesAreInstalled $REQUIRED_PACKAGES || { log "Prerequisities missing! Install them with pkg_benchmarkingPrerequisities"; exit 1; }

function main {
   echo "Collecting system info"
   systeminfo
   echo
   echo "Starting benchmark"
   benchmark
}

main
