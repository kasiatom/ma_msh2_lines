library(flowCore)
library(flowClust)
library(ggplot2)
library(dplyr)
library(cowplot)
library(readr)

options(scipen = -1)

fs <-
	read.flowSet(path = "~/Documents/olga_szyszkowska/fcs/olga_110326/",
							 pattern = ".fcs",
							 alter.names = TRUE)

names <- read_tsv(file = "~/Documents/olga_szyszkowska/names.txt")
names_dict  <- setNames(names$strain, names$well)

stats_list <- list()
plots <- list()


find_peaks_stable <-
	function(x,
					 adjust = 1.5,
					 height_frac = 0.2,
					 min_dist = 0.5) {
		x <- x[is.finite(x)]
		d <- density(x, adjust = adjust)
		
		idx <- which(diff(sign(diff(d$y))) == -2)
		
		px <- d$x[idx]
		py <- d$y[idx]
		
		# filtr wysokości
		keep <- py > height_frac * max(py)
		px <- px[keep]
		py <- py[keep]
		
		# filtr odległości
		keep <- c(TRUE, diff(px) > min_dist)
		px <- px[keep]
		py <- py[keep]
		
		## zawsze trzy
		px <- px[order(py, decreasing = TRUE)]
		px <- px[1:3]
		
		return(px)
	}
## change order
desired_well_order <- c(
	## controls AS
	"B12",
	"A12",
	"E10",
	"G12",
	## MA strains
	"A10",
	"A11",
	"B10",
	"B11",
	"C10",
	"C11",
	"C12",
	"D11",
	"D12",
	"E11",
	"E12",
	"F10",
	"F11",
	"F12",
	"G10",
	"H10",
	"H12",
	## BY
	"G11",
	"H11",
	"D10" 
)

for (i in seq_along(fs)) {
	## wybierz dołek po indeksie
		ff <- fs[[i]]
	plot_idx <- 5 * (i - 1)
	
	## wypisz nazwę dołka
	well <- gsub(".*-([A-Z][0-9]+)\\.fcs", "\\1", sampleNames(fs)[i])
	df <- as.data.frame(exprs(ff))
	strain <- names_dict[well]
	
	plot1 <- ggplot(df, aes(FSC.A, SSC.A)) +
		geom_point(alpha = 1,
							 size = 0.1,
							 color = "#66c2a5") +
		theme_classic(base_size = 7) +
		ggtitle(strain) +
		theme(plot.title = element_text(size = 7)) +
		xlim(0, 2e6) + ylim(0, 4e6)
	
	print(plot1)
	#plots[[plot_idx +1 ]] <- plot1
	
	plot2 <- ggplot(df, aes(FSC.A, FSC.H)) +
		geom_point(alpha = 1,
							 size = 0.2,
							 color = "#fc8d62") +
		theme_classic(base_size = 7) +
		ggtitle(strain) +
		theme(plot.title = element_text(size = 7)) +
		xlim(0, 2e6) + ylim(0, 1e6)
	
	print(plot2)
	#plots[[plot_idx + 2 ]] <- plot2
	
	
	fsc_lim <- quantile(df$FSC.A, c(0.05, 0.95))
	
	plot3 <- ggplot(df, aes(log(FSC.A, 2))) +
		geom_histogram(bins = 100, fill = "#8da0cb") +
		geom_vline(
			xintercept = log(fsc_lim, 2),
			linetype = "dashed",
			color = "grey40"
		) +
		theme_classic(base_size = 7) +
		ggtitle(strain) +
		xlim(14, 20) + ylim(0, 2000) +
		theme(plot.title = element_text(size = 7))
	
	
	print(plot3)
	#plots[[plot_idx + 3]] <- plot3
	
	df_set <- df[df$FSC.A > fsc_lim[1] & df$FSC.A < fsc_lim[2], ]
	
	x <- log(df_set$FL2.A, 2)
	x <- x[!is.na(x)]   # usuń NA
	x <- x[is.finite(x)]  #
	
	peak_x <- find_peaks_stable(x)
	
	plot4 <- ggplot(df_set, aes(log(FL2.A, 2))) +
		geom_histogram(bins = 100,
									 fill = "#e78ac3",
									 alpha = 1) +
		theme_classic(base_size = 7) +
		geom_vline(xintercept = peak_x,
							 color = "grey40",
							 linetype = "dashed") +
		ggtitle(strain) +
		xlim(8, 18) +
		ylim(0, 2000) +
		theme(plot.title = element_text(size = 7))
	
	#plots[[plot_idx +4 ]] <- plot4
	print(plot4)
	
	plot5 <- ggplot(df_set, aes(log(FSC.A, 2), log(FL2.A, 2))) +
		geom_point(alpha = 1,
							 size = 0.2,
							 color = "#a6d854") +
		theme_classic(base_size = 7) +
		ggtitle(strain) +
		theme(plot.title = element_text(size = 7))
	
	print(plot5)
	#plots[[plot_idx + 5 ]] <- plot5
	
	plots[[well]] <- list(
		p1 = plot1,
		p2 = plot2,
		p3 = plot3,
		p4 = plot4,
		p5 = plot5
	)
	
	stats_list[[i]] <- data.frame(
		well = well,
		strain = strain,
		FSC_mean = mean(df_set$FSC.A),
		FSC_median = median(df_set$FSC.A),
		FSC_sd = sd(df_set$FSC.A),
		FSC_var = var(df_set$FSC.A),
		FSC_CV = var(df_set$FSC.A) / mean(df_set$FSC.A),
		FSC_min_90 = fsc_lim[1],
		FSC_max_90 = fsc_lim[2],
		FSC_range_90 = diff(fsc_lim),
		
		log_FL2_mean = mean(x),
		log_FL2_median = median(x),
		log_FL2_sd = sd(x),
		log_FL2_var = var(x),
		log_FL2_CV = var(x) / mean(x),
		
		log_FL2_peak1 = peak_x[1],
		log_FL2.peak2 = peak_x[2],
		log_FL2.peak3 = peak_x[3],
		
		
		n_FSC = nrow(df_set),
		n_log_FL2 = length(x)
	)
}
stats_in <- bind_rows(stats_list)
plots <- plots[desired_well_order]
plotlist <- unlist(plots, recursive = FALSE)
final_plot <- plot_grid(plotlist = plotlist, ncol = 5)

control_plots <- plot_grid(plotlist = plotlist[1:20], ncol = 5)

h <- 2 * i + 1
ggsave("plots_cyto.pdf",
			 final_plot,
			 width = 12,
			 height = h)

ggsave("plots_cyto_controlsAS.pdf",
			 control_plots,
			 width = 12,
			 height = 8.17)

write_tsv(stats_in, file = "results_cyto.tsv")