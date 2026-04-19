#!/bin/bash
set -euo pipefail
trap 'echo "BLAD w linii $LINENO"' ERR

echo "Podaj sciezke do folderu z filtrowanymi plikami VCF:"
read VCF_DIR

echo "Podaj sciezke do pliku z mutacjami autora:"
read EXPECTED_TSV

echo "Podaj sciezke do pliku chromosomes-rename.txt:"
read CHR_RENAME

echo "Podaj sciezke do pliku header:"
read HEADER_FILE

echo "Podaj sciezke do referencji:"
read REF

echo "Podaj nazwe probki do porownania (np. B2):"
read SAMPLE_NAME

echo "Podaj linie autora do porownania (np. MA62):"
read MA_LINE

mkdir -p comparison
mkdir -p comparison/data
mkdir -p comparison/logs
mkdir -p comparison/tmp

LOG_FILE="comparison/logs/comparison.log"
RESULT_FILE="comparison/data/overlap_summary.tsv"

if [ ! -f "$RESULT_FILE" ]; then
    echo -e "sample\tma_line\tshared_variants\tonly_sample\tonly_author\ttotal_sample_considered\toverlap_fraction" > "$RESULT_FILE"
fi

make_author_vcf () {
    local ma_line="$1"
    local out_prefix="$2"

    local selected_tsv="comparison/tmp/${out_prefix}_selected.tsv"
    local a_file="comparison/tmp/${out_prefix}_a.txt"
    local b_file="comparison/tmp/${out_prefix}_b.txt"
    local c_file="comparison/tmp/${out_prefix}_c.txt"
    local raw_vcf="comparison/tmp/${out_prefix}.vcf"
    local norm_vcf="comparison/tmp/${out_prefix}.norm.vcf.gz"

    grep "^${ma_line}" "$EXPECTED_TSV" | sed 's/:/\t/' > "$selected_tsv"

    while read -r f; do
        a=$(echo "$f" | cut -f1)
        b=$(echo "$f" | cut -f2)
        sed -i "s/ref|$a|/$b/" "$selected_tsv"
    done < "$CHR_RENAME"

    cut -f2,3 "$selected_tsv" | sed 's/$/\t./' > "$a_file"
    cut -f4- "$selected_tsv" | sed "s/$/\t.\t.\tMA_LINE=${ma_line}\tGT\t1/" > "$b_file"
    paste "$a_file" "$b_file" | sed 's/ //g' > "$c_file"
    cat "$HEADER_FILE" "$c_file" | sed "s/SAMPLE/${ma_line}/" > "$raw_vcf"

    bcftools norm -f "$REF" "$raw_vcf" -o "$norm_vcf" -O z >> "$LOG_FILE" 2>&1
    bcftools index -t "$norm_vcf" >> "$LOG_FILE" 2>&1

    echo "$norm_vcf"
}

compare_one_sample () {
    local sample_name="$1"
    local ma_line="$2"

    local sample_vcf="${VCF_DIR}/${sample_name}.final.filtered.vcf.gz"
    local author_norm_vcf
    local isec_dir="comparison/data/isec_${sample_name}"

    if [ ! -f "$sample_vcf" ]; then
        echo "Brak pliku probki: $sample_vcf"
        echo "Brak pliku probki: $sample_vcf" >> "$LOG_FILE"
        return 1
    fi

    author_norm_vcf=$(make_author_vcf "$ma_line" "${sample_name}_${ma_line}_author")

    rm -rf "$isec_dir"
    bcftools isec "$sample_vcf" "$author_norm_vcf" -p "$isec_dir" >> "$LOG_FILE" 2>&1

    only_sample=$(grep -vc '^#' "$isec_dir/0000.vcf" || true)
    only_author=$(grep -vc '^#' "$isec_dir/0001.vcf" || true)
    shared=$(grep -vc '^#' "$isec_dir/0002.vcf" || true)

    total_sample=$((only_sample + shared))

    if [ "$total_sample" -gt 0 ]; then
        overlap_fraction=$(awk -v s="$shared" -v t="$total_sample" 'BEGIN{printf "%.6f", s/t}')
    else
        overlap_fraction="0"
    fi

    echo -e "${sample_name}\t${ma_line}\t${shared}\t${only_sample}\t${only_author}\t${total_sample}\t${overlap_fraction}" >> "$RESULT_FILE"

}

compare_one_sample "$SAMPLE_NAME" "$MA_LINE"

echo "koniec"
