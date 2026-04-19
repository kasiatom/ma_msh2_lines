#!/bin/bash
set -euo pipefail
trap 'echo "BLAD w linii $LINENO"' ERR

echo "Podaj sciezke do folderu z wynikami do cnv"
read CNV_RAW_DATA

echo "Podaj sciezke do pliku cnvkit.sif:"
read CNVKIT_SIF

echo "Podaj sciezke do folderu z filtrowanymi VCF:"
read VCF_DATA

## tworzenie folderow
mkdir -p cnv_results/final
mkdir -p cnv_results/plots
mkdir -p cnv_results/logs

## list plikow
shopt -s nullglob
sample_dirs=("$CNV_RAW_DATA"/*)

## sprawdzenie czy probki sa w folderze
if [ "${#sample_dirs[@]}" -eq 0 ]; then
    echo "Brak probek w folderze"
    exit 1
fi

## petla dla kazdej probki
for sample_dir in "${sample_dirs[@]}"; do

    ## pomijanie rzeczy, ktore nie sa folderami
    if [ ! -d "$sample_dir" ]; then
        continue
    fi

    ## nazwa probki
    sample=$(basename "$sample_dir")

    ## pliki wejsciowe
    cns_file="$sample_dir/${sample}.final.cns"
    cnr_file="$sample_dir/${sample}.final.cnr"
    vcf_file="$VCF_DATA/${sample}.final.filtered.vcf.gz"

    ## sprawdzanie czy pliki istenija jesli nie to probka jest pomijana
    if [ ! -f "$cns_file" ]; then
        echo "Brak pliku: $cns_file"
        continue
    fi

    if [ ! -f "$cnr_file" ]; then
        echo "Brak pliku: $cnr_file"
        continue
    fi

    if [ ! -f "$vcf_file" ]; then
        echo "Brak pliku: $vcf_file"
        continue
    fi

    ## nazwa dla outputu
    haplo_call="$sample_dir/${sample}_haplo.call.cns"
    diplo_call="$sample_dir/${sample}_diplo.call.cns"

    ## filtrowanie do wykresu
    filtered_cnr="$sample_dir/${sample}.filtered.cnr"
    filtered_cns="$sample_dir/${sample}.filtered.cns"
    filtered_haplo="cnv_results/final/${sample}_filtered_haplo.call.cns"
    filtered_diplo="cnv_results/final/${sample}_filtered_diplo.call.cns"

    ## tworzenie pdf
    pdf_file="cnv_results/plots/${sample}.pdf"

    ## call dla  haploida
    singularity exec "$CNVKIT_SIF" cnvkit.py call "$cns_file" \
        --method clonal \
        --purity 1 \
        --ploidy 1 \
        --vcf "$vcf_file" \
        -o "$haplo_call"

    ## call dla diploida
    singularity exec "$CNVKIT_SIF" cnvkit.py call "$cns_file" \
        --method clonal \
        --purity 1 \
        --ploidy 2 \
        --vcf "$vcf_file" \
        -o "$diplo_call"

    ## usuwanie skrajnych wartosci
    awk 'NR==1 || ($6 > -5 && $6 < 5)' "$cnr_file" > "$filtered_cnr"
    awk 'NR==1 || ($5 > -5 && $5 < 5)' "$cns_file" > "$filtered_cns"

    ## tworzenie wykresu
    singularity exec "$CNVKIT_SIF" cnvkit.py scatter \
        -s "$filtered_cns" "$filtered_cnr" \
        -o "$pdf_file"

    ## filtrowanie dla haploida
    head -1 "$haplo_call" > "$filtered_haplo"
    awk 'NR>1 && ($8 != 1 && $10 < 0.01 && $1 != "Mito")' "$haplo_call" \
        | sort -k1,1V -k2,2n >> "$filtered_haplo"

    ## filtrowanie dla diploida
    head -1 "$diplo_call" > "$filtered_diplo"
    awk 'NR>1 && ($8 != 2 && $10 < 0.01 && $1 != "Mito")' "$diplo_call" \
        | sort -k1,1V -k2,2n >> "$filtered_diplo"

    echo "Koniec analizy dla probki: $sample"

done

echo "Koniec"
