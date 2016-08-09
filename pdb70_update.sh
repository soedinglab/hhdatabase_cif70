#!/bin/bash

cd /cbscratch/hvoehri/hhdatabase_pdb70

source /etc/profile
source ./paths.sh
source ~/.bashrc

export pdb70_lock_file=${pdb70_dir}/lock_pdb70.txt

if [ -e ${pdb70_lock_file} ] && kill -0 `cat ${pdb70_lock_file}`; then
  echo "already running"
  exit
fi

# remove old log files
rm -f /cbscratch/hvoehri/hhdatabase_pdb70/logs/pdb70*.log

echo "pdb70_update.sh: Creating ${pdb_dir}."
mkdir -p ${pdb_dir} # create the pdb folder if not exitsts

# sync folders, for testing purposes only some folders of the PDB
echo "pdb70_update.sh: Syncing folders ..."
#rsync --progress -rlpt -v -z --port=33444 rsync.wwpdb.org::ftp/data/structures/divided/mmCIF/08 ${pdb_dir}
rsync --progress -rlpt -v -z --port=33444 rsync.wwpdb.org::ftp/data/structures/divided/mmCIF ${pdb_dir}
rsync --progress -rlpt -v -z --port=33444 rsync.wwpdb.org::ftp/data/structures/obsolete/mmCIF ${pdb_dir}/obsolete


bsub < ./pdb70_unfold_pdb.sh 
bsub < ./pdb70_prepare_input.sh
bsub < ./pdb70_hhblits.sh

#depends on hhblits
bsub < ./pdb70_addss.sh
bsub < ./pdb70_cstranslate.sh
bsub < ./pdb70_cstranslate_old.sh
#bsub < ./pdb70_renumberpdb.sh

#depends on addss
bsub < ./pdb70_hhmake.sh

#depends on hhmake cstranslate cstranslate_old renumberpdb
bsub < ./pdb70_finalize.sh

