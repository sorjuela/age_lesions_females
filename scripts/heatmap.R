###################################################
## Draw heatmaps for figure 1 and supp Fig 2, 3
# Dec 17 2019
###################################################

suppressPackageStartupMessages({
  library(GenomicRanges)
  library(ComplexHeatmap)
  library(plyranges)
  library(dplyr)
  library(viridis)
  library(annotatr)
  library(bsseq)
})


#### load combined object ####
load("data/rdata/bsseqCombined.RData") ## generated from combine_bsseq.R

#Get meth table
gr <- rowRanges(bsCombined)
cov <- getCoverage(bsCombined, type = "Cov")
meth <- getCoverage(bsCombined, type = "M")
meth_vals <- meth /cov
colnames(meth_vals) <- paste0(colData(bsCombined)$patient,".",colData(bsCombined)$lesion)
mcols(gr) <- meth_vals
seqlevels(gr) <- paste0("chr",seqlevels(gr))

#Fix some annotations
colData(bsCombined)$state <- ifelse(is.na(colData(bsCombined)$state), 
                                    "Normal", colData(bsCombined)$state)

colData(bsCombined)$state <- ifelse(grepl("SSA|Adenoma", colData(bsCombined)$lesion), 
                                    colData(bsCombined)$lesion, colData(bsCombined)$state)

colData(bsCombined)$state <- ifelse(grepl("Adenoma", colData(bsCombined)$state), 
                                    gsub("Adenoma","cADN", colData(bsCombined)$state), 
                                    colData(bsCombined)$state)

colData(bsCombined)$state <- ifelse(grepl("SSA", colData(bsCombined)$state), 
                                    gsub("SSA","SSA/P", colData(bsCombined)$state), 
                                    colData(bsCombined)$state)

diagnosis <- ifelse(grepl("SSA|cADN", colData(bsCombined)$state), 
                                        colData(bsCombined)$state, "healthy")

colData(bsCombined)$diagnosis <- factor(gsub("Normal_","",diagnosis), 
                                        levels = c("healthy", "cADN", "SSA/P"))

colData(bsCombined)$tissue <- factor(ifelse(grepl("Normal", colData(bsCombined)$state), 
                                     "normal mucosa","lesion"), levels = c("normal mucosa","lesion"))


seg <- ifelse(colData(bsCombined)$segment == "C","cecum", colData(bsCombined)$segment)
colData(bsCombined)$seg <- factor(ifelse(seg == "A","ascend", seg), levels = c("sigmoid", "ascend", "cecum"))


age <- ifelse(colData(bsCombined)$age < 40, "<=40", "41-70")
age <- ifelse(colData(bsCombined)$age > 70, ">70", age)
colData(bsCombined)$age_group <- factor(age, levels = c("<=40", "41-70", ">70"))

#### Function to get matrix, to get annotations, draw heatmaps ####

