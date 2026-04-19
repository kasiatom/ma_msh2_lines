#!/bin/bash
set -euo pipefail
trap 'echo "BLAD w linii $LINENO"' ERR

echo "Podaj sciezke do folderu z plikami BAM:"
read BAM_DATA

echo "Podaj sciezke do pliku z referencja:"
read REF

## tworzenie potrzebnych folderow
mkdir -p results
mkdir -p results/raw_vcf
mkdir -p results/norm_vcf
mkdir -p results/filtered_vcf
mkdir -p results/logs

echo "analiza small variants; tworzenie vcf"

## gdy brak plikow BAM, nie zwraca wyniku
shopt -s nullglob

## tworzenie listy z plikow .bam
bam_files=("$BAM_DATA"/*final.bam)

if [ "${#bam_files[@]}" -eq 0 ]; then
echo "Brak plikow BAM"
exit 1
fi

for bam in "${bam_files[@]}"; do
 sample=$(basename "$bam" .bam)

echo "analiza probki $sample"

## tworzenie nazw plikow
raw_vcf="results/raw_vcf/${sample}.vcf.gz"
norm_vcf="results/norm_vcf/${sample}.norm.vcf.gz"
filt_vcf="results/filtered_vcf/${sample}.filtered.vcf.gz"

## tworzenie logow do kazdego kroku
haplo_log="results/logs/${sample}.haplotypecaller.log"
norm_log="results/logs/${sample}.norm.log"
filt_log="results/logs/${sample}.filter.log"

## szukanie mutacji
echo "krok 1: szukanie mutacji dla: [$sample]"

gatk HaplotypeCaller \
    -I "$bam" \
    -R "$REF" \
    -O "$raw_vcf" \
    > "$haplo_log" 2>&1

## porzadkowanie pliku vcf
echo "krok 2: porzadkowanie pliku vcf dla: [$sample]"

    bcftools norm \
        -f "$REF" \
        -m -any \
        "$raw_vcf" \
        -Oz \
        -o "$norm_vcf" \        > "$norm_log" 2>&1

    bcftools index -t "$norm_vcf" >> "$norm_log" 2>&1

## filtorwanie 
echo "krok 3: filtrowanie dla: [$sample]"

    bcftools filter \
        -e 'TYPE="snp" & (INFO/FS > 60 | INFO/ReadPosRankSum < -8.0 | INFO/SOR > 3.0 | INFO/MQ < 40.0 | INFO/MQRankSum < -12.5)' \
        "$norm_vcf" \
    | bcftools filter \
        -e 'TYPE="indel" & (INFO/FS > 200 | INFO/ReadPosRankSum < -20.0)' \
    | bcftools filter \
        -e 'QUAL <= 30.0' \
        -Oz \
        -o "$filt_vcf" \
        > "$filt_log" 2>&1

    bcftools index -t "$filt_vcf" >> "$filt_log" 2>&1

    echo "analiza skonczona dla: [$sample]" 

done

