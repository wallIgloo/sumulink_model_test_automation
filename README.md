# Simulink Test Automation v0.6

## Recommended entry flow

```matlab
st_setup
st_find_target_paths
st_run_from_harness
```

Use `st_run_after_harness` when the harnesses already exist.

## CUT path discovery

`st_find_target_paths` searches `.slx` / `.mdl` files, lets you select one target model, then resolves every enabled `CUTName` in `TestManagement.xlsx`.

Excel does not need a model column. One selected model is shared by all CUTs in the current run.

### Duplicate CUT names

When the same CUT name exists in many locations, v0.6 no longer presents an unranked list.

The resolver first establishes anchors from:

1. an existing `CUTPath` that is still valid, and
2. CUT names that have exactly one matching subsystem.

Ambiguous candidates are then ranked using the resolved anchors. Structural relationships are stronger evidence than Excel row order. The algorithm considers descendant/ancestor relationships, same parent or grandparent, common ancestor depth, tree distance, and Excel row proximity.

This means the row above the current CUT is useful context but is never assumed to be its parent.

After you confirm one ambiguous CUT, that path immediately becomes another anchor, making the next ambiguous CUT easier to rank.

### Candidate display

Candidates are shown in recommendation order with:

- score
- grandparent
- parent
- relative path
- strongest anchor and relation

With `cfg.PathFinderPreviewSelection = true`, the selected candidate is highlighted in Simulink and must be confirmed before it is written to Excel.

## Path finder configuration

```matlab
cfg.ModelSearchRoot = fileparts(rootDir);
cfg.ModelSearchRecursive = true;
cfg.PathFinderAnchorCount = 3;
cfg.PathFinderPreviewSelection = true;
```

`cfg.PathFinderAnchorCount` controls how many of the strongest resolved anchors contribute to each recommendation score. The best anchor has the largest weight.

## Management Excel

Expected columns remain:

- `CUTName`
- `CUTPath`
- `HarnessName`
- `TestCaseName`

Optional:

- `No`
- `Enabled`

`CUTPath` can be empty before the first path-finder run. Resolved paths are written back into the same column.
