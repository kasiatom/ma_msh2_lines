## PI staining  
Statistics are in the `results_cyto.tsv`. Below is the column description. However, I think that examining the plots (especially the histograms) may be more informative. It should be possible to use them to classify the MA strains into ploidy categories, at least haploid, diploid, or higher ploidy. In some cases, only a single peak is visible, but the fluorescence range could still be used for such classification. 

| Variable         | Description                                                                       |
| ---------------- | --------------------------------------------------------------------------------- |
| `well`           | well - in cytometry                                                               |
| `strain`         | strain                                                                            |
| `FSC_mean`       | mean FSC.A                                                                        |
| `FSC_median`     | median FSC.A                                                                      |
| `FSC_sd`         | standard deviation of FSC.A                                                       |
| `FSC_var`        | variance of FSC.A                                                                 |
| `FSC_CV`         | coefficient of variation of FSC.A                                                 |
| `FSC_min_90`     | lower cutoff limit of FSC.A                                                       |
| `FSC_max_90`     | upper cutoff limit of FSC.A                                                       |
| `FSC_range_90`   | range covering 90% of FSC.A measurements                                          |
| `log_FL2_mean`   | mean log2 fluorescence (FL2.A, PE)                                                |
| `log_FL2_median` | median log2 fluorescence (FL2.A, PE)                                              |
| `log_FL2_sd`     | standard deviation of log2 fluorescence (FL2.A, PE)                               |
| `log_FL2_var`    | variance of log2 fluorescence (FL2.A, PE)                                         |
| `log_FL2_CV`     | coefficient of variation of log2 fluorescence (FL2.A, PE)                         |
| `log_FL2_peak1`  | position of the highest peak of log2 fluorescence (FL2.A, PE)                     |
| `log_FL2_peak2`  | position of the second highest peak of log2 fluorescence (FL2.A, PE) - if present |
| `log_FL2_peak3`  | position of the third highest peak of log2 fluorescence (FL2.A, PE) - if present  |
| `n_FSC`          | number of measurements for FSC.A                                                  |
| `n_log_FL2`      | number of measurements for log2 fluorescence (data with fluorescence ≤ 0 removed) |



**Notes**  
All statistics are calculated for points within the range shown in the plots in the third column (between the vertical lines), excluding the 10% of points with extreme FSC.A values.  
FSC.A – approximation of cell size  
FL2.A – PI fluorescence, approximation of DNA content, Automatically detected peaks are marked with vertical lines (fourth column).   
No other gates/filters were applied.  


For this analysis I used [dna_content_analysis.R](../../scripts/dna_content_analysis.R) script.  

