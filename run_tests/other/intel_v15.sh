#! /bin/bash

PROD_DIR="/opt/intel/composer_xe_2015"

source $PROD_DIR/bin/compilervars.sh intel64

#=== MPI setting ===

#-- to use local installation of mpich-1 (to use with standard optfile):
#  PATH="/opt/intel/mpich-1.2.7p1_ic-14.0.0/bin:${PATH}"
#  MPI_INC_DIR="/opt/intel/mpich-1.2.7p1_ic-14.0.0/include"

#-  with mpich1, also need to put this in ./tcshrc (if unset) for mpirun
# #setenv LD_LIBRARY_PATH /opt/intel/composer_xe_2013_sp1/lib/intel64

#-- to use standard fc19 mpich (to use with specific optfile):
#  PATH="/usr/lib64/mpich/bin:${PATH}"
#  MPI_INC_DIR="/usr/include/mpich-x86_64"

#-- to use standard fc19 mpich with modified script mpicc,mpif77 & mpif90
#   (default setting changed to icc & ifort) to use with standard optfile:
  PATH="/opt/intel/mpich_fc21_mod4ic/bin:${PATH}"
  MPI_INC_DIR="/usr/include/mpich-x86_64"

export PATH
export MPI_INC_DIR

