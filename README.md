# Simulink Test Automation v0.7

## Recommended entry flow

```matlab
st_setup
st_find_target_paths
st_run_from_harness
```

Use `st_run_after_harness` when the harnesses already exist.

## CUT path discovery

`st_find_target_paths` selects one Simulink model and resolves every enabled `CUTName` in `TestManagement.xlsx`.

Excel does not need a model column. Excel depth/indent information is intentionally not used because it may be incomplete or inaccurate.

### Duplicate CUT names

The path finder first resolves confident anchors:

1. an existing `CUTPath` that still matches the CUT, and
2. CUT names having exactly one subsystem match.

For duplicated CUT names, v0.7 applies two stages.

### 1. Later-CUT hard filter

A current CUT candidate is removed before scoring when it is located under a later Excel CUT whose path is already confidently resolved.

Example:

```text
Excel: A, B, C, D, E
D = MODEL/A/C/D

Candidate B = MODEL/A/C/D/Internal/B
-> excluded
```

This prevents a CUT appearing earlier in Excel from being recommended below a confidently known later CUT.

### 2. Context-aware recommendation

Remaining candidates are scored using several nearby resolved paths instead of relying on only the closest previous row. The scorer derives a stable context root supported by multiple nearby anchors and combines that with parent/common-ancestor/tree-distance evidence.

Excel row distance is only a weak hint and never implies parent-child hierarchy.

## Excel context in the selection dialog

When a duplicated CUT requires manual selection, the dialog shows the current physical Excel row and nearby rows, including already resolved relative paths.

Configure the range with:

```matlab
cfg.PathFinderExcelContextRows = 3;
```

## Optional Simulink highlight

Highlighting is now independent from path recommendation.

```matlab
cfg.PathFinderHighlightSelection = false;
```

- `false`: select directly from the ranked list; Simulink view is not moved.
- `true`: open/highlight the selected candidate and ask for confirmation.

## Path finder configuration

```matlab
cfg.ModelSearchRoot = fileparts(rootDir);
cfg.ModelSearchRecursive = true;
cfg.PathFinderAnchorCount = 5;
cfg.PathFinderExcelContextRows = 3;
cfg.PathFinderHighlightSelection = false;
```

## Management Excel

Required columns remain:

- `CUTName`
- `CUTPath`
- `HarnessName`
- `TestCaseName`

Optional:

- `No`
- `Enabled`

Resolved paths are written back only to the existing `CUTPath` column.
