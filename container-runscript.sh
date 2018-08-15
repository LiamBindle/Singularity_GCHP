#!/bin/bash
set -e

# Check if all mount-points are mounted
MOUNTED=true
for MOUNT in "/mnt/gc-source" "/mnt/gc-rundirs" "/mnt/gc-unittest" "/mnt/gc-extdata" ; do
    if ! grep -q $MOUNT /proc/mounts ; then
        MOUNTED=false
    fi
done

# Echo to STDERR
echo_err() {
    echo "$@" >&2
}

# Get the verb
if [ "$#" -eq 0 ] ; then
    VERB='help'
else
    VERB=$1
    shift
fi

# Write host RC file to STDOUT
rcfile() {
    # Parse arguments
    while getopts "s:e:u:r:" opt; do
        case $opt in
            s) GC_SOURCE=$OPTARG ;;     # GC source repo
            e) GC_EXTDATA=$OPTARG ;;    # External data location
            u) GC_UNITTEST=$OPTARG ;;   # GC unit testing repo
            r) GC_RUNDIRS=$OPTARG ;;    # Run directories parent
            \?)
                echo "Unknown option: -$OPTARG" >&2; exit 1
                ;;
        esac
    done
    
    # If any paths were omitted, assume user is trying to clear BINDPATH
    if [ -z "$GC_SOURCE" ] || [ -z "$GC_EXTDATA" ] || [ -z "$GC_UNITTEST" ] || [ -z "$GC_RUNDIRS" ] ; then
        echo 'SINGULARITY_BINDPATH='
    else
        echo 'SINGULARITY_BINDPATH=$(realpath '$GC_SOURCE'):/mnt/gc-source'
        echo 'SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,$(realpath '$GC_UNITTEST'):/mnt/gc-unittest'
        echo 'SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,$(realpath '$GC_EXTDATA'):/mnt/gc-extdata'
        echo 'SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,$(realpath '$GC_RUNDIRS'):/mnt/gc-rundirs'
    fi
    echo 'export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH'
    
    # Write ulimit settings
    echo 'ulimit -c unlimited'
    echo 'ulimit -l unlimited'
    echo 'ulimit -u 50000'
    echo 'ulimit -v unlimited'
}

# Edit CopyRunDirs.input and Makefile in /mnt/gc-unittest
bootstrap() {
    if [ "$MOUNTED" = false ] ; then
        echo_err "(error) Container has not been mounted."
        exit 1
    fi
    if [ "$#" -gt 0 ] ; then
        echo_err "(error) Unexpected arguments: $@"
        exit 1
    fi
    echo_err '(info) Bootstrapping the container...'
    set -x
    sed -i 's#\(GCGRID_ROOT\s*:\s*\)[$(){}\w\/\-].*#\1/mnt/gc-extdata#g' /mnt/gc-unittest/perl/CopyRunDirs.input
    sed -i 's#\(DATA_ROOT\s*:\s*\)[$(){}\w\/\-].*#\1/mnt/gc-extdata#g' /mnt/gc-unittest/perl/CopyRunDirs.input
    sed -i 's#\(UNIT_TEST_ROOT\s*:\s*\)[$(){}\w\/\-].*#\1/mnt/gc-unittest#g' /mnt/gc-unittest/perl/CopyRunDirs.input
    sed -i 's#\(COPY_PATH\s*:\s*\)[$(){}\w\/\-].*#\1/mnt/gc-rundirs#g' /mnt/gc-unittest/perl/CopyRunDirs.input
    sed -i 's#\(CODE_DIR\s*:=\s*\)[$(){}\w\/\-].*#\1/mnt/gc-source#g' /mnt/gc-unittest/perl/Makefile
    set +x
    echo_err '(info) Finished.'
}


setup() {
    if [ "$MOUNTED" = false ] ; then
        echo_err "(error) Container has not been mounted."
        exit 1
    fi
    if [ "$#" -gt 0 ] ; then
        echo_err "(error) Unexpected arguments: $@"
        exit 1
    fi
    echo_err '(info) Running gcCopyRunDirs'
    set +x
    cd /mnt/gc-unittest/perl
    ./gcCopyRunDirs
    set -x
}

usage() {
    echo 'usage: singularity run gc.simg <action|rundir> [options...]'
    echo '    actions:'
    echo '        rcfile [options...]    Outputs an RC file to setup the HOST system'
    echo '                                environment.'
    echo '            options:'
    echo '                -s <path to GEOS-Chem source code repo>'
    echo '                -u <path to GEOS-Chem unit testing repo>'
    echo '                -e <path to ExtData folder>'
    echo '                -r <path to the parent directory for run dirs>'
    echo ''
    echo '        bootstrap              Configures CopyRunDirs.input and Makefile in UT'
    echo '                                 for use with the container.'
    echo ''
    echo '        setup                  Creates the run directory by running'
    echo '                                gcCopyRunDirs.'
    echo ''
    echo '        checkout [options...]  Calls git checkout in source and UT repositories.'
    echo '            options:'
    echo '                All options are passed to git checkout [options...]'
    echo ''
    echo '        help                    Prints usage documentation (prints this).'
    echo ''
    echo '    rundir:'
    echo '        <rundir> <command>     Runs <command> in your <rundir>.'
    echo ''
}

run() {
    # First argument is the run directory 
    if [ "$#" -lt 1 ] ;  then
        usage
        exit 1
    else
        RUNDIR=$1
        shift
    fi

    RUNDIR=/mnt/gc-rundirs/$RUNDIR

    if [ ! -d "$RUNDIR" ] ; then
        echo "(error) Run directory $RUNDIR does not exist."
        exit 1
    fi

    # Run the given commands
    set -x
    cd $RUNDIR
    exec "$@"
    set +x
}

case $VERB in
    rcfile) rcfile $@ ;;
    bootstrap) bootstrap $@ ;;
    setup) setup ;;
    checkout) 
        cd /mnt/gc-source
        git checkout $@
        cd /mnt/gc-unittest
        git checkout $@
        ;;
    help) usage ;;  
    *) run $VERB $@ ;;
esac


