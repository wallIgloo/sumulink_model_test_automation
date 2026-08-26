# Simulink Test Automation v0.9

## Recommended path workflow

There are now three independent ways to prepare `Targets.CUTPath`.

### 1. Fast temporary path from Excel Depth

When `Targets` contains a `Depth` column, run:

```matlab
st_setup
st_fill_temp_paths_from_depth
```

Example:

```text
CUTName   Depth
A         0
B         1
C         1
D         2
E         1
```

Temporary paths:

```text
TEST_TARGET_MODEL_NAME/A
TEST_TARGET_MODEL_NAME/A/B
TEST_TARGET_MODEL_NAME/A/C
TEST_TARGET_MODEL_NAME/A/C/D
TEST_TARGET_MODEL_NAME/A/E
```

This function does not try to infer the correct model path from duplicate names. It only uses Excel row order and Depth. An exact-path existence check is recorded in `DepthPathResult`; paths that do not exist are still written as temporary values so they can be corrected manually.

By default existing/manual `CUTPath` cells are preserved:

```matlab
cfg.DepthPathOverwriteExisting = false;
```

Force regeneration of every path when needed:

```matlab
st_fill_temp_paths_from_depth(true)
```

`Depth` is optional for the rest of the automation; it is required only by this helper.

### 2. Export every real Subsystem path

```matlab
st_export_subsystem_paths
```

This recreates `TestManagement.xlsx / ModelSubsystems`. `CUTName` keeps the exact block name while the visual hierarchy is shown with Excel native `IndentLevel`. `Depth`, `ParentName`, `RelativePath`, and `FullPath` are taken from the actual Simulink model.

Use `FullPath` to manually correct any temporary paths that do not match.

### 3. Recommendation Path Finder

`st_find_target_paths` remains available as an optional recommendation-based helper.

## Run defaults in v0.9

The requested run/update behavior is now enabled by default:

```matlab
cfg.OverwriteTestFile = true;
cfg.RunGeneratedTests = true;
cfg.AutoUpdateExpectedOnFail = true;
cfg.RerunAfterExpectedUpdate = true;
```

Therefore the normal workflow recreates the Test File, runs generated Test Cases, updates failed verify RHS values from actual results, and reruns when an update occurred. Automatic expected-value adoption should be used intentionally because it treats current model output as the new expected value.

## Recommended full flow

```matlab
st_setup

% Optional: quickly fill CUTPath from Excel Depth
st_fill_temp_paths_from_depth

% Optional: inspect every actual subsystem and manually correct CUTPath
st_export_subsystem_paths

st_pre_validate_targets

st_run_from_harness
```

If Harnesses already exist, use `st_run_after_harness`.

---

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
