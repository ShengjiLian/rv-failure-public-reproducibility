# Input acquisition and integrity

This public scientific pipeline requires **22 frozen generation inputs**. They are **not included** in the GitHub repository.

`INPUT_ACQUISITION_SPEC.csv` records, for every required input:

- source accession/provider;
- exact destination path;
- expected file size;
- expected SHA-256;
- official source page;
- direct download URL where automated download is appropriate;
- acquisition mode and third-party terms note.

## Recommended workflow

1. From the repository root, run `DOWNLOAD_PUBLIC_INPUTS.bat`.
2. The helper downloads every direct-HTTPS input into a temporary `.part` file and only renames it after exact byte/SHA verification.
3. MSigDB requires manual registration/login. Download `h.all.v2026.1.Hs.symbols.gmt` from the official MSigDB site and place it at:
   `data/authority/MSigDB/h.all.v2026.1.Hs.symbols.gmt`
4. Run `VERIFY_INPUTS.bat`.
5. Continue only when all 22 inputs report `PASS`.

Existing files are never silently overwritten. A non-identical existing file causes a fail-closed stop.

The expected input set totals approximately 5.66 GiB in the accepted clean-room run.
