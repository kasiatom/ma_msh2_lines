## Files location  

I gave the fastq files here `/mnt/storage/projects/MA_experiment_ZGE/fastq_for_OS/`. Copy the files to your account - contact me in case of permission problems. Each sample has four FASTQ files – two ending with `_1.fq.gz` and two with `_2.fq.gz`. Note that the files are compressed; **do not decompress them**, as almost all bioinformatics tools can work directly with compressed input.

1. Check the quality of the raw files by running FastQC (the program is installed in the bio Conda environment). Summarize the results using MultiQC, and add the final report to the repository. Then we will decide on the next steps. The usage of the multiQC is described here: [https://github.com/MultiQC/MultiQC](https://github.com/MultiQC/MultiQC) and in more detail here: [https://seqera.io/multiqc/](https://seqera.io/multiqc/). You have to install the program - see the [setup.md](./setup.md) file.

2. Files look ok. You can map them to the reference genome. I propose to use **BWA MEM** (installed in the *bio* Conda environment — just run `conda activate bio`). More information on BWA is available here: https://bio-bwa.sourceforge.net/bwa.shtml.  
I provided the *Saccharomyces cerevisiae* reference genome here (version from Ensembl, R64-1-1): `/mnt/storage/projects/MA_experiment_ZGE/genome/`.
You will find the FASTA file, its index, and BWA reference files there. You do not need to copy them, but please check that you have access.

3. BWA doesn't handle multiple FASTQ files per sample if you want to obtain one BAM file per sample. You can therefore:  
  A) merge the FASTQ files per sample (`*_1.fq.gz` and `*_2.fq.gz`) and then map them. Be careful — `_1.fq.gz` and `_2.fq.gz` must be concatenated in the same order.   
  B) alternatively, map the files separately and then concatenate the BAM files with `samtools cat`. You must assign the same read group (RG) in both BAMs belonging to the same sample. Samtools are installed in the *bio* environment.

4. Mark duplicates using **GATK MarkDuplicates**. In short, this step ensures that during further analysis each DNA fragment is considered only once. During preparation of sequencing libraries, DNA is fragmented and often amplified with PCR (our libraries were prepared with amplification). As a result, the same DNA fragment can appear multiple times in the final FASTQ files. This tool attempts to identify such cases and mark duplicated reads (by modifying the SAM flag column), so they will not be used during coverage calculation or variant calling. More information: https://gatk.broadinstitute.org/hc/en-us/articles/360037052812-MarkDuplicates-Picard , GATK is installed in bio environment.   

5. Sort and index the final BAM files (samtools sort, samtools index).   
6. Finally, check metrics of the final BAM files to verify that the mapping was successful and to see whether there might be contamination (e.g. a low percentage of mapped reads). For this, use samtools flagstat. Save the results to text files and summarize them with MultiQC.  

Please put all scripts and the MultiQC report in the repository. I shared my scripts from the previous analysis here; you can use them as a guide:  
  - [alignment script](./scripts/align.sh)  
  - [flagstats](./scripts/bam-stats.sh)   

Run everything in a screen session and activate the appropriate conda environment inside the session. Please save logs to files, as this will help us identify and debug any errors.  
For example, when running a script you can redirect both standard output and error to a log file:
```
./script.sh > script.log 2>&1
```  
Alternatively, if you want to see the output on the screen and save it to a file at the same time, you can use:   
```
./run_mapping.sh 2>&1 | tee run_mapping.log   
```
Remember to put your name in the calendar. It shouldn't be a large job — about one day of compute time and ~40 threads should be enough.

## After aligment  
1) What do you think about the alignment? Take a look at the flagstats report. Do you have a high mapping rate? Are many reads unaligned? If so, you might suspect contamination. If almost all reads are properly aligned to the reference, then everything is fine.  
2) Now, you can use the BAM files (the final ones, sorted and with duplicates marked) to call small variants and copy number variants. 

### Small variant calling
 Use gatk HaplotypeCaller, as authors in the original paper also used this caller. I added the needed reference files (`scer.dict` and `scer.fa.fai` to the `mnt/storage/projects/MA_experiment_ZGE/genome/` folder). Force the output VCF to be in bgzipped format:  
  ```
  gatk HaplotypeCaller \
	-I bam \
	-R scer.fa \
	-V sample.vcf.gz
 ```
