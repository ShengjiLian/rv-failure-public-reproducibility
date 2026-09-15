# R package requirements

The validated scientific execution environment used **R 4.6.1** and **Bioconductor 3.23**.

Exact directly checked/tested versions are recorded in:

`REPRODUCIBILITY_ENVIRONMENT_V1_0.csv`

The frozen release records the following versions:

| Package | Version |
|---|---:|
| BiocManager | 1.30.27 |
| DESeq2 | 1.52.0 |
| tximport | 1.40.0 |
| rhdf5 | 2.56.0 |
| ashr | 2.2.63 |
| fgsea | 1.38.0 |
| limma | 3.68.4 |
| edgeR | 4.10.1 |
| Matrix | 1.7.5 |
| SeuratObject | 5.4.0 |
| digest | 0.6.39 |
| ggplot2 | 4.0.3 |
| data.table | 1.18.6.1 |
| readxl | 1.5.0 |
| S4Vectors | 0.50.1 |
| SummarizedExperiment | 1.42.0 |
| sp | 2.2-3 |
| spam | 2.11-4 |

`BiocParallel` is queried only as an optional version-reporting probe in one frozen stage. Full `Seurat` is also probed for availability in the structural preflight, but the frozen contract explicitly sets `full_Seurat_required=NO`; **SeuratObject 5.4.0 is the required object runtime**.

Before scientific execution, run:

`VERIFY_ENVIRONMENT.bat`

The release intentionally does not vendor R packages and does not claim a complete transitive dependency lockfile. It does, however, record and verify the exact direct/tested package versions used by the accepted Windows clean-room execution.
