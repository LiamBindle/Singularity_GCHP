Bootstrap: docker
From: centos:centos7

%post
    # Setup system
    yum -y update
    yum -y install centos-release-scl                               # Additional repositories
    yum -y install devtoolset-7-gcc-gfortran devtoolset-7-gcc-c++   # GNU compilers 7.x
    yum -y install make git file tar curl vim file m4               # More tools
    yum clean all
    
    # Enable devtoolset-7
    source /opt/rh/devtoolset-7/enable

    # Build dependencies (zlib, HDF5, NetCDF-C, NetCDF-Fortran, Open MPI)
    cd /tmp
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

    # Build zlib
    ZLIB_VERSION=1.2.11
    curl -L https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz -o zlib-${ZLIB_VERSION}.tar.gz
    tar -xf zlib-${ZLIB_VERSION}.tar.gz
    cd zlib-${ZLIB_VERSION}
    ./configure --prefix=/usr/local
    make -j4
    make install
    cd /tmp

    # Build HDF5
    HDF5_MAJOR=1.10
    HDF5_MINOR=2
    HDF5_VERSION=${HDF5_MAJOR}.${HDF5_MINOR}
    curl -L https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_MAJOR}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz -o hdf5-${HDF5_VERSION}.tar.gz
    tar -xf hdf5-${HDF5_VERSION}.tar.gz
    cd hdf5-${HDF5_VERSION}
    ./configure --prefix=/usr/local
    make -j4
    make install
    cd /tmp

    # Build NetCDF-C
    NETCDF_C_VERSION=4.6.1
    curl -L https://github.com/Unidata/netcdf-c/archive/v${NETCDF_C_VERSION}.tar.gz -o netcdf-c-${NETCDF_C_VERSION}.tar.gz
    tar -xf netcdf-c-${NETCDF_C_VERSION}.tar.gz
    cd netcdf-c-${NETCDF_C_VERSION}
    ./configure --prefix=/usr/local --disable-dap
    make -j4
    make install
    cd /tmp

    # Build NetCDF-Fortran
    NETCDF_F_VERSION=4.4.4
    curl -L https://github.com/Unidata/netcdf-fortran/archive/v${NETCDF_F_VERSION}.tar.gz -o netcdf-fortran-${NETCDF_F_VERSION}.tar.gz
    tar -xf netcdf-fortran-${NETCDF_F_VERSION}.tar.gz
    cd netcdf-fortran-${NETCDF_F_VERSION}
    ./configure --prefix=/usr/local
    make -j4
    make install
    cd /tmp

    # Build Open MPI
    OMPI_MAJOR=2.1
    OMPI_MINOR=2
    OMPI_VERSION=${OMPI_MAJOR}.${OMPI_MINOR}
    curl -L https://www.open-mpi.org/software/ompi/v${OMPI_MAJOR}/downloads/openmpi-${OMPI_VERSION}.tar.gz -o /tmp/openmpi-${OMPI_VERSION}.tar.gz
    tar -xf openmpi-${OMPI_VERSION}.tar.gz
    cd openmpi-${OMPI_VERSION}
    ./configure --prefix=/usr/local
    make -j4
    make install

    # Additional setup
    cd /
    rm -rf /tmp/*
    ln -s /usr/lib64/gfortran/modules/netcdf.mod /usr/include/netcdf.mod
    mkdir /mnt/gc-extdata /mnt/gc-source /mnt/gc-unittest /mnt/gc-rundirs
    chmod a+rw /mnt/gc-*
 
%environment
    source scl_source enable devtoolset-7
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

    export FC=gfortran
    export F77=$FC
    export F90=$FC
    export OMPI_FC=$FC
    export COMPILER=$FC
    export ESMF_COMPILER=$FC
   
    export CC=gcc
    export OMPI_CC=$CC

    export CXX=g++
    export OMPI_CXX=$CXX
    export NETCDF_HOME=/usr
    export NETCDF_FORTRAN_HOME=/usr

    export GC_BIN=$NETCDF_HOME/bin
    export GC_INCLUDE=$NETCDF_HOME/include
    export GC_LIB=$NETCDF_HOME/lib64

    export GC_F_BIN=$GC_BIN
    export GC_F_INCLUDE=$GC_INCLUDE
    export GC_F_LIB=$GC_LIB

    export ESMF_COMM=openmpi
    export MPI_ROOT=/usr/local
    export ESMF_BOPT=O
    
%files
    container-runscript.sh /usr/local/bin/

%runscript
    exec /usr/local/bin/container-runscript.sh "$@" 
