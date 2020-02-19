#!/bin/bash
source ./paths.sh
source ~/.bashrc

set -e

pdb_archives_list=$(mktemp --suffix=.dat)
find ${pdb_dir} -name "*.gz" > ${pdb_archives_list}

mkdir -p ${pdb_dir}/all

echo "pdb70_unfold_pdb.sh: Unpacking pdb data ..."
while read f; do
  bn=$(basename $f .gz)
  if [ ! -e ${pdb_dir}/all/${bn} ]; then
    gunzip -c ${f} > ${pdb_dir}/all/${bn}
  fi
done < ${pdb_archives_list}

rm -f ${pdb_archives_list}
