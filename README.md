### About the scripts
The scripts in this repositiory are used to post-process and analyze novel antibiotic resistance gene sequences predicted in sequence data. The main analysis pipeline can be found in the script **phylogenetic_analysis.sh** in the **phylogenetic_analysis** directory (though some scripts found in this repository are unrelated to this pipeline).

### Dependencies
To run the scripts in this repository, the following software is required:
- Python >= 2.7.11
  - numpy >= 1.14.0
  - Biopython >= 2.2.31
- Usearch >= 8.0.1445
- mafft >= 7.464
- FastTree >= 2.1.10
- BLAST >= 2.2.31

### Descriptions of subdirectories
#### blast_scripts
This directory contains scripts that can be used to BLAST predicted ARG sequences against a database of reference ARG sequences and idenitfy which sequences represent known ARGs based on sequence similarity.

#### miscellaneous_scripts
This directory contains auxiliary Python scripts that can be used by themselves or as part of larger pipelines.

#### phylogenetic_analysis
This directory contains scripts that can be used to create phylogenetic trees from predicted ARG sequences. This directory contains the main pipeline phylogenetic_analysis.sh, which creates various results related to phylogenetic analysis, as well as the files necessary to run scripts in the visualization directory.

#### taxonomic_analysis
This directory contains scripts that can be used to analyze the taxonomy of hosts of predicted ARGs.

#### visualization
This directory contains scripts that can be used for visualization of the results from analysis of predicted ARGs.
