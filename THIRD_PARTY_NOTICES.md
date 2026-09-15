# Third-party data and software notices

The MIT License in `LICENSE` applies to the original analysis code and original repository documentation in this release. It does **not** relicense third-party datasets, reference resources, journal source-data files, or R/Bioconductor packages.

## NCBI Gene Expression Omnibus (GEO)

The pipeline uses public GEO resources listed in `data/INPUT_ACQUISITION_SPEC.csv`. The repository does not redistribute those input datasets. Users obtain them from NCBI GEO and remain responsible for complying with any rights asserted by submitters or other copyright holders.

NCBI GEO states that NCBI places no restrictions on use or distribution of GEO data, while also noting that submitters may claim patent, copyright, or other intellectual-property rights in submitted material:
https://www.ncbi.nlm.nih.gov/geo/info/disclaimer.html

## Nature Cardiovascular Research source data

Four XLSX source-data files are obtained from:

Jafari L, Wiedenroth CB, Kriechbaum SD, et al.
*Transcriptional changes of the extracellular matrix in chronic thromboembolic pulmonary hypertension govern right ventricle remodeling and recovery.*
Nature Cardiovascular Research (2025).
https://doi.org/10.1038/s44161-025-00672-8

The article is open access under Creative Commons Attribution 4.0 (CC BY 4.0), subject to any separate credit line or third-party-material restriction. The repository links to the publisher files and does not redistribute them.

## MSigDB

The pipeline uses `h.all.v2026.1.Hs.symbols.gmt` from Human MSigDB v2026.1.Hs. The GMT is not included in this repository. Users should register/login at the official MSigDB site, obtain the exact file, place it at the documented path, and verify the required SHA-256.

Current MSigDB releases v2022.1 and above are provided under the MSigDB license framework based on CC BY 4.0, with additional terms applying to some gene sets:
https://www.gsea-msigdb.org/gsea/msigdb_license_terms.jsp

## R and Bioconductor packages

R, Bioconductor, CRAN packages and their dependencies retain their own licenses. They are not relicensed by this repository.
