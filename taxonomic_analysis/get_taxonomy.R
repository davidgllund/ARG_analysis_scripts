library("taxonomizr")
library("stringr")

#-------------------------------------------------------------------------------------------------------------------------------------------------
# Section 0.2: Obtain taxonomy of bacteria
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Import headers and adjust list
headers<-data.frame(read.table('headers.txt'))
headers_split<-as.data.frame(t(data.frame(strsplit(as.character(headers[,1]),"_",fixed=TRUE))))
headers_split2<-as.character(headers_split$V1)

# For the headers, get corresponding taxonomy
id<-accessionToTaxa(headers_split2,"~/Aminoglycoside resistance project/R files/accessionTaxa.sql", version = "version")
taxonomy<-data.frame(getTaxonomy(id,"~/Aminoglycoside resistance project/R files/accessionTaxa.sql"))
rownames(taxonomy)<-headers$V1

# Export the taxonomy table
write.table(taxonomy,"taxonomy.txt",row.names = TRUE,col.names = FALSE,quote = FALSE, sep="\t")
