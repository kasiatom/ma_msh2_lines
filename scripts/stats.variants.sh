#!/bin/bash
set -euo pipefail
trap 'echo "BLAD w linii $LINENO"' ERR

echo "Podaj sciezke do folderu z filtrowanymi plikami VCF:"
read VCF_DATA

## tworzenie potrzebnych folderow
mkdir -p variant_stats
mkdir -p variant_stats/data
mkdir -p variant_stats/logs

## tworzenie nazw plikow wynikowych
OUT_FILE="variant_stats/data/variant_stats.tsv"
LOG_FILE="variant_stats/logs/variant_stats.log"

## tworzenie wiersza z nazwami kolumn
echo -e "sample\ttotal_variants\thomozygous_variants\theterozygous_variants\tsnp_variants\tindel_variants\tfraction_homozygous\tfraction_heterozygous\tfraction_snps\tfraction_indels" > "$OUT_FILE"

## lista z plikami vcf.gz
shopt -s nullglob
vcf_files=("$VCF_DATA"/*.vcf.gz)

## sprawdzenie czy pliki vcf znajduja sie w podanym folderze
if [ "${#vcf_files[@]}" -eq 0 ]; then
    echo "Brak plikow .vcf.gz w folderze: $VCF_DATA"
    exit 1
fi

## wykonanie dla kazdego pliku kolejnych krokow analizy
for vcf in "${vcf_files[@]}"; do
    ## zmiana nazwy pliku na nazwe probki
    sample=$(basename "$vcf" .vcf.gz)
    sample=${sample%.filtered}
    sample=${sample%.final}

    echo "Analiza probki: $sample" | tee -a "$LOG_FILE"

    ## pokazanie REF, ALT i GT + liczenie statystyk
    bcftools query -f '%REF\t%ALT[\t%GT]\n' "$vcf" | \
    awk -v sample="$sample" '
    BEGIN {
        total=0;
        hom=0;
        het=0;
        indel=0;
        snp=0;
    }
    {
        ref=$1;
        alt=$2;
        gt=$3;

        total++;

        if (length(ref) != length(alt)) {
            indel++;
        } else {
            snp++;
        }

        if (gt ~ /^[0-9]+[\/|][0-9]+$/) {
            split(gt, a, /[\/|]/);
            if (a[1] != a[2]) {
                het++;
            } else if (a[1] != "0") {
                hom++;
            }
        }
        else if (gt ~ /^[1-9][0-9]*$/) {
            hom++;
        }
    }
    END {
        frac_hom = (total > 0 ? hom/total : 0);
        frac_het = (total > 0 ? het/total : 0);
        frac_indel = (total > 0 ? indel/total : 0);
        frac_snp = (total > 0 ? snp/total : 0);

        printf "%s\t%d\t%d\t%d\t%d\t%d\t%.6f\t%.6f\t%.6f\t%.6f\n",
               sample, total, hom, het, snp, indel, frac_hom, frac_het, frac_snp, frac_indel;
    }' >> "$OUT_FILE"

done

echo "Koniec"
