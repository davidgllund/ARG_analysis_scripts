#-------------------------------------------------------------------------------------------------------------------------------------------------
# Section 0.1: Load packages and functions
#-------------------------------------------------------------------------------------------------------------------------------------------------
library("taxonomizr")
library("ggplot2")
library("ggtree")
library("ape")
library("stringr")
library("gtools")
library("phangorn")
library("randomcoloR")
library("ggnewscale")

isEmpty <- function(x) { #This function checks if a data frame is empty or not
  return(length(x)==0)
}

paste3 <- function(...,sep=", ") {
  L <- list(...)
  L <- lapply(L,function(x) {x[is.na(x)] <- ""; x})
  ret <-gsub(paste0("(^",sep,"|",sep,"$)"),"",
             gsub(paste0(sep,sep),sep,
                  do.call(paste,c(L,list(sep=sep)))))
  is.na(ret) <- ret==""
  ret
}

#-------------------------------------------------------------------------------------------------------------------------------------------------
# Section 0.2: Prepare necessary files
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Import headers and adjust list
headers<-data.frame(read.table('headers.txt'))
headers_split<-as.data.frame(t(data.frame(strsplit(as.character(headers[,1]),"_",fixed=TRUE))))
headers_split1.1<-str_replace(as.character(headers_split[,1]),">","")
headers_split1.2<-data.frame(V1=headers_split1.1,V2=headers_split[,2])
headers_split2<-as.character(headers_split$V1)

# For the headers, get corresponding taxonomy
id<-accessionToTaxa(headers_split2,"accessionTaxa.sql", version = "version")
taxonomy<-data.frame(getTaxonomy(id,"accessionTaxa.sql"))

# Make sure no weird characters are included
taxonomy$phylum<-str_replace(taxonomy$phylum,"\\[","")
taxonomy$phylum<-str_replace(taxonomy$phylum,"\\]","")
taxonomy$phylum<-str_replace(taxonomy$phylum,"\\:","")
taxonomy$phylum<-str_replace(taxonomy$phylum,"\\(","")
taxonomy$phylum<-str_replace(taxonomy$phylum,"\\)","") 
taxonomy$phylum<-str_replace_all(taxonomy$phylum,"\\'","")

#-------------------------------------------------------------------------------------------------------------------------------------------------
# Section 1: Plot data 
#-------------------------------------------------------------------------------------------------------------------------------------------------

# Import simplified phylum information
simplified_phyla<-read.table('phylum.txt')
phylum_metadata<-data.frame(paste(headers_split1.2$V1,"_",headers_split1.2$V2,sep = ''))
phylum_metadata$phylum<-simplified_phyla

row.names(phylum_metadata)<-phylum_metadata$paste.headers_split1.2.V1..._...headers_split1.2.V2
phylum_metadata2<-data.frame(phylum_metadata[,-1])
row.names(phylum_metadata2)<-row.names(phylum_metadata)

# Compile BLAST results
blast_results<-read.table('names.txt')
blast_metadata<-data.frame(paste(headers_split1.2$V1,"_",headers_split1.2$V2,sep = ''))
blast_metadata$blast_result<-blast_results

row.names(blast_metadata)<-blast_metadata$paste.headers_split1.2.V1..._...headers_split1.2.V2
blast_metadata2<-data.frame(blast_metadata[,-1])
row.names(blast_metadata2)<-row.names(blast_metadata)

# Define colorschemes
phylum_cols<-c("#000000","#377eb8","#4daf4a","#ff7f00","#984ea3","#C8C8C8","#FFFFFF")
phylum_shape<-c(21,21,21,21,21,21,21,1)

# Generate new tiplabels for the tree
gene<-as.character(blast_results[,1])
labels<-as.data.frame(matrix(ncol=1, nrow=length(gene)))

for (i in 1:length(gene)){
  if (!is.na(gene[i])){
    labels[i,1] <- gene[i]
  }
}

row.names(labels)<-row.names(blast_metadata)

# Import phylogenetic tree in newwick format and plot with ggtree
tree <- read.tree("tree.txt")
p <- ggtree(tree, layout='circular')

# Define metadata to plot
tip1<- read.table("phylum.txt", sep="\t", header=FALSE,check.names=FALSE, stringsAsFactor=F)
tip2 <- rownames(phylum_metadata2)

tip_metadata <- data.frame(Label=tip2, Phylum=tip1, Gene=labels[,1])
colnames(tip_metadata) <- c("Label", "Phylum", "Gene")

tip_metadata$Phylum<-factor(tip_metadata$Phylum, levels = c("Mobile", "Actinobacteria", "Bacteroidetes", "Firmicutes", "Proteobacteria", "Miscellaneous", "Metagenome"))

tip_metadata<-rbind(tip_metadata, c("APH2IIIa", NA, "APH(2'')-IIIa"))
tip_metadata<-rbind(tip_metadata, c("APH2IIa", NA, "APH(2'')-IIa"))
tip_metadata<-rbind(tip_metadata, c("APH2Ie", NA, "APH(2'')-Ie"))

p <- p %<+% tip_metadata + 
  geom_tippoint(aes(fill=Phylum, shape = Phylum), size=4.5, color="black", stroke=0.7) + 
  scale_fill_manual(values=phylum_cols) + 
  scale_shape_manual(values = phylum_shape) +
  theme(legend.position = c(0.9, 0.62), legend.title=element_text(size=24), legend.text=element_text(size=22)) +
  guides(shape=guide_legend(override.aes = list(size = 6))) +
  geom_tiplab(aes(subset=!is.na(Gene), label=Gene), align=T, fontface='bold', size=7) +
  geom_tiplab(aes(subset=is.na(Gene), label=Gene), align=F)

# Plot tree and save into pdf
pdf("results/tree_annotated.pdf",height = 25, width = 25)
plot(p)
dev.off()
