#!/bin/bash
REF="$HOME/scer-genome/scer.fa"

grep '^MA62' expected-mutations-all-msh2-lines.tsv | sed 's/:/\t/' > ma62-b2_expected-mut.tsv
grep '^MA79' expected-mutations-all-msh2-lines.tsv | sed 's/:/\t/' > ma79-h1_expected-mut.tsv
while read f; do a=$(echo "$f" | cut -f1);b=$(echo "$f" | cut -f2); sed -i "s/ref|$a|/$b/" ma79-h1_expected-mut.tsv;done<chromosomes-rename.txt
while read f; do a=$(echo "$f" | cut -f1);b=$(echo "$f" | cut -f2); sed -i "s/ref|$a|/$b/" ma62-b2_expected-mut.tsv;done<chromosomes-rename.txt

cut -f2,3 ma79-h1_expected-mut.tsv | sed 's/$/\t./' > a.txt
cut -f4- ma79-h1_expected-mut.tsv | sed 's/$/\t.\t.\tMA_LINE=MA79\tGT\t1/' > b.txt
paste a.txt b.txt | sed 's/ //g' > c.txt
cat header c.txt | sed 's/SAMPLE/MA79/' > ma79-h1_expected-mut.vcf

cut -f2,3 ma62-b2_expected-mut.tsv | sed 's/$/\t./' > a.txt
cut -f4- ma62-b2_expected-mut.tsv | sed 's/$/\t.\t.\tMA_LINE=MA62\tGT\t1/' > b.txt
paste a.txt b.txt | sed 's/ //g' > c.txt
cat header c.txt | sed 's/SAMPLE/MA62/' > ma62-b2_expected-mut.vcf

bcftools norm -f $REF ma79-h1_expected-mut.vcf -o ma79-h1_expected-mut-norm.vcf.gz -O z -W
bcftools norm -f $REF ma62-b2_expected-mut.vcf -o ma62-b2_expected-mut-norm.vcf.gz -O z -W

## different mutations 
grep '^MA' expected-mutations-all-msh2-lines.tsv | sed 's/:/\t/' > all_expected-mut.tsv
while read f; do a=$(echo "$f" | cut -f1);b=$(echo "$f" | cut -f2); sed -i "s/ref|$a|/$b/" all_expected-mut.tsv;done<chromosomes-rename.txt
cut -f2,3 all_expected-mut.tsv  > a.txt
cut -f1 all_expected-mut.tsv  > b.txt
cut -f4- all_expected-mut.tsv | sed 's/$/\t.\t.\tMA_LINE=/' > c.txt
cat b.txt | sed 's/$/\tGT\t1/' > d.txt
paste a.txt b.txt c.txt d.txt | sed 's/ //g' | sed 's/=\t/=/' > e.txt
cat header e.txt > all_expected-mut.vcf

bcftools sort all_expected-mut.vcf |\
bcftools norm -f $REF  -o all_expected-mut-norm.vcf.gz -O z -W

## confirm
bcftools filter -i 'ID="MA23"' all_expected-mut.vcf |\
bcftools norm -f $REF -d exact -o ma23_h3_expected-mut-norm.vcf.gz -O z -W

bcftools filter -i 'ID="MA28"' all_expected-mut.vcf |\
bcftools norm -f $REF -d exact -o ma28_h5_expected-mut-norm.vcf.gz -O z -W

rm  *_expected-mut.vcf *[0-9]_expected-mut.tsv