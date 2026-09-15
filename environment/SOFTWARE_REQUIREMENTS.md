# Software requirements

Validated full-execution platform:

- Windows
- Windows PowerShell 5.1+
- R 4.6.1
- Bioconductor 3.23

Required command-line/runtime components:

- `Rscript.exe`
- `curl.exe` for public input acquisition
- `tar.exe` for the frozen R0 acquisition/extraction stage
- a ZIP extractor that preserves the repository hierarchy

The exact directly checked R package versions are listed in:

`REPRODUCIBILITY_ENVIRONMENT_V1_0.csv`

The scientific runner expects a project-local R library at:

`R_library/R-4.6`

and places that library first in the child R library stack. Existing user/system libraries may follow.

Before execution:

1. provision the package versions listed in `REPRODUCIBILITY_ENVIRONMENT_V1_0.csv`;
2. run `VERIFY_ENVIRONMENT.bat`;
3. acquire and verify the 22 frozen generation inputs;
4. run `DRY_RUN_SCIENCE_PIPELINE.bat`;
5. only then run `RUN_SCIENCE_PIPELINE.bat`.

Full Linux/macOS scientific-run parity is not claimed by this release. No CPU/RAM benchmark or complete transitive package lockfile is claimed.
