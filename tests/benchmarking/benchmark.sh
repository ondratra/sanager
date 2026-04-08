function benchmark {
    benchmarkCpu
    benchmarkMemory
    benchmarkGpu
    benchmarkDisks
}

function benchmarkCpu {
    echo "CPU"

    local SYSBENCH_OUTPUT=$(sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run)

    local EVENTS_PER_SECOND=$(echo "$SYSBENCH_OUTPUT" | awk '/events per second/{print $NF}')

    echo "Sysbench events per second: $EVENTS_PER_SECOND"
}

function benchmarkMemory {
    echo "Memory"

    local CPU_CORES=$(nproc)

    local RESULT_WRITE=$(
        sysbench memory \
            --memory-block-size=1M \
            --memory-total-size=50G \
            --memory-oper=write \
            --threads="$CPU_CORES" run 2>/dev/null \
        | awk '/transferred/{gsub(/[^0-9.]/,"",$4); print $4}'
    )

    local RESULT_READ=$(
        sysbench memory \
            --memory-block-size=1M \
            --memory-total-size=50G \
            --memory-oper=read \
            --threads="$CPU_CORES" run 2>/dev/null \
        | awk '/transferred/{gsub(/[^0-9.]/,"",$4); print $4}'
    )

    local RESULT_AVG=$(mbw -t 0 -n 3 2048 2>/dev/null | awk '/^AVG.*MEMCPY/ {print $(NF-1)}')

    echo "  Sequential write (sysbench): ${RESULT_WRITE} MiB/s"
    echo "  Sequential read  (sysbench): ${RESULT_READ} MiB/s"
    echo "  Memory copy (mbw): ${RESULT_AVG} MiB/s"
}

function benchmarkGpu {
    echo "GPU"

    # TODO: this is unreliable and in some systems choses CPU over GPU because order of devices is not guaranteed and CPU is sometimes first one
    local HASHCAT_SCORE=$(hashcat -b --hash-type=1400 --machine-readable 2>/dev/null | awk -F: '/^1:1400:/{printf "%.0f", $6/1000000}')
    echo "  hashcat SHA-256: $HASHCAT_SCORE MH/s"

    # TODO: glmark values doesn't make much sense and it doesn't fully use GPU; let's skip it for now
    #local GLMARK_SCORE=$(glmark2-drm --off-screen 2>/dev/null | awk '/glmark2 Score/{print $NF}')
    #echo "  glmark2: $GLMARK_SCORE"

    # TODO: clpeak needs to select proper device, let's leave it for next time
    #local CLPEAK_OUTPUT=`clpeak --compute-sp --global-bandwidth`
    #local CLPEAK_BANDWIDTH=$(echo "$CLPEAK_OUTPUT" | grep -A5 "Global memory bandwidth" | grep "float " | awk '{print $NF}' | head -1)
    #local CLPEAK_COMPUTE=$(echo "$CLPEAK_OUTPUT" | grep -A5 "Single-precision compute" | grep "float " | awk '{print $NF}' | head -1)

    #echo "clpeak score: bandwidth $CLPEAK_BANDWIDTH GB/s, compute $CLPEAK_COMPUTE GFLOPS"
}

function benchmarkDisks {
    # TODO: implement
    #fio --name=rand-read --rw=randread --bs=4K --size=4G --numjobs=4 --runtime=30 --time_based --iodepth=32 --ioengine=libaio --direct=1
    #fio --name=rand-write --rw=randwrite --bs=4K --size=4G --numjobs=4 --runtime=30 --time_based --iodepth=32 --ioengine=libaio --direct=1
    #fio --name=mixed --rw=randrw --rwmixread=70 --bs=4K --size=4G --numjobs=4 --runtime=30 --time_based --iodepth=32 --ioengine=libaio --direct=1
}