GATK is installed in the bio Conda environment.  
Then, modify and filter the output VCF: 
A) Split multiallelic records and normalize indels:  
```
bcftools norm -f scer.fa -m -any sample.vcf.gz -o sample_norm.vcf.gz -Oz
bcftools index -t sample_norm.vcf.gz
```
Bcftools is also installed in the `bio` environment.   
B) Filter variants. For this, you can use `bcftools filter` with the `-e` (*exclude*) or `-i` (*include*) options. You can read about filtering expressions here: [https://samtools.github.io/bcftools/bcftools.html#expressions](https://samtools.github.io/bcftools/bcftools.html#expressions). Contact me if you run into any issues.   
Which variants should be removed? You can use thresholds similar to those described here:   
 * [https://gatk.broadinstitute.org/hc/en-us/articles/360037499012-I-am-unable-to-use-VQSR-recalibration-to-filter-variants](https://gatk.broadinstitute.org/hc/en-us/articles/360037499012-I-am-unable-to-use-VQSR-recalibration-to-filter-variants)
 * [https://gatk.broadinstitute.org/hc/en-us/articles/360035531112--How-to-Filter-variants-either-with-VQSR-or-by-hard-filtering](https://gatk.broadinstitute.org/hc/en-us/articles/360035531112--How-to-Filter-variants-either-with-VQSR-or-by-hard-filtering)  
  
Note that SNPs and indels should be filtered differently.  
The filtering command will look something like this (but double-check it):
```
bcftools  filter -e 'TYPE="snp" & (INFO/FS > 60 | INFO/ReadPosRankSum < -8.0 | INFO/SOR > 3.0 | INFO/MQ < 40.0 | INFO/MQRankSum < -12.5)' sample_norm.vcf.gz \
    | bcftools filter -e 'TYPE="indel" & (INFO/FS > 200 | INFO/ReadPosRankSum < -20.0 )' \
    | bcftools filter -e 'QUAL<= 30.0'  -o sampe_filtered.vcf.gz -O z  
bcftools index -t sampe_filtered.vcf.gz   	
```	
C) After that, for each sample, calculate:   
* the fraction of homozygous variants (you should have almost no heterozygous variants if the strain is haploid)
* the fraction of indels (deletion of *MSH2* should lead to a high percentage of indels)  

D) Finally, check whether the identified variants correspond to those reported by the authors. See the [`MA line_sample key.xlsx`](./data/MA%20line_sample%20key.xlsx) file. or this, you can use the `bcftools isec` program:
```
bcftools isec A.vcf.gz B.vcf.gz -p result-dir
```
Here, A.vcf.gz and B.vcf.gz are the two files to be compared. To run the tool, you first need to convert the provided list of variants into VCF format. This can be done analogously to the [`make-pseudo-vcf.sh`](./scripts/make-pseudo-vcf.sh) script (lines 1-20). Calculate the percentage of overlapping variants for both samples, for example:
```
for i in  result-dir/*.vcf
do echo "$i"
 grep -v '^#' -c "$i"
done
```
Variants in 0002.vcf and 0003.vcf are shared between the two VCFs, whereas variants in 0000.vcf and 0001.vcf are specific to the first and second VCF, respectively.   

### Copy number variants (CNV) and aneuploidies  
To check whether you have any large copy number variants, you can use CNVkit (https://cnvkit.readthedocs.io/en/stable/) with settings for WGS (whole genome sequencing) analysis.  

The program can be installed in various ways (for example, via conda), but when I worked with other students, we encountered numerous problems with old versions and improperly working dependencies. Therefore, I recommend using a pre-built Docker image through Singularity. Installation (or more specifically, pulling a small container with the program pre-installed and converting it into a standalone environment or executable): 

```
## pull image from the repository and convert it into cnvkit.sif 
singularity pull cnvkit.sif docker://etal/cnvkit   

## check version
singularity exec cnvkit.sif cnvkit.py --version
```
Now, in your working directory (where you executed the above command), the `cnvkit.sif` file is present. Instead of directly running `cnvkit.py`, you need to use Singularity by entering `singularity exec path/to/cnvkit.sif cnvkit.py`, as above.  

To identify CNVs, CNVkit requires a reference created from BAM files of normal strains. In our case, we can use data from the strains in the KP experiment (normal diploids; note that ploidy is not crucial here, as long as we have uniform coverage across all chromosomes). I have prepared the reference (`reference.cnn`) for you and placed it in the `/mnt/storage/projects/MA_experiment_ZGE/genome/` directory:  
```
singularity exec cnvkit.sif cnvkit.py batch \
	--normal dna-seq-02-2026/bams/*bam \
	-m wgs \
	-f ~/scer-genome/scer.fa
```
Now, you can call variants like that:
```
singularity exec cnvkit.sif cnvkit.py batch sample.bam \
	--method wgs \
	--fasta scer.fa \
	--reference reference.cnn \
	-p 4
```	
The command above will produce several files: `sample.bintest.cns`, `sample.cnr`, `sample.cns`, `sample.targetcoverage.cnn`, and finally `sample.call.cns`. The latter file lists segments of the genome with different copy number estimates (column 8). This file can be easily recreated with different settings. The primary purpose of CNVkit is to identify CNVs in tumor samples, so you can try to adjust its parameters to better suit our yeast strains. (e.g., `--ploidy 1`, `--purity 1`, and `--vcf` to add information about allelic ratios of small variants).
```
singularity exec cnvkit.sif cnvkit.py call sample.cns \
	--method clonal \
	--purity 1 \
	--ploidy 1\
	--vcf sample_filtered.vcf.gz
	-o sample_haplo.call.cns
```
As we are unsure whether the samples are haploids, please run the above command with the `--ploidy` parameter set to `1`, and then run it again with the `--ploidy` set to `2` (with the output file sample_diplo.call.cns).

Finally, you can filter the calls and make plots:
```
## filter segments and regions
awk 'NR==1 || ($6 > -5 && $6 < 5)' sample.cnr > sample.filtered.cnr
awk 'NR==1 || ($5 > -5 && $5 < 5)' sample.cns > sample.filtered.cns
## make plot
singularity exec cnvkit.sif cnvkit.py scatter -s sample.filtered.cn{s,r} -o sample.pdf

## filter calls - remove genome segments with normal coverage, here for haploids:
head -1 sample_haplo.call.cns >  sample_filtered_haplo.call.cns
awk '($8 != 1 && $10 < 0.01 && $1 != "Mito")' sample_haplo.call.cns \
| sort -k1,1V -k2,2n >> sample_filtered_haplo.call.cns
```
For diploids, modify the condition for column 8 in the command above.

***
***
Place all scripts in the `scripts` directory of the repository. Put the files with the results of calculations on small variants (such as the fraction of indels, the fraction of heterozygous variants, and the fraction of allelic expected variants) in the `data` folder within the repository. Also, include the final, filtered CNV call.cns files and plots in the `data` folder.