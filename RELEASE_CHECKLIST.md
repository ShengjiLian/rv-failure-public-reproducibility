# GitHub release checklist

Before creating the canonical GitHub release:

- [ ] Repository tree equals the sealed release candidate.
- [ ] `LICENSE` is MIT and `THIRD_PARTY_NOTICES.md` is present.
- [ ] No generation input files are committed.
- [ ] No final figure-renderer or manuscript-assembly stage code is present.
- [ ] `reproducibility/SHA256SUMS.txt` verifies.
- [ ] `VERIFY_ENVIRONMENT.bat` passes on the validated Windows environment.
- [ ] `VERIFY_INPUTS.bat` passes after input acquisition.
- [ ] `DRY_RUN_SCIENCE_PIPELINE.bat` reports exactly 59 nodes and zero scientific execution.
- [ ] Replace `[GITHUB_REPOSITORY_URL]` in README and manuscript availability template.
- [ ] Create an immutable GitHub release/tag.
- [ ] Record final repository URL, tag/commit SHA and release archive SHA-256 in the manuscript.
