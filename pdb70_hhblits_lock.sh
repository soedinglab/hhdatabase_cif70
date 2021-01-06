#!/bin/bash
source paths.sh
source ~/.bashrc

set -e

mkdir -p "${LOCAL}/${USER}"
MYLOCAL=$(mktemp -d --tmpdir=${LOCAL}/${USER})
trap "if [ -d \"${MYLOCAL}\" ] && [ \"${MYLOCAL}\" != \"/\" ]; then rm -rf -- \"${MYLOCAL}\"; fi" EXIT

# copy database to local ssd
db=${uniprot}
db_bn=$(basename $db)
#cp ${db}*.ff* ${MYLOCAL}
#DB=${MYLOCAL}/${db_bn}
cp ${db}*.ff* /dev/shm
DB=/dev/shm/${db_bn}

open_sem() {
    mkfifo pipe-$$
    exec 3<>pipe-$$
    rm pipe-$$
    local i=$1
    for ((;i>0;i--)); do
        printf %s 000 >&3
    done
}

# run the given command asynchronously and pop/push tokens
run_with_lock() {
    local x
    # this read waits until there is something to read
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
        ( "$@"; )
        # push the return code of the command to the semaphore
        printf '%.3d' $? >&3
    )&
}

task() {
    dd if=${pdb70_build_dir}/selected_pdb70_fasta.ffdata ibs=1 skip="${OFF}" count="${LEN}" status=none | \
	hhblits -i stdin -oa3m ${MYLOCAL}/a3m/${KEY} -o /dev/null -cpu 1 -d "${DB}" -n 3 -v 0
}

mkdir -p "${MYLOCAL}/a3m"
N=128
open_sem $N
while read -r KEY OFF LEN; do
    run_with_lock task "${KEY}" "${OFF}" "${LEN}"
done < ${pdb70_build_dir}/selected_pdb70_fasta.ffindex

wait

(cd ${MYLOCAL}/a3m && ffindex_build -s ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index} .)

