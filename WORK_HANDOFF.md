## Test Manager no-input rule

`st_configure_signal_editors` still skips CUTs that have no direct Inport. `st_create_test_manager` now mirrors that decision: it assigns `SignalEditorScenario` only when a direct CUT Inport exists. `TestSequenceScenario` is always assigned because the Assessment scenario remains required. `TestManagerResult` includes `HasDirectInport` and `SignalEditorScenarioApplied`.

## Exhaustive inventory rule

`st_export_subsystem_paths` is a discovery list, not a validity filter. It now includes linked-library internals, Subsystem Reference internals, recursively referenced-model internals, inactive variants, masked subsystems, and commented blocks. `SourceModel` identifies the owning block diagram. The user chooses the desired `FullPath`; `st_pre_validate_targets` remains the gate before harness creation.

# Simulink Test Automation - Work Handoff

## Current baseline: v0.9.4

The v0.9.1 Simulink/Test workflow is preserved. v0.9.2 adds a diagnostic layer for company-managed Excel environments where one Excel automation path may fail while another xlwings path succeeds. v0.9.3 broadens subsystem inventory discovery. v0.9.4 prevents Test Manager from assigning a nonexistent Signal Editor scenario to CUTs with no direct Inport.

## Excel diagnostic

Run:

```matlab
st_diagnose_excel_access
```

Safe read-only methods tested:

1. `app.books.open(..., read_only=True)`
2. `app.api.Workbooks.Open(..., ReadOnly=True)`
3. `xw.Book(path, read_only=True)`
4. `xw.Book(path, mode='r')`

Optional:

```matlab
st_diagnose_excel_access(true)
```

This additionally tests read-write opening without saving and creates/deletes a disposable workbook in the target directory. The original management workbook is not modified.

The machine-readable report is:

```text
result/ExcelAccessDiagnostic.json
```

Do not replace all Excel I/O with a guessed method before running this diagnostic on the company PC. Use the successful method as the basis for the next Excel bridge revision.

## Path workflow

1. `st_select_target_model`
2. `st_fill_temp_paths_from_indent`
3. `st_export_subsystem_paths` when manual correction is needed
4. `st_pre_validate_targets`
5. `st_run_from_harness` or `st_run_after_harness`

## Test defaults

```matlab
cfg.OverwriteTestFile = true;
cfg.RunGeneratedTests = true;
cfg.AutoUpdateExpectedOnFail = true;
cfg.RerunAfterExpectedUpdate = true;
```
