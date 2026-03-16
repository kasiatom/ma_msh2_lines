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
