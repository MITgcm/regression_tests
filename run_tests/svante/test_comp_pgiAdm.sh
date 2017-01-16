#! /usr/bin/env bash

# $Header: /u/gcmpack/MITgcm_contrib/test_scripts/svante/test_comp_pgiAdm.sh,v 1.3 2017/01/15 17:32:16 jmc Exp $

#  Test script for MITgcm to run on head-node of svante cluster (svante-login.mit.edu)
#   to just generate source code (*.f) including TAF output src code.

headNode=`hostname -s`
#QSUB="qsub"
#QSTAT="qstat -u $USER"
#dNam=$headNode
QSUB="/usr/bin/sbatch"
#QSTAT="/usr/bin/qstat -u $USER"
QLIST="/usr/bin/squeue -u $USER"
dNam='svante'
HERE="$HOME/test_${dNam}"

SUB_DIR="$HERE/$dNam"
OUT_DIR="$HERE/output"
TST_DISK="/net/fs09/d0/jm_c"
TST_DIR="$TST_DISK/test_${dNam}"
#SUB_DIR="$HERE/temp"

dInWeek=`date +%a`
TODAY=`date +%d`

#- main options
sfx='pgiAdm'; typ='-adm'
addExp=''

logPfix="test_comp_$sfx"
BATCH_SCRIPT="run_tst_${sfx}.slurm"
#- job name ($JOB) & output-file name ( $JOB.std??? ) must match
#  definition within $BATCH_SCRIPT slurm script
JOB="tst_$sfx"
sJob=`printf "%8.8s" $JOB` #- squeue truncate name to only 1rst 8c

#-------------------------------
# checkOut=2 : download new code ;
#   =1 : update code       (if no existing code -> swith to 2)
#   =0 : use existing code (if no existing code -> swith to 2)
checkOut=1
option=

#option="-nc" ; checkOut=1
#option="-q"  ; checkOut=0

dAlt=`date +%d` ; dAlt=`expr $dAlt % 3`
if [ $dAlt -eq 1 ] ; then options="$options -fast"
else options="$options -devel" ; fi

#- defaults
umask 0022
if [ -d ~/bin ]; then export PATH=$PATH:~/bin ; fi
#- to get case insensitive "ls" (and order of tested experiments)
export LC_ALL="en_US.UTF-8"
#  Turn off stack limit for FIZHI & AD-tests
ulimit -s unlimited

if test -f /etc/profile.d/modules.sh    ; then . /etc/profile.d/modules.sh    ; fi
if test -f /etc/profile.d/zz_modules.sh ; then . /etc/profile.d/zz_modules.sh ; fi

#- method to acces CVS:
cmdCVS='cvs -d :pserver:cvsanon@mitgcm.org:/u/gcmpack -q'

#-- clean up old log files and start a new one:
LOG_FIL="$OUT_DIR/$logPfix."`date +%m%d`".log"
cd $OUT_DIR

rm -f $logPfix.*.log_bak
if test -f $LOG_FIL ; then mv -f $LOG_FIL ${LOG_FIL}_bak ; fi
echo -n '-- Starting: '                                 | tee -a $LOG_FIL
date                                                    | tee -a $LOG_FIL

n=$(( `ls $logPfix.*.log | wc -l` - 10 ))
if test $n -gt 0 ; then
  echo ' remove old log files:'                         | tee -a $LOG_FIL
    ls -lt $logPfix.*.log | tail -"$n"                  | tee -a $LOG_FIL
    ls -t  $logPfix.*.log | tail -"$n" | xargs rm -f
fi

#- load standard modules:
 module add slurm

#- load specific modules & set ENV variables:
 module add pgi/16.9
 module add openmpi
 module add netcdf
 OPTFILE="../tools/build_options/linux_amd64_pgf77"
 MPI=6
#- needed for DIVA with MPI:
 export MPI_INC_DIR="/home/software/pgi/16.9/linux86-64/2016/mpi/openmpi-1.10.2/include"

echo '======= modules ======================================='	| tee -a $LOG_FIL
module list 2>&1						| tee -a $LOG_FIL
echo '======================================================='	| tee -a $LOG_FIL

