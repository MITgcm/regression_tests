#!/bin/bash
#SBATCH -J tst_pgiAdm
#SBATCH -p fdr
#SBATCH -t 6:00:00
#SBATCH --mem-per-cpu 4000
#SBATCH -N 1
#SBATCH --tasks-per-node 6
#SBATCH -e /home/jm_c/test_svante/output/tst_pgiAdm.stderr
#SBATCH -o /home/jm_c/test_svante/output/tst_pgiAdm.stdout

# $Header: /u/gcmpack/MITgcm_contrib/test_scripts/svante/test_svante_pgi_mpi,v 1.5 2016/12/29 22:05:32 jmc Exp $
# $Name:  $

if test -f /etc/profile.d/modules.sh    ; then . /etc/profile.d/modules.sh    ; fi
if test -f /etc/profile.d/zz_modules.sh ; then . /etc/profile.d/zz_modules.sh ; fi
# Note: added "ulimit -s unlimited" in file "~/.bashrc"
# to pass big test (the 2 fizhi-cs-* test & adjoint tests) with MPI

umask 0022
#- to get case insensitive "ls" (and order of tested experiments)
export LC_ALL="en_US.UTF-8"
echo " running on: "`hostname`
headNode='svante-login'

dNam='svante'
HERE="$HOME/test_${dNam}"
OUTP="$HERE/output"; SavD="$HERE/send"
SEND="ssh $headNode $SavD/mpack"
TST_DISK="/net/fs09/d0/jm_c"
TST_DIR="$TST_DISK/test_${dNam}"

cd $TST_DISK ; pwd
if test -d $TST_DIR ; then
  echo "start from TST_DIR='$TST_DIR' at: "`date`
else
  echo "ERROR: missing directory \"$TST_DIR\""
  exit 1
fi

sfx='pgiAdm'; typ='-adm'
addExp=''
 module add pgi/16.9
 module add openmpi
 module add netcdf
 OPTFILE="../tools/build_options/linux_amd64_pgf77"
#- needed for DIVA with MPI:
 export MPI_INC_DIR="/home/software/pgi/16.9/linux86-64/2016/mpi/openmpi-1.10.2/include"
 options="$typ -MPI 6"
#- need this to get "staf":
#export PATH="$PATH:$HOME/bin"

#dAlt=`date +%d` ; dAlt=`expr $dAlt % 3`
#if [ $dAlt -eq 1 ] ; then options="$options -fast"
#else options="$options -devel" ; fi

NSLOTS=$SLURM_NTASKS
THEDATE=`date`
echo '********************************************************************************'
echo 'Start job '$THEDATE
echo 'NSLOTS = '$NSLOTS
echo '======= NODELIST ==============================================================='
echo $SLURM_NODELIST
cat /etc/redhat-release
echo '======= env ===================================================================='
env | grep SLURM
echo '======= modules ================================================================'
module list 2>&1
echo '================================================================================'

gcmDIR="MITgcm_$sfx"
cd $TST_DIR

#- check for disk space: relative space (99%) or absolute (10.G):
dsp=`df -P . | tail -1 | awk '{print $5}' | sed 's/%$//'`
if [ $dsp -gt 99 ] ; then
#dsp=`df -P . | tail -1 | awk '{print $4}'`
#if [ $dsp -le 100000000 ] ; then
  echo 'Not enough space on this disk => do not run testreport.'
  df .
  exit
fi

#- change dir to $gcmDIR/verification dir:
if test -e $gcmDIR/verification ; then
  if [ $checkOut -lt 2 ] ; then
    echo " dir $gcmDIR/verification exist" ; fi
  cd $gcmDIR/verification
else
  echo "no dir: $gcmDIR/verification => exit"
  exit
fi

#- get option -devel/-fast from head-node testreport output:
options="$options -q"
prevName=`grep '^on :' tr_out.txt | awk '{print $4}'`
if test "x$prevName" = "x$headNode" ; then
  dev_Opt=`grep '^run:' tr_out.txt | grep -c ' -devel'`
  fastOpt=`grep '^run:' tr_out.txt | grep -c ' -fast'`
  if test $dev_Opt = 1 -a $fastOpt = 0 ; then
    options="$options -devel"
  fi
  if test $dev_Opt = 0 -a $fastOpt = 1 ; then
    options="$options -fast"
  fi
else
  echo " missing previous testreport output "tr_out.txt" from $headNode"
  echo ' skip addition of -devel/-fast to $options'
fi

echo ''
echo ./testreport $options -of $OPTFILE -odir ${dNam}-$sfx \
  -send \"$SEND\" -sd $SavD -a jmc@mitgcm.org
./testreport $options -of $OPTFILE -odir ${dNam}-$sfx \
  -send "$SEND" -sd $SavD -a jmc@mitgcm.org

#echo ''
#echo ../tools/do_tst_2+2 -mpi -o ${dNam}-$sfx \
#  -send \"$SEND\" -sd $SavD -a jmc@mitgcm.org
#../tools/do_tst_2+2 -mpi -o ${dNam}-$sfx \
#  -send "$SEND" -sd $SavD -a jmc@mitgcm.org

