# v0.8.0

- Added `st_export_subsystem_paths.m` as a separate manual CUT-path matching helper.
- Exports every actual Subsystem from the selected model to `TestManagement.xlsx / ModelSubsystems`.
- `CUTName` in the inventory is indented using actual Simulink hierarchy depth.
- Added `RawCUTName`, numeric `Depth`, `ParentName`, `RelativePath`, and `FullPath`.
- Inventory depth does not use Targets-sheet depth/indent data.
- Reuses `runtime_target.mat` by default; `st_export_subsystem_paths(true)` forces model reselection.
- Existing automatic/recommendation Path Finder remains optional.

---

# Changelog

## v0.7 - Context-aware path recommendation

- Excel depth/indent is not used.
- Added a hard filter for duplicated CUT candidates:
  - if a later Excel CUT has a confidently resolved path,
  - a current CUT candidate located under that later CUT is removed before scoring.
- Added context-aware scoring from multiple nearby resolved CUT paths.
- Added a stable context root so one recently selected deep branch does not dominate every following recommendation.
- Duplicate-selection dialog now shows nearby physical Excel rows and resolved paths.
- Added `cfg.PathFinderExcelContextRows`.
- Replaced `cfg.PathFinderPreviewSelection` with `cfg.PathFinderHighlightSelection`.
- Highlight is optional and defaults to `false`.
- PathFinderResult now includes `FilteredCount` and `ContextRoot`.

## v0.6

- Added anchor-based recommendation for duplicated CUT names.
- Existing valid paths and unique matches are used as anchors.
- Added `st_score_path_candidates.m`.
