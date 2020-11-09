#!/bin/bash

cd ${HOME}/git/hhdatabase_cif70

source /etc/profile
source ./paths.sh
source ~/.bashrc

set -e

export pdb70_lock_file=${pdb70_dir}/lock_pdb70.txt

if [ -e ${pdb70_lock_file} ] && kill -0 `cat ${pdb70_lock_file}`; then
  echo "already running"
  exit
fi

# remove old log files
rm -f ${HOME}/jobs/cif70*.log

echo "pdb70_update.sh: Creating ${pdb_dir}."
mkdir -p ${pdb_dir} # create the pdb folder if not exitsts

# sync folders, for testing purposes only some folders of the PDB
echo "pdb70_update.sh: Syncing folders ..."
rsync --progress -rlpt -v -z --delete --port=33444 rsync.wwpdb.org::ftp/data/structures/divided/mmCIF/ ${pdb_dir}

LOG_DIR=/usr/users/jsoedin/jobs
JOB_ID=$(sbatch -p hh -t 2-0 -n 1  -N 1 $EXTRA_CLUSTER_ARGS --parsable -o "${LOG_DIR}/cif70_unfold_cif.log" ./pdb70_unfold_pdb.sh)
JOB_ID=$(sbatch -p hh -t 2-0 -n 16 -N 1 $EXTRA_CLUSTER_ARGS --parsable -o "${LOG_DIR}/cif70_prepare_input.log" -d "afterok:$JOB_ID" ./pdb70_prepare_input.sh)
JOB_ID=$(sbatch -p hh -t 2-0 -n 16 -N 1 $EXTRA_CLUSTER_ARGS --parsable -o "${LOG_DIR}/cif70_hhblits.log" -d "afterok:$JOB_ID" --array=1-11 ./pdb70_hhblits_split.sh)
HH_JOB_ID=$(sbatch -p hh -t 2-0 -n 1  -N 1 $EXTRA_CLUSTER_ARGS --parsable -o "${LOG_DIR}/cif70_hhblits_merge.log" -d "afterok:$JOB_ID" ./pdb70_hhblits_merge.sh)

#depends on hhblits
SS_JOB_ID=$(sbatch -p hh -t 2-0 -n 16 -N 1 $EXTRA_CLUSTER_ARGS --parsable -o "${LOG_DIR}/cif70_addss.log" -d "afterok:$HH_JOB_ID" ./pdb70_addss.sh)
CS_JOB_ID=$(sbatch -p hh -t 2-0 -n 16 -N 1 $EXTRA_CLUSTER_ARGS --parsable -o "${LOG_DIR}/cif70_cstranslate.log" -d "afterok:$HH_JOB_ID" ./pdb70_cstranslate.sh)
#CO_JOB_ID=$(sbatch -p hh -t 2-0 -n 16 -N 1 --parsable -o "${LOG_DIR}/cif70_cstranslate_old.log" -d "afterok:$HH_JOB_ID" ./pdb70_cstranslate_old.sh)

#depends on addss
HM_JOB_ID=$(sbatch -p hh -t 2-0 -n 16 -N 1 $EXTRA_CLUSTER_ARGS --parsable -o "${LOG_DIR}/cif70_hhmake.log" -d "afterok:$SS_JOB_ID" ./pdb70_hhmake.sh)

#depends on hhmake cstranslate
sbatch -p hh -t 2-0 -n 1 -N 1 $EXTRA_CLUSTER_ARGS -o "${LOG_DIR}/cif70_finalize.log" -d "afterok:${HM_JOB_ID},${CS_JOB_ID}" ./pdb70_finalize.sh

