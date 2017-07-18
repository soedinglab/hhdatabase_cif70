#!/bin/bash

cd ${HOME}/git/hhdatabase_cif70

source /etc/profile
source ./paths.sh
source ~/.bashrc

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
rsync --progress -rlpt -v -z --port=33444 rsync.wwpdb.org::ftp/data/structures/divided/mmCIF/ ${pdb_dir}
rsync --progress -rlpt -v -z --port=33444 rsync.wwpdb.org::ftp/data/structures/obsolete/mmCIF/ ${pdb_dir}/obsolete

timestamp=$(date +%s)
bsub -q mpi -W 47:50 -n 1 -a openmp -o /usr/users/jsoedin/jobs/cif70_unfold_cif.log -R "span[hosts=1]" -R haswell -R cbscratch -J cif70_unfold_cif${timestamp} ./pdb70_unfold_pdb.sh
bsub -q mpi -W 47:50 -n 16 -a openmp -o /usr/users/jsoedin/jobs/cif70_prepare_input.log -R "span[hosts=1]" -R haswell -m hh -R cbscratch -J cif70_prepare_input${timestamp} -w "done(cif70_unfold_cif${timestamp})" ./pdb70_prepare_input.sh
#bsub -q mpi -W 48:00 -n 16 -a openmp -R "span[hosts=1]" -o /usr/users/jsoedin/jobs/cif70_hhblits.log -R np16 -R haswell -R cbscratch -J cif70_hhblits${timestamp} -m hh -w "done(cif70_prepare_input${timestamp})" ./pdb70_hhblits.sh

bsub -q mpi -W 48:00 -n 16 -a openmp -R "span[hosts=1]" -o /usr/users/jsoedin/jobs/cif70_hhblits.log -R np16 -R haswell -R cbscratch -J cif70_hhblits_run${timestamp}[1-11] -m hh -w "done(cif70_prepare_input${timestamp})" ./pdb70_hhblits_split.sh
bsub -q mpi -W 48:00 -n 1 -a openmp -R "span[hosts=1]" -o /usr/users/jsoedin/jobs/cif70_hhblits.log -R np16 -R haswell -R cbscratch -J cif70_hhblits${timestamp} -m hh -w "ended(cif70_hhblits_run${timestamp})" ./pdb70_hhblits_merge.sh

#depends on hhblits
bsub -q mpi -W 47:50 -n 16 -a openmp -o /usr/users/jsoedin/jobs/cif70_addss.log -R "span[hosts=1]" -R np16 -R haswell -R cbscratch -J cif70_addss${timestamp} -m hh -w "done(cif70_hhblits${timestamp})" ./pdb70_addss.sh
bsub -q mpi -W 47:50 -n 16 -a openmp -o /usr/users/jsoedin/jobs/cif70_cstranslate.log -R "span[hosts=1]" -R np16 -R haswell -R cbscratch -J cif70_cstranslate${timestamp} -m hh -w "done(cif70_hhblits${timestamp})" ./pdb70_cstranslate.sh
bsub -q mpi -W 47:50 -n 16 -a openmp -o /usr/users/jsoedin/jobs/cif70_cstranslate_old.log -R "span[hosts=1]" -R np16 -R haswell -R cbscratch -J cif70_cstranslate_old${timestamp} -m hh -w "done(cif70_hhblits${timestamp})" ./pdb70_cstranslate_old.sh

#depends on addss
bsub -q mpi -W 47:50 -n 16 -a openmp -o /usr/users/jsoedin/jobs/cif70_hhmake.log -R "span[hosts=1]" -R np16 -R haswell -R cbscratch -J cif70_hhmake${timestamp} -m hh -w "done(cif70_addss${timestamp})" ./pdb70_hhmake.sh

#depends on hhmake cstranslate cstranslate_old
bsub -q mpi -W 47:50 -n 1 -a openmp -o /usr/users/jsoedin/jobs/cif70_finalize.log -R "span[hosts=1]" -R np16 -R haswell -R cbscratch -J cif70_finalize${timestamp} -m hh -w "done(cif70_hhmake${timestamp}) && done(cif70_cstranslate${timestamp}) && done(cif70_cstranslate_old${timestamp})" ./pdb70_finalize.sh

