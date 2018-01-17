#!/bin/bash

#BSUB -q mpi
#BSUB -W 47:50
#BSUB -n 1
#BSUB -a openmp
#BSUB -o /usr/users/jsoedin/jobs/cif70_finalize.log
#BSUB -R "span[hosts=1]"
#BSUB -R np16
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -J cif70_finalize
#BSUB -m hh
#BSUB -w "done(cif70_hhmake) && done(cif70_cstranslate) && done(cif70_cstranslate_old)"

source paths.sh
source /etc/profile
source $HOME/.bashrc

#set +e
#set +x

## Copy from build to final directory
for type in a3m hhm cs219 cs219_old;
do
  echo "! Running ffindex_modify -u -f ${pdb70_build_dir}/todo_files.dat ${pdb70_dir}/pdb70_${type}.ffindex"
  # Delete todo_files from old ffindices
  ffindex_modify -u -f ${pdb70_build_dir}/todo_files.dat ${pdb70_dir}/pdb70_${type}.ffindex
  echo "! Running ffindex_build -as -d ${pdb70_build_dir}/pdb70_${type}.ffdata -i ${pdb70_build_dir}/pdb70_${type}.ffindex ${pdb70_dir}/pdb70_${type}.ff{data,index}"
  # Add new files
  ffindex_build -as -d ${pdb70_build_dir}/pdb70_${type}.ffdata -i ${pdb70_build_dir}/pdb70_${type}.ffindex ${pdb70_dir}/pdb70_${type}.ff{data,index}
  echo "! Running ffindex_build -as -d ${pdb70_dir}/pdb70_${type}.ffdata -i ${pdb70_dir}/pdb70_${type}.ffindex ${pdb70_dir}/pdb70_${type}_opt.ff{data,index}"
  # Optimize ffindex databases
  ffindex_build -as -d ${pdb70_dir}/pdb70_${type}.ffdata -i ${pdb70_dir}/pdb70_${type}.ffindex ${pdb70_dir}/pdb70_${type}_opt.ff{data,index}

  # Overwrite unoptimized databases with optimized databases
  mv -f ${pdb70_dir}/pdb70_${type}_opt.ffdata ${pdb70_dir}/pdb70_${type}.ffdata
  mv -f ${pdb70_dir}/pdb70_${type}_opt.ffindex ${pdb70_dir}/pdb70_${type}.ffindex
done

echo "PART 2 of finalize"

##sort hhms and a3m according to sequence length
sort -k 3 -n ${pdb70_dir}/pdb70_cs219.ffindex | cut -f1 > ${pdb70_build_dir}/sort_by_length.dat
for type in a3m hhm;
do
  ffindex_order ${pdb70_build_dir}/sort_by_length.dat ${pdb70_dir}/pdb70_${type}.ffdata ${pdb70_dir}/pdb70_${type}.ffindex ${pdb70_dir}/pdb70_${type}_opt.ffdata ${pdb70_dir}/pdb70_${type}_opt.ffindex

  mv -f ${pdb70_dir}/pdb70_${type}_opt.ffdata ${pdb70_dir}/pdb70_${type}.ffdata
  mv -f ${pdb70_dir}/pdb70_${type}_opt.ffindex ${pdb70_dir}/pdb70_${type}.ffindex
done

echo "PART 3 of finalize ffindex data manager"

##update time stamps
cut -f 1 ${pdb70_build_dir}/pdb70_a3m.ffindex > ${pdb70_build_dir}/done_files.dat
python3 ./ffindex_date_manager.py --update -i ${pdb70_dir}/pdb70_date_index.dat -f ${pdb70_build_dir}/done_files.dat

echo "PART 4 of finalize reformat_old_cs219"

## Prepare old database format
#delete old cs219 files
rm -f ${pdb70_dir}/pdb70.cs219 ${pdb70_dir}/pdb70.cs219.sizes
python3 ./reformat_old_cs219_ffindex.py ${pdb70_dir}/pdb70_cs219_old ${pdb70_dir}/pdb70

#delete old indices
rm -f ${pdb70_dir}/pdb70_{a3m_db,hhm_db,pdb}.index
awk '{$1=$1".a3m"}1' ${pdb70_dir}/pdb70_a3m.ffindex > ${pdb70_dir}/pdb70_a3m_db.index
sed -i "s/ /\t/g" ${pdb70_dir}/pdb70_a3m_db.index
awk '{$1=$1".hhm"}1' ${pdb70_dir}/pdb70_hhm.ffindex > ${pdb70_dir}/pdb70_hhm_db.index
sed -i "s/ /\t/g" ${pdb70_dir}/pdb70_hhm_db.index

#update links
cd ${pdb70_dir}
ln -sf pdb70_a3m.ffdata pdb70_a3m_db
ln -sf pdb70_hhm.ffdata pdb70_hhm_db

#rm -f md5sum
md5sum pdb70_{a3m,hhm,cs219}.ff{data,index} pdb70.cs219 pdb70.cs219.sizes pdb70_{a3m_db,hhm_db}.index pdb_filter.dat pdb70_clu.tsv > md5sum

# date of when the pdb100 was downloaded
release="$(date -d @$(stat -c '%Y' pdb100.fas) +'%y%m%d')"
tar_name="pdb70_from_mmcif_${release}.tar.gz"

tar -I pigz -cvf ${tar_name} md5sum pdb70_{a3m,hhm,cs219}.ff{data,index} pdb70.cs219 pdb70.cs219.sizes pdb70_{a3m_db,hhm_db}.index pdb70_a3m_db pdb70_hhm_db pdb_filter.dat pdb70_clu.tsv
chmod a+r ${tar_name}

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${tar_name} compbiol@login.gwdg.de:/usr/users/compbiol
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no compbiol@login.gwdg.de "mv /usr/users/compbiol/${tar_name} /usr/users/compbiol/www/data/hhsuite/databases/hhsuite_dbs"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no compbiol@login.gwdg.de "ln -sf /usr/users/compbiol/www/data/hhsuite/databases/hhsuite_dbs/${tar_name} /usr/users/compbiol/www/data/hhsuite/databases/hhsuite_dbs/pdb70_from_mmcif_latest.tar.gz"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no compbiol@login.gwdg.de "find /usr/users/compbiol/www/data/hhsuite/databases/hhsuite_dbs/ -maxdepth 1 -type f -mtime +42 -name 'pdb70_from_mmcif_*' -execdir mv {} /usr/users/a/compbiol \;"

rm -f ${tar_name}
rm -f ${pdb70_lock_file}
