# Simulink Test Automation v0.9.3


## v0.9.3 - exhaustive subsystem inventory

`st_export_subsystem_paths` now intentionally searches as broadly as possible for manual path selection. The inventory includes Subsystems under masks, inside library links, inside Subsystem References, inside recursively referenced models, inactive variant choices, and commented blocks.

Referenced-model internals can therefore appear with a `FullPath` rooted at that referenced model. A new `SourceModel` column makes the owning block diagram explicit. The inventory is intentionally permissive; copy only the desired `FullPath` into `Targets.CUTPath`, then use `st_pre_validate_targets` to reject paths that are not valid for the selected test workflow.


## Excel access diagnostic

If the company-managed Excel environment blocks one workbook-opening path but another Python/xlwings path works, run the diagnostic before changing the project Excel I/O implementation.

### From MATLAB

Safe read-only test:

```matlab
st_setup
st_diagnose_excel_access
```

The diagnostic compares these methods against `cfg.ManagementExcel`:

```text
app.books.open(..., read_only=True)
app.api.Workbooks.Open(..., ReadOnly=True)
xw.Book(path, read_only=True)
xw.Book(path, mode='r')
```

The result is printed in MATLAB and also saved to:

```text
result/ExcelAccessDiagnostic.json
```

To additionally test whether the original workbook can be opened read-write without saving, and whether Excel can create/save a disposable workbook in the same directory:

```matlab
st_diagnose_excel_access(true)
```

The original `TestManagement.xlsx` is not modified by the diagnostic. The disposable write-probe workbook is deleted after the check.

If MATLAB cannot determine the intended Python executable, pass it explicitly:

```matlab
st_diagnose_excel_access(false, 'C:\Python311\python.exe')
```

### Directly from Python

```text
python excel_open_diagnostic.py TestManagement.xlsx
```

Optional write probe:

```text
python excel_open_diagnostic.py TestManagement.xlsx --write-probe
```

After running it on the company PC, the method that reports `OK` should be used for the Excel bridge. In particular, `mode='r'` is a different mechanism from the normal interactive Excel automation path and may require the appropriate xlwings feature/license.

## Recommended path workflow

### 1. Select the target model

```matlab
st_setup
st_select_target_model
```

### 2. Build temporary CUTPath values from Excel indentation

`Targets.CUTName` may already be visually hierarchical using Excel native cell indentation.

```text
A
    B
    C
        D
    E
```

Run:

```matlab
st_fill_temp_paths_from_indent
```

Generated one-line paths:

```text
TEST_TARGET_MODEL_NAME/A
TEST_TARGET_MODEL_NAME/A/B
TEST_TARGET_MODEL_NAME/A/C
TEST_TARGET_MODEL_NAME/A/C/D
TEST_TARGET_MODEL_NAME/A/E
```

The helper reads the actual Excel `IndentLevel` property. It does not parse leading spaces and does not use a numeric Depth column.

### 3. Export the actual model hierarchy when manual correction is needed

```matlab
st_export_subsystem_paths
```

Use `ModelSubsystems.FullPath` to correct any temporary path in `Targets.CUTPath`.

### 4. Validate and run

```matlab
st_pre_validate_targets
st_run_from_harness
```

If Harnesses already exist:

```matlab
st_run_after_harness
```

## Default test behavior

```matlab
cfg.OverwriteTestFile = true;
cfg.RunGeneratedTests = true;
cfg.AutoUpdateExpectedOnFail = true;
cfg.RerunAfterExpectedUpdate = true;
```
