# RV Project — public scientific reproducibility

This repository contains the **core scientific analysis pipeline** for the human right-ventricular failure project.

## Public reproducibility scope

The public pipeline contains **59 frozen scientific nodes**, corresponding to Full94 sequences **1–47 and 53–64**. It covers:

- R0 discovery;
- R1 cross-cohort replication and sensitivity analysis;
- R2 supporting PAH context;
- R3 pulmonary endarterectomy / unloading analyses;
- stable program analyses;
- patient-level snRNA-seq and Xenium localization;
- R4A clinical-severity characterization;
- R4B patient-level PEA trajectory characterization;
- R4C NF → pRV → RVF progression characterization.

The following internally validated presentation/reporting stages are intentionally **outside the GitHub execution requirement**:

- Full94 48–52: paper-facing materialization and figure-preparation bridge;
- Full94 65–77: final main/supplementary figure renderers;
- Full94 78–94: manuscript, legends, literature and submission assembly.

No scientific model, sample universe, FDR family, threshold, frozen class, or conclusion is changed by this public-scope reduction.

## Reproducibility evidence

The broader internal Windows clean-room workflow completed **94/94 nodes** in V1.7 with no checkpoint reuse and no preseeded dynamic results.

The curated 59-node public scientific scope was then compared against the accepted local authority. The compact scientific-output comparison was FINAL_CLOSED: 304 critical files had already passed direct/canonical comparison; 70 remaining text differences were adjudicated as 69 run-specific provenance/receipt differences plus one R1 sensitivity summary whose only differing metric was `runtime_seconds`. Its Primary25 sensitivity table and 330-candidate ledger were exact SHA-256 matches.

The 59-node release runner is a frozen subset of that validated 94-node implementation. After public-scope curation, the release runner is required to pass a **59-node dry-run with zero scientific execution**. The scientific analyses were not needlessly re-executed a third time solely to re-prove the reduced public scope.

## Repository layout

- `code/stages/` — 59 frozen scientific stage scripts.
- `code/lib/` — runtime helper code.
- `runner/` — strict invocation and result-provenance envelope.
- `data/INPUT_ACQUISITION_SPEC.csv` — exact 22-input acquisition contract.
- `data/ACQUISITION.md` — data acquisition instructions.
- `environment/` — validated software/package versions.
- `reproducibility/` — frozen node scope, checksums, provenance and release manifests.
- `results/` — generated at runtime; no scientific outputs are preseeded.
- `scripts/paper/` — contains only two accepted R0 base-support scripts required by the scientific DAG; it does not contain manuscript or figure rendering code.

## Quick start — Windows

### 1. Prepare the repository

Clone or extract the repository to a normal local folder. Do not pre-populate `results/`.

### 2. Prepare R

Install R 4.6.1 and provision the exact directly tested package versions listed in:

`environment/REPRODUCIBILITY_ENVIRONMENT_V1_0.csv`

Create a project-local library at:

`R_library/R-4.6`

Then run:

`VERIFY_ENVIRONMENT.bat`

The release records the exact direct/tested package versions from the accepted clean-room environment. It does not claim a complete transitive dependency lockfile.

### 3. Acquire the 22 frozen inputs

Run:

`DOWNLOAD_PUBLIC_INPUTS.bat`

MSigDB requires manual login/download; follow the message printed by the helper and `data/ACQUISITION.md`.

Then run:

`VERIFY_INPUTS.bat`

All 22 inputs must pass exact byte and SHA-256 checks.

### 4. Inspect the execution plan without running science

Run:

`DRY_RUN_SCIENCE_PIPELINE.bat`

Expected result:

`PUBLIC_SCIENCE_DRY_RUN_COMPLETE nodes=59 analysis_nodes_executed=0`

### 5. Execute

Run:

`RUN_SCIENCE_PIPELINE.bat`

The strict runner creates a new invocation under `logs/invocations/`, forbids preseeded results, verifies stage-script hashes, and executes nodes in frozen order.

Expected terminal marker:

`PUBLIC_SCIENCE_PIPELINE_COMPLETE ... nodes=59`

Three nodes have prespecified non-zero handoff exits and are considered successful only when their frozen postconditions pass:

- C0264 → 21
- C0266 → 22
- C0275 → 34

Every other node requires exit 0.

## Output boundary

This repository reproduces the **core machine-readable scientific analyses**. It does not claim to rebuild final publication graphics or assemble the manuscript.

## Data sources

The exact files, source pages, direct links, bytes and SHA-256 values are in `data/INPUT_ACQUISITION_SPEC.csv`. Major sources include GEO accessions GSE345645, GSE240921, GSE198618, GSE249696, GSE249694, GSE291508, GSE345646 and GSE345643; source-data files from the 2025 Nature Cardiovascular Research CTEPH study; and Human MSigDB v2026.1.Hs Hallmark gene sets.

Third-party input files are not redistributed in this repository.

## License

Original code and original repository documentation are released under the **MIT License**. See `LICENSE`.

Third-party datasets and resources retain their own terms. See `THIRD_PARTY_NOTICES.md`.

## Validated platform

Windows is the validated full-execution target. Linux/macOS full-run parity is not claimed.

## Repository URL

Canonical GitHub repository:

[https://github.com/ShengjiLian/rv-failure-public-reproducibility](https://github.com/ShengjiLian/rv-failure-public-reproducibility)
