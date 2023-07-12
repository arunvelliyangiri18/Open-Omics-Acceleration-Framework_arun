#!/bin/sh
SCRIPT_PATH="${BASH_SOURCE:-$0}"
ABS_SCRIPT_PATH="$(realpath "${SCRIPT_PATH}")"
ABS_DIRECTORY="$(dirname "${ABS_SCRIPTINPUT_DIR_PATH}")"

INDIR=$INPUT_DIR
OUTDIR=$OUTPUT_DIR

#* ranks: Number of mpi process that we want the pipeline to run on
#* threads/shards: parameters to different tools in the pipeline, calculated as below
ppn=$1
Sockets=$(lscpu | grep -E '^Socket\(s\)' | awk  '{print $2}')   #2
Cores=$(lscpu| grep -E '^Core\(s\)' | awk  '{print $4}')  #56
Thread=$(lscpu | grep -E '^Thread' | awk  '{print $4}')  #2

a=$(( $(( ${Cores}*${Thread}*${Sockets} / $ppn )) - 2*${Thread} ))   #24 (Four threads are removed for IO)
b=$(( $(( ${Cores}*${Sockets} )) / $ppn ))   #14

if [ $a -lt 1]; then
    echo 'Number of cpus are less to run the pipeline.'
    exit 1
fi

N=$1
PPN=$2
CPUS=$a
THREADS=$a
SHARDS=$b
INDEX=GRCh38_chr1.fna
FILEBASE=HG001_
BINDING=socket



echo $OUTDIR
mkdir -p ${OUTDIR}

echo Starting run with $N ranks, $CPUS threads,$THREADS threads, $SHARDS shards, $PPN ppn.

mpiexec -bootstrap ssh -bind-to $BINDING -map-by $BINDING --hostfile hostfile -n $N -ppn $PPN python -u test_pipeline_final.py --input $INDIR --output  $OUTDIR $TEMPDIR $REFDIR --index $INDEX --read ${FILEBASE}R1_chr1.fastq.gz ${FILEBASE}R2_chr1.fastq.gz --cpus $CPUS --threads $THREADS --shards $SHARDS |& tee ${OUTDIR}log.txt
