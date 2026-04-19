#!/bin/bash
set -euo pipefail
trap 'echo "BLAD w linii $LINENO"' ERR

echo "Podaj sciezke do folderu z plikami BAM:"
read BAM_DATA

echo "Podaj sciezke do pliku cnvkit.sif:"
read CNVKIT_SIF

echo "Podaj sciezke do referencji"
read REF

echo "Podaj sciezke do pliku reference.cnn:"
read REF_CNN

## tworzenie folderow
mkdir -p cnv_results
mkdir -p cnv_results/raw
mkdir -p cnv_results/logs

echo "wlaczanie cnvkit"

## lista plikow BAM
shopt -s nullglob
bam_files=("$BAM_DATA"/*.final.bam)

## sprawdzanie czy pliki istnieja
if [ "${#bam_files[@]}" -eq 0 ]; then
    echo "Brak plikow BAM w podanym folderze"
    exit 1
fi

##  polecenia dla kazdego pliku BAM
for bam in "${bam_files[@]}"; do

## zmiana nazwy probki 
sample=$(basename "$bam" .bam)
sample=${sample%.final}

echo "Analiza probki: $sample"

## foldery i log dla probek
sample_dir="cnv_results/raw/${sample}"
log_file="cnv_results/logs/${sample}.cnvkit_batch.log"

## tworzenie folderu dla konkretnej probki
mkdir -p "$sample_dir"

singularity exec "$CNVKIT_SIF" cnvkit.py batch "$bam" \
    --method wgs \
    --fasta "$REF" \
    --reference "$REF_CNN" \
    -p 4 \
    -d "$sample_dir" \
    > "$log_file" 2>&1

echo "Zakonczono analize dla probki: $sample"
done
echo "Koniec"