hm_build <- function(regions, sampleidx, numregs=2000, mostvar = FALSE, 
                     split = "age_group", includeseg = FALSE,
                     title = "Most variable 2000 CpG promoters", numgroups = 2){
  
  hits <- findOverlaps(regions, gr)
  gr$DMR <- NA
  gr[subjectHits(hits)]$DMR <- queryHits(hits)
  
  gr_sub <- gr[!is.na(gr$DMR)]
  
  #use plyranges
  gr_dmr <- gr_sub %>% 
    group_by(DMR) %>% 
    summarise_at(
      colnames(meth_vals), mean, na.rm=TRUE
    )
  print(dim(gr_dmr))
  
  #Get matrix
  if(mostvar) {
  madr <- rowVars(as.matrix(gr_dmr)[,-1][,sampleidx])
  o <- order(madr, decreasing = TRUE)
  agg <- as.matrix(gr_dmr)[o,-1][1:numregs,sampleidx]
  #return(regions[queryHits(hits)][o][1:numregs])
  } else agg <- as.matrix(gr_dmr)[,-1][1:numregs,sampleidx] 

  #seriation to order samples
  agg[is.na(agg)] <- 0
  agg[is.nan(agg)] <- 0
  agg[is.infinite(agg)] <- 0
  
  #row annotation (meth change)
  if (numgroups == 2) {
  condit <- colData(bsCombined)[,split][idx]
  conds <- as.character(unique(condit))
  meth_change <- rowMeans(agg[,condit == conds[2]]) - rowMeans(agg[,condit == conds[1]])
  }
  
  #Colors
  col <- RColorBrewer::brewer.pal(n = 9, name = "YlGnBu")
  col_anot <- RColorBrewer::brewer.pal(n = 9, name = "Set1")
  purples <- RColorBrewer::brewer.pal(n = 3, name = "Purples")
  oranges <- RColorBrewer::brewer.pal(n = 3, name = "Oranges")
  greens <- RColorBrewer::brewer.pal(n = 3, name = "Greens")
  pinks <- RColorBrewer::brewer.pal(n = 4, name = "RdPu")[c(1,3:4)]
  
  #hm colors
  col_fun <- circlize::colorRamp2(c(0,0.2,1), c(col[9], col[7], col_anot[6]))
  
  #annot colors
  col_age <- purples[1:nlevels(colData(bsCombined)$age_group[idx])]
  names(col_age) <- levels(colData(bsCombined)$age_group[idx])
  
  col_diag <- oranges[1:nlevels(colData(bsCombined)$diagnosis[idx])]
  names(col_diag) <- levels(colData(bsCombined)$diagnosis[idx])
  
  col_tis <- greens[1:nlevels(colData(bsCombined)$tissue[idx])]
  names(col_tis) <- levels(colData(bsCombined)$tissue[idx])
  
  col_seg <- pinks[1:nlevels(colData(bsCombined)$seg[idx])]
  names(col_seg) <- levels(colData(bsCombined)$seg[idx])

  column_ha <- HeatmapAnnotation(Age = colData(bsCombined)$age_group[idx], #[ord] 
                                 Diagnosis = colData(bsCombined)$diagnosis[idx], #[ord]
                                 Tissue = colData(bsCombined)$tissue[idx], #[ord]
                                 col = list(Age = col_age,
                                            Diagnosis = col_diag,
                                            Tissue = col_tis
                                 ), 
                                 gp = gpar(col = "black"))
  
  if (numgroups == 2) {
  row_ha <- rowAnnotation("Change" = anno_lines(meth_change, 
                                              smooth = FALSE, #loess
                                              add_points = FALSE,
                                              axis_param = list(direction = "reverse",
                                                                gp = gpar(fontsize = 5)
                                                                )
                                              ))
  }

  if(includeseg) {
    column_ha <- HeatmapAnnotation(Age = colData(bsCombined)$age_group[idx],#[ord]
                                   Segment = colData(bsCombined)$seg[idx], #[ord]
                                   Diagnosis = colData(bsCombined)$diagnosis[idx], #[ord]
                                   Tissue = colData(bsCombined)$tissue[idx], #[ord]
                                   col = list(Age = col_age,
                                              Diagnosis = col_diag,
                                              Tissue = col_tis,
                                              Segment = col_seg
                                   ), gp = gpar(col = "black"))
  }
  
  #Plot
  hm <- Heatmap(agg, 
          na_col = "white",
          column_split = colData(bsCombined)[,split][idx], #[ord]
          top_annotation = column_ha,
          col = col_fun,
          row_km = 2, 
          clustering_distance_columns = "spearman",
          cluster_columns = TRUE,
          show_row_dend = FALSE,
          show_column_dend = TRUE,
          cluster_column_slices = FALSE,
          left_annotation = row_ha, ## remove with 3 groups
          row_title = title, 
          column_title = "Samples",
          column_title_side = "bottom",
          column_names_gp = gpar(fontsize = 8),
          heatmap_legend_param = list(title = "mean beta value",
                                      title_position = "lefttop-rot",
                                      grid_height = unit(1, "cm"),
                                      grid_width = unit(0.5, "cm")))
                                      #labels_gp = gpar(fontsize = 6)))
  
  return(hm)
}
  
#### most variable CGIs and Promoters ####

#Figure 1A
#islands
annotsgene <- c("hg19_cpg_islands")
annotations_cgi = build_annotations(genome = 'hg19', annotations = annotsgene)

idxfull <- rep(TRUE, ncol(bsCombined)) # all samples

hm_build(annotations_cgi, idxfull, numregs= 1000, split = "tissue", includeseg = TRUE,
         title = "1000 most variable CpG Islands", mostvar = TRUE)

#Figure 1B
idx <- colData(bsCombined)$state == "Normal" #selet all healthy fems
hm_build(annotations_cgi, idx, numregs= 1000, split = "age_group", includeseg = TRUE,
         title = "1000 most variable CpG Islands", mostvar = TRUE)


#Supp Figure 2A
#promoters
annotsgene <- c("hg19_genes_promoters")
annotations_genes = build_annotations(genome = 'hg19', annotations = annotsgene)
annotations_genes <- unique(annotations_genes) #unique transcripts, not genes
annotations_genes <- annotations_genes[!duplicated(annotations_genes$gene_id)]

hm_build(annotations_genes, idxfull, numregs= 1000, split = "tissue",
         title = "1000 most variable promoters", mostvar = TRUE, includeseg = TRUE)

#Supp Figure 2B
hm_build(annotations_genes, idx, numregs= 1000, split = "age_group", includeseg = TRUE,
         title = "1000 most variable promoters", mostvar = TRUE)


#Supp Figure 3A
idxnorm <- colData(bsCombined)$tissue == "normal mucosa" #select all normals

hm_build(annotations_cgi, idxnorm, numregs= 1000, split = "age_group", numgroups = 3,
         title = "1000 most variable CpG Islands", mostvar = TRUE, includeseg = TRUE)

#Supp Figure 3B
hm_build(annotations_cgi, idxnorm, numregs= 1000, split = "age_group", numgroups = 3,
         title = "1000 most variable promoters", mostvar = TRUE, includeseg = TRUE)



#count number of promoters overlapping islands of the ones here

# isles <- hm_build(annotations_genes, idx, numregs= 1000, split = "tissue", includeseg = TRUE,
#                   title = "1000 most variable promoters", mostvar = TRUE)
# proms <- hm_build(annotations_genes, idx, numregs= 1000, split = "tissue", includeseg = TRUE,
#                   title = "1000 most variable promoters", mostvar = TRUE)
# 
# subsetByOverlaps(proms, isles)
