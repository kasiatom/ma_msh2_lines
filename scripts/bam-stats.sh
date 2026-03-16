#!/bin/bash

set -e -o pipefail

OUT="$HOME/dna-seq-02-2026/bam-metrics"

for i in $HOME/dna-seq-02-2026/bams/*.bam
do 
	name=$(basename $i "_bwa-markdup.bam")
	samtools flagstats -@10 $i > $OUT/"$name"_flagstats.txt
done