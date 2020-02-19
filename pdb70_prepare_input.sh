#!/bin/bash
source ./paths.sh
source ~/.bashrc

echo "pdb70_prepare_input: Removing old pdb100.fas and running pdb2fasta to create an up-to-date fasta file ..."
mkdir -p ${pdb70_dir}

# work in temp directory
rm -rf ${pdb70_build_dir}
mkdir -p ${pdb70_build_dir}

rm -f ${pdb70_dir}/pdb100.fas ${pdb70_dir}/pdb_filter.dat
python3 ${HHSCRIPTS}/cif2fasta.py -i ${pdb_dir}/all/ -o ${pdb70_dir}/pdb100.fas -p ${pdb70_dir}/pdb_filter.dat -s ${scop_file} -c 16 

echo "pdb70_prepare_input: Removing old pdb70.fas ..."
rm -f ${pdb70_dir}/pdb70.fas ${pdb70_dir}/pdb70_clu.tsv
rm -rf "${pdb70_build_dir}/clustering"
mmseqs rmdb ${pdb70_build_dir}/pdb70_clu

echo "pdb70_prepare_input: Starting mmseqs to cluster sequences from pdb100.fas (-c 0.9 --min-seq-id 0.7) ..."
mkdir -p ${pdb70_build_dir}/clustering
mmseqs createdb ${pdb70_dir}/pdb100.fas ${pdb70_dir}/pdb100
mmseqs cluster ${pdb70_dir}/pdb100 ${pdb70_build_dir}/pdb70_clu ${pdb70_build_dir}/clustering -c 0.9 --min-seq-id 0.7
mmseqs createtsv ${pdb70_dir}/pdb100 ${pdb70_dir}/pdb100 ${pdb70_build_dir}/pdb70_clu ${pdb70_dir}/pdb70_clu.tsv

echo "pdb70_prepare_input: Running pdbfilter to select for each cluster the structure with the best resolution, R-free and completness ..."
python3 ${HHSCRIPTS}/pdbfilter.py ${pdb70_dir}/pdb100.fas ${pdb70_dir}/pdb70_clu.tsv ${pdb70_dir}/pdb_filter.dat  ${pdb70_dir}/pdb70.fas -i ${pdb70_scripts}/pdb70_to_include.dat -r ${pdb70_scripts}/pdb70_to_remove.dat -v

echo "pdb70_prepare_input: Converting fasta file to ffdata, ffindex."
rm -f ${pdb70_dir}/pdb70_fasta.ff{data,index}
ffindex_from_fasta -s ${pdb70_dir}/pdb70_fasta.ff{data,index} ${pdb70_dir}/pdb70.fas

ln -s ${pdb70_dir}/pdb70_fasta.ffdata ${pdb70_build_dir}/selected_pdb70_fasta.ffdata

#build selected fasta sequences ffindex

## Get invalid files
#TODO: not working at the moment
#mpirun -np 1 ffindex_apply_mpi ${hhpred_pdb_dir}/pdb70_a3m.ff{data,index} -- ${HHLIB}/scripts/checkA3M.pl -i stdin --silent 2> ${hhpred_pdb_build_dir}/a3m_check.log
#grep "1$" ${hhpred_pdb_build_dir}/a3m_check.log | cut -f1 > ${hhpred_pdb_build_dir}/redo_old_fasta.dat

if [ ! -f ${pdb70_dir}/pdb70_a3m.ffindex ]; then
    echo "Did not find pdb70_a3m.ffindex. Creating a dummy file."
    touch ${pdb70_dir}/pdb70_a3m.ffindex
fi

if [ ! -f ${pdb70_dir}/pdb70_a3m.ffdata ]; then
    echo "Did not find pdb70_a3m.ffindex. Creating a dummy file."
    touch ${pdb70_dir}/pdb70_a3m.ffdata
fi

## Get new files
cut -f1 ${pdb70_dir}/pdb70_fasta.ffindex > ${pdb70_build_dir}/fasta_files.dat
cut -f1 ${pdb70_dir}/pdb70_a3m.ffindex | sed "s/.a3m$//g" > ${pdb70_build_dir}/existing_a3m_files.dat
cat ${pdb70_build_dir}/fasta_files.dat ${pdb70_build_dir}/existing_a3m_files.dat | sort | uniq -u > ${pdb70_build_dir}/new_fasta_files.dat


if [ ! -f ${pdb70_dir}/pdb70_date_index.dat ]; then
    echo "Did not find pdb70_date_index.dat. Creating a dummy file."
    touch ${pdb70_dir}/pdb70_date_index.dat
fi

## Get 1000 oldest files
python3 ./ffindex_date_manager.py --oldest=1000 -i ${pdb70_dir}/pdb70_date_index.dat -o ${pdb70_build_dir}/old_a3m_files.dat

cat ${pdb70_build_dir}/old_a3m_files.dat ${pdb70_build_dir}/new_fasta_files.dat > ${pdb70_build_dir}/todo_files.dat
cat ${pdb70_build_dir}/fasta_files.dat ${pdb70_build_dir}/old_a3m_files.dat ${pdb70_build_dir}/new_fasta_files.dat | sort | uniq -u > ${pdb70_build_dir}/not_todo_files.dat
cp ${pdb70_dir}/pdb70_fasta.ffindex ${pdb70_build_dir}/selected_pdb70_fasta.ffindex
ffindex_modify -s -u -f ${pdb70_build_dir}/not_todo_files.dat ${pdb70_build_dir}/selected_pdb70_fasta.ffindex

