# Import packages
library("ggplot2")
library("ggtree")

# Import files with the ids of the tips in the tree, the phylum corresponding to each tip, and the names of the tips
ids<-read.table('headers.txt')
phylum<-read.table("phylum.txt")
names<-read.table("names.txt")

# Combine input files to a data.frame containing all metadata of each tip
tip_metadata<-data.frame(Label=ids, Phylum=phylum, Gene=names)
colnames(tip_metadata) <- c("Label", "Phylum", "Gene")

# Re-order the phylum information for the plot
tip_metadata$Phylum<-factor(tip_metadata$Phylum, levels = c("Mobile", "Actinobacteria", "Bacteroidetes", "Firmicutes", "Proteobacteria", "Miscellaneous", "Metagenome"))

# Add labels to tree outgroup
tip_metadata<-rbind(tip_metadata, c("KsgA", NA, "KsgA"))
tip_metadata<-rbind(tip_metadata, c("APH2IIIa", NA, "APH(2'')-IIIa"))
tip_metadata<-rbind(tip_metadata, c("APH2IIa", NA, "APH(2'')-IIa"))
tip_metadata<-rbind(tip_metadata, c("APH2Ie", NA, "APH(2'')-Ie"))

# Define colors and shapes of tips
phylum_cols<-c("#000000","#8da0cb","#66c2a5","#fc8d62","#e78ac3","#C8C8C8","#FFFFFF")
phylum_shape<-c(21,21,21,21,21,21,21,1)

# Import phylogenetic tree in newwick format and plot with ggtree
tree <- read.tree("tree.txt")
p <- ggtree(tree, layout='circular')

p <- p %<+% tip_metadata + 
  geom_tippoint(aes(fill=Phylum, shape = Phylum), size=4.5, color="black", stroke=0.7) + 
  scale_fill_manual(values=phylum_cols) + 
  scale_shape_manual(values = phylum_shape) +
  theme(legend.position = c(0.9, 0.62), legend.title=element_text(size=24), legend.text=element_text(size=22)) +
  guides(shape=guide_legend(override.aes = list(size = 6))) +
  geom_tiplab(aes(subset=!is.na(Gene), label=Gene), align=T, fontface='bold', size=7) +
  geom_tiplab(aes(subset=is.na(Gene), label=Gene), align=F)

# Plot tree and save into pdf
pdf("tree_annotated.pdf",height = 25, width = 25)
plot(p)
dev.off()
