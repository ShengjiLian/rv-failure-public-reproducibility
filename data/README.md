# Generation inputs

The public scientific pipeline requires **22 frozen generation inputs**. None of these files is redistributed in this repository.

The authoritative acquisition contract is:

`INPUT_ACQUISITION_SPEC.csv`

For every input it records the exact repository-relative destination, expected byte count, SHA-256, official source page, acquisition method and provider/terms note.

Current acquisition status:

- 21 inputs use official direct HTTPS download locations.
- 1 input, `h.all.v2026.1.Hs.symbols.gmt`, requires an authenticated/manual MSigDB download.
- all 22 inputs remain exact byte/SHA-bound to the clean-room authority.

Use:

1. `DOWNLOAD_PUBLIC_INPUTS.bat`
2. manually obtain the MSigDB GMT when prompted
3. `VERIFY_INPUTS.bat`

Do not substitute historical downstream results, renamed files or same-accession alternatives. Execution is permitted only after all 22 exact input identities pass.
