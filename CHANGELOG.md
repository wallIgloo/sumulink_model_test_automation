# Changelog

## v0.9.1

- Corrected the temporary CUTPath feature: hierarchy now comes from Excel CUTName cell `IndentLevel`, not a numeric `Depth` column.
- Added `st_fill_temp_paths_from_indent.m`.
- Converts a visually indented CUT list into one-line paths such as `MODEL/A/C/D`.
- Does not parse inserted spaces or `-` characters from CUTName values.
- Added `cfg.IndentPathOverwriteExisting` and `cfg.IndentPathResultSheet`.
- Kept `st_fill_temp_paths_from_depth.m` as a compatibility wrapper.
- Preserved requested defaults: Test File overwrite, generated Test Case execution, expected-value auto update, and rerun are all enabled.

## v0.9.0

- Added the first temporary-path helper. This numeric-Depth interpretation was corrected in v0.9.1.
