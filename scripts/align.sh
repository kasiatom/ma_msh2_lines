#!/bin/bash
set -e -o pipefail


## align reads
REF="$HOME/scer-genome/scer.fa"
OUTDIR="$HOME/dna-seq-02-2026/bams/"
MERGED="$HOME/dna-seq-02-2026/merged-clean-fastq"

# merge per sample fastq files
cd clean-fastq
samples=$(ls *gz | cut -f1 -d '_' | sort | uniq)
cd ..
for i in $samples
do
	echo $i
	fq1=$(ls clean-fastq/"$i"_*_1.fq.gz)
	fq2=$(echo "$fq1" | sed 's/_1.fq.gz/_2.fq.gz/g')
	echo "$fq1"
	echo "$fq2"
	zcat $fq1 | bgzip > $MERGED/"$i"_clean_merged_1.fq.gz
	zcat $fq2 | bgzip > $MERGED/"$i"_clean_merged_2.fq.gz
done



## align to reference
for fq1 in $MERGED/*_1.fq.gz
do

	fq2=$(echo $fq1 | sed 's/_1.fq.gz/_2.fq.gz/')
  	ID=$(basename $fq1 "_clean_merged_1.fq.gz")
  	echo mapping: $ID
  	## set reading groups and other information
  	RG_ID="$ID"
  	RG_PU="$RG_ID"".""$ID"
  	RG_LB="$ID"".library"
  	RG_SM="$ID" 
  	RG_PL="illumina" 
  		

  	bwa mem \
    	-t 10 \
        -R "@RG\tID:""$RG_ID""\tPU:""$RG_PU""\tPL:""$RG_PL""\tLB:""$RG_LB""\tSM:""$RG_SM" \
        -K 100000000 -v 3 -Y  \
        $REF \
        "$fq1" "$fq2" \
        > $OUTDIR/"$ID"_bwa-unsorted.sam


   	## mark duplicated reads
   	echo marking duplicates: $ID
   	gatk MarkDuplicates \
      	-I $OUTDIR/"$ID"_bwa-unsorted.sam \
      	-O $OUTDIR/"$ID"_bwa-markdup-unsorted.bam \
      	-M $OUTDIR/"$ID"_bwa-metrics.txt \
      	--ASSUME_SORT_ORDER  queryname

   	## sort and index, write to qnap
   	echo sorting: $ID
   	samtools sort $OUTDIR/"$ID"_bwa-markdup-unsorted.bam -@ 10 -o $OUTDIR/"$ID"_bwa-markdup.bam
   	samtools index $OUTDIR/"$ID"_bwa-markdup.bam

   	##clean
   	rm $OUTDIR/"$ID"_bwa-markdup-unsorted.bam $OUTDIR/"$ID"_bwa-unsorted.sam 
done
echo all mapped