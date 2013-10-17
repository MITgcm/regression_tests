#! /bin/bash

PROD_DIR="/opt/intel/composerxe-2011"
if [ -z "${PATH}" ]
then
    PATH="$PROD_DIR/bin";
else
    PATH="$PROD_DIR/bin:${PATH}";
fi
    PATH="/opt/intel/mpich-1.2.7p1_ic-12.0.4/bin:${PATH}"
    export PATH
    MPI_INC_DIR="/opt/intel/mpich-1.2.7p1_ic-12.0.4/include"
    export MPI_INC_DIR

  if [ -z "${LD_LIBRARY_PATH}" ]
   then
       LD_LIBRARY_PATH="$PROD_DIR/lib/intel64"
   else
       LD_LIBRARY_PATH="$PROD_DIR/lib/intel64:${LD_LIBRARY_PATH}"
   fi
   export LD_LIBRARY_PATH

   if [ -z "${LIBRARY_PATH}" ]
   then
       LIBRARY_PATH="$PROD_DIR/lib/intel64"
   else
       LIBRARY_PATH="$PROD_DIR/lib/intel64:${LIBRARY_PATH}"
   fi
   export LIBRARY_PATH
   if [ -z "${NLSPATH}" ]
   then
     NLSPATH="$PROD_DIR/lib/intel64/locale/%l_%t/%N"
   else
     NLSPATH="$PROD_DIR/lib/intel64/locale/%l_%t/%N:${NLSPATH}"
   fi
   export NLSPATH

if [ -z "${MANPATH}" ]
then
    MANPATH="$PROD_DIR/man/en_US":$(manpath)
else
    MANPATH="$PROD_DIR/man/en_US:${MANPATH}"
fi
export MANPATH

if [ -z "${INTEL_LICENSE_FILE}" ]
then
  INTEL_LICENSE_FILE="/opt/intel/licenses"
else
  INTEL_LICENSE_FILE="${INTEL_LICENSE_FILE}:/opt/intel/licenses"
fi
export INTEL_LICENSE_FILE

