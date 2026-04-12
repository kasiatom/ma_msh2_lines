#!/bin/bash
set -euo pipefail
trap 'echo "BLAD w linii $LINENO"' ERR

REF="/mnt/storage/projects/MA_experiment_ZGE/genome/scer.fa"
THREADS=40

# pytanie o folder z danymi
read -p "Podaj folder z FASTQ: " RAW

mkdir -p results/merged
mkdir -p results/map
mkdir -p results/flagstat
mkdir -p results/metrics
mkdir -p results/multiqc

echo "Krok 1: merge FASTQ"

cd "$RAW"

samples=$(ls *.fq.gz | cut -f1 -d '_' | sort | uniq)

for SAMPLE in $samples
do
    echo "Probka: $SAMPLE"

    cat ${SAMPLE}_*_L3_1.fq.gz ${SAMPLE}_*_L4_1.fq.gz > ../results/merged/${SAMPLE}_R1.fq.gz
    cat ${SAMPLE}_*_L3_2.fq.gz ${SAMPLE}_*_L4_2.fq.gz > ../results/merged/${SAMPLE}_R2.fq.gz

done

cd ..

echo "Krok 2: mapowanie"

for SAMPLE in $samples
do
    bwa mem -t "$THREADS" "$REF" \
    results/merged/${SAMPLE}_R1.fq.gz \
    results/merged/${SAMPLE}_R2.fq.gz \
    > results/map/${SAMPLE}.sam
done

echo "Krok 3: duplikaty i sortowanie"

for SAMPLE in $samples
do
    gatk MarkDuplicates \
    -I results/map/${SAMPLE}.sam \
    -O results/map/${SAMPLE}_dup.bam \
    -M results/metrics/${SAMPLE}.txt \
    --ASSUME_SORT_ORDER queryname

    samtools sort -@ "$THREADS" \
    results/map/${SAMPLE}_dup.bam \
    -o results/map/${SAMPLE}.bam

    samtools index results/map/${SAMPLE}.bam
done

echo "Krok 4: flagstat"

for SAMPLE in $samples
do
    samtools flagstat results/map/${SAMPLE}.bam \
    > results/flagstat/${SAMPLE}.txt
done

