# Reproducibility environment

The evidenced execution target is **Windows + Windows PowerShell 5.1 + R 4.6.1**.

The exact versions recorded from the accepted clean-room execution are listed in `REPRODUCIBILITY_ENVIRONMENT_V1_0.csv`. Full Seurat is not required; the localization workflow uses `SeuratObject`.

The runner expects a project-local R library at:

`R_library/R-4.6`

The project-local library is placed first in `R_LIBS_USER`; existing user/system libraries may follow. Before execution, run:

`VERIFY_ENVIRONMENT.bat`

The repository intentionally does not vendor R packages. Package licenses remain with their respective projects.

No Linux/macOS full scientific execution claim is made by this release. The validated target is Windows.
