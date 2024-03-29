
## Scripts for analysis and figures

#### DMR analysis
* `run_dmrseq_age.R` Import methylation counts generated by bismark, and detect regions with differential methylation between old and young healhty females, and between the sigmoig and cecum segments of the colon of these same females.
* `run_dmrseq_lesions.R` Same as above, but between SSA/Ps Vs paired normal mucosa, and cADN Vs paired normal mucosa.

#### Figures in paper
* `heatmaps.R` Script to draw heatmaps from figure 1 and supp. figures 2 and 3.
* `density_plots.R` to draw density plot in figure 2A and supp. figure 4A.
* `scatter_plots.R` to draw ggpairs plot from figure 2B, and bin2d plot from figure 3A.
* `upsets.R` to draw upset plot from figure 3B.
* `Luo.R` to download beta values from [GEO:GSE48684](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE48684) and plot figure 4A.
* `DiezVillanueva.R` Code to download beta values from [GEO:GSE131013](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE131013) and plot figure 4B.
* `Luebeck.R` Code to download beta values from [GEO:GSE113904](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE113904).
* `TCGA_dat.R` Code to download beta values from curated TCGA-COAD data and plot supp. figure.

#### Extras
* `overlap_regions.R` to obtain and filter for lesion-specific DMRs, used as biomarkers for figure 4.
* `get_table_with_annots.R` to annotate DMRs generated by `dmrseq`.
* `create_bigwigs.R` to generate bigwigs to visualize in IGV.
* `combine_bsseq.R` Generate `bsCombined`, used in most plots.
* `helpers.R` for heatmaps.
* `plot_annotation.R` to calculate and plot DMR genomic/CpG island annotations.