dInWeek=`date +%a`
TODAY=`date +%d`
#tst_list='gads gadm gfo+rs gmpi gmth gmp2+rs ifc pgi'
#if test "x$dInWeek" = xSun ; then tst_list="$tst_list tlm oad" ; fi
tst_list='pgiAdm'

echo "cd $TST_DISK ; pwd (x2)"					| tee -a $LOG_FIL
cd $TST_DISK 2>&1						| tee -a $LOG_FIL
pwd								| tee -a $LOG_FIL
if test ! -d $TST_DIR ; then
   echo -n "Creating a working dir: $TST_DIR ..."		| tee -a $LOG_FIL
  #/bin/rm -rf $TST_DIR
   mkdir $TST_DIR
   retVal=$?
   if test "x$retVal" != x0 ; then
      echo "Error: unable to make dir: $TST_DIR (err=$retVal ) --> Exit" | tee -a $LOG_FIL
      exit 1
   fi
fi
cd $TST_DIR
pwd								| tee -a $LOG_FIL

#------------------------------------------------------------------------

  echo "================================================================"
  gcmDIR="MITgcm_$sfx"

  #- check day and time:
  curDay=`date +%d` ; curHour=`date +%H`
  if [ $curDay -ne $TODAY ] ; then
    date ; echo "day is over => skip test $sfx"			| tee -a $LOG_FIL
    exit 2
  fi
  if [ $curHour -ge 18 ] ; then
    date ; echo "too late to run test $sfx"			| tee -a $LOG_FIL
    exit 2
  fi
  #- check for unfinished jobs
  #job_exist=`$QSTAT | grep $JOB | wc -l`
  job_exist=`$QLIST | grep $sJob | wc -l`
  if test "x$job_exist" != x0 ; then
    echo $BATCH_SCRIPT						| tee -a $LOG_FIL
    echo "job '$JOB' still in queue:"				| tee -a $LOG_FIL
    #$QSTAT | grep $JOB						| tee -a $LOG_FIL
    $QLIST | grep $sJob						| tee -a $LOG_FIL
    echo " => skip this test"					| tee -a $LOG_FIL
    exit 2
  fi
  #-- move previous output file
  outList=`( cd $OUT_DIR ; ls $JOB.std??? 2> /dev/null )`
  if test "x$outList" != x ; then
    echo -n " moving job $JOB old output files:"	| tee -a $LOG_FIL
    if test -d $OUT_DIR/prev ; then
      for xx in $outList ; do
        pp=$OUT_DIR/prev/$xx ; echo -n " $xx"		| tee -a $LOG_FIL
        test -f $pp.sav && mv -f $pp.sav $pp.old
        test -f $pp     && mv -f $pp     $pp.sav
        chmod a+r $OUT_DIR/$xx ; mv -f $OUT_DIR/$xx $OUT_DIR/prev
      done
      echo " to dir ./prev"				| tee -a $LOG_FIL
    else
      echo " <-- missing dir $OUT_DIR/prev"		| tee -a $LOG_FIL
    fi
  else echo " no old output files from job '$JOB'"	| tee -a $LOG_FIL
  fi
  if test -d prev ; then
    #-- save previous summary: tr_out.txt* tst_2+2_out.txt
    oldS=`( cd ${gcmDIR}/verification ; ls t*_out.txt* ) 2> /dev/null`
    for xx in $oldS ; do
     #ss=`/bin/ls -l ${gcmDIR}/verification/$xx | awk '{print $6 $7}'`
      ss=`/bin/ls -l --time-style=iso ${gcmDIR}/verification/$xx | awk '{print $6}'`
      yy=`echo $xx | sed -e "s/\.txt.old/.$sfx.c/" \
          -e "s/2_out.txt/2.$sfx./" -e "s/\.txt/.$sfx.r/"`
      cp -p ${gcmDIR}/verification/$xx prev/${yy}$ss
    done
  fi

  #- clean and update code
  if [ $checkOut -eq 1 ] ; then
    if test -d $gcmDIR/CVS ; then
      echo "cleaning output from $gcmDIR/verification :"	| tee -a $LOG_FIL
  #- remove previous output tar files and tar & remove previous output-dir
      /bin/rm -f $gcmDIR/verification/??_${dNam}*_????????_?.tar.gz
      ( cd $gcmDIR/verification
        listD=`ls -1 -d tr_${headNode}_????????_? ??_${dNam}-${sfx}_????????_? 2> /dev/null`
        for dd in $listD
        do
          if test -d $dd ; then
            tar -cf ${dd}".tar" $dd > /dev/null 2>&1 && gzip ${dd}".tar" && /bin/rm -rf $dd
            retVal=$?
            if test "x$retVal" != x0 ; then
               echo "ERROR in tar+gzip prev outp-dir: $dd"
               echo " on '"`hostname`"' (return val=$retVal) but continue"
            fi
          fi
        done )
