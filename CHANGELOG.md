# Changelog

## v0.6 - Anchor-based CUT path recommendation

- Improved `st_find_target_paths` for models containing many duplicated CUT names.
- The previous Excel row is no longer assumed to be the parent CUT.
- Existing valid CUT paths and unique CUT matches are resolved first and used as anchors.
- Ambiguous candidates are ranked by structural similarity to resolved anchors:
  - descendant / ancestor relationship
  - same parent / grandparent
  - common ancestor depth
  - tree distance
  - Excel row proximity as a secondary hint
- Both earlier and later uniquely resolved CUTs can contribute as anchors.
- Every manually confirmed ambiguous CUT immediately becomes a new anchor for the following CUTs.
- Candidate selection shows recommendation score, parent, grandparent, relative path, and strongest anchor relation.
- Optional Simulink preview/highlight before confirming an ambiguous candidate.
- Added `st_score_path_candidates.m` as an independently testable scoring helper.
- Added config options:
  - `cfg.PathFinderAnchorCount`
  - `cfg.PathFinderPreviewSelection`

## v0.5

- Added target-model selection and CUT path discovery.
- Selected model stored in `runtime_target.mat`.
- Excel remains model-column-free; one model is shared by all CUTs in one run.