#       ( cd $gcmDIR/verification ; ../tools/do_tst_2+2 -clean ) >> $LOG_FIL 2>&1
        ( cd $gcmDIR/verification ; ./testreport $typ -clean ) >> $LOG_FIL 2>&1
      echo "cvs update of dir $gcmDIR :"			| tee -a $LOG_FIL
      ( cd $gcmDIR ; $cmdCVS update -P -d ) >> $LOG_FIL 2>&1
      retVal=$?
      if test "x$retVal" != x0 ; then
        echo "cvs update on '"`hostname`"' fail (return val=$retVal) => exit"
        exit 3
      fi
    else
      echo "no dir: $gcmDIR/CVS => try a fresh check-out"	| tee -a $LOG_FIL
      checkOut=2
    fi
  fi
  #- download new code
  if [ $checkOut -eq 2 ] ; then
    test -e $gcmDIR && rm -rf $gcmDIR
    echo -n "Downloading the MITgcm code using: $cmdCVS ..."	| tee -a $LOG_FIL
    $cmdCVS co -P -d $gcmDIR MITgcm > /dev/null
    echo "  done"						| tee -a $LOG_FIL
    for exp2add in $addExp ; do
     echo " add dir: $exp2add (from Contrib:verification_other)"| tee -a $LOG_FIL
     ( cd $gcmDIR/verification ; $cmdCVS co -P -d $exp2add \
                MITgcm_contrib/verification_other/$exp2add > /dev/null 2>&1 )
    done
    /usr/bin/find $gcmDIR -type d | xargs chmod g+rxs
    /usr/bin/find $gcmDIR -type f | xargs chmod g+r
  fi
#---------------------------------------------------
#-- set the testreport command:
  comm="./testreport $typ"

#-- run the testreport command:
  echo -n "Running testreport using"	| tee -a $LOG_FIL
  if test $MPI != 0 ; then comm="$comm -MPI $MPI" ; fi
  if test "x$options" != x ; then comm="$comm $options" ; fi
  if test "x$OPTFILE" != x ; then
    comm="$comm -of=$OPTFILE"
  fi
  echo " option '-src' (only fortran source-files):"	| tee -a $LOG_FIL
  comm="$comm -src"
  echo "  \"eval $comm\""		| tee -a $LOG_FIL
  echo "======================"
  ( cd $gcmDIR/verification
    eval $comm				>> $LOG_FIL 2>&1
  )
 #sed -n "/^An email /,/^======== End of testreport / p" $LOG_FIL
  sed -n "/^No results email was sent/,/^======== End of testreport / p" $LOG_FIL
  echo ""				| tee -a $LOG_FIL

#-- submit SLURM script to run
  if test -e $SUB_DIR/$BATCH_SCRIPT ; then
    echo " submit SLURM bach script '$SUB_DIR/$BATCH_SCRIPT'"	| tee -a $LOG_FIL
    $QSUB $SUB_DIR/$BATCH_SCRIPT				| tee -a $LOG_FIL
    echo " job '$JOB' in queue:"				| tee -a $LOG_FIL
    #$QSTAT | grep $JOB						| tee -a $LOG_FIL
    $QLIST | grep $sJob						| tee -a $LOG_FIL
  else
    echo " no SLURM script '$SUB_DIR/$BATCH_SCRIPT' to submit"	| tee -a $LOG_FIL
    continue
  fi

