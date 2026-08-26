# Changelog

## v0.9.5

- Assessment output matching no longer performs or proposes slash deletion/name normalization.
- `st_configure_assessments` now matches Harness output names to Assessment Input symbols using exact raw names first.
- If raw names differ, a port-order fallback is allowed only when Harness Outport count and Assessment Input symbol count are identical.
- Fallback keeps the original Harness signal/outport names unchanged and uses the actual Assessment symbol name for verify generation.
- If a safe one-to-one match cannot be established, the automation fails with the unmatched raw Harness names and actual Assessment symbol names instead of guessing.
- Added `PortOrderFallbackCount` to `AssessmentResult`.

## v0.9.4

- Fixed Test Manager iteration setup for CUTs with no direct Inport.
- `st_create_test_manager` now uses the same direct-Inport condition as `st_configure_signal_editors`.
- When a CUT has no direct Inport, `SignalEditorScenario` is no longer assigned to `Iteration 1`.
- `TestSequenceScenario` is still assigned because the Test Assessment scenario is independent of CUT input existence.
- Added `HasDirectInport` and `SignalEditorScenarioApplied` columns to `TestManagerResult` for traceability.

## v0.9.3

- Changed `st_export_subsystem_paths` to exhaustive inventory mode for human path selection.
- Searches under masks and inside library links, Subsystem References, and Model References.
- Includes inactive variant choices with `Simulink.match.allVariants`.
- Includes commented blocks.
- Added `SourceModel` so paths returned from referenced models can be distinguished from the selected top model.
- Depth and relative path are now calculated from each returned subsystem's actual block-diagram root.
- Duplicate identical returned definition paths are removed while preserving order.


## v0.9.2

- Added `excel_open_diagnostic.py` to compare multiple xlwings workbook-opening paths against the same management workbook.
- Added `st_diagnose_excel_access.m` so the diagnostic can be launched directly from MATLAB.
- Safe default tests are read-only and never modify the original workbook.
- Optional `writeProbe=true` additionally checks whether Excel can open the workbook read-write without saving and whether a disposable workbook can be saved in the same directory.
- Diagnostic methods include:
  - `app.books.open(..., read_only=True)`
  - `app.api.Workbooks.Open(..., ReadOnly=True)`
  - `xw.Book(path, read_only=True)`
  - `xw.Book(path, mode='r')`
- JSON results are written to `result/ExcelAccessDiagnostic.json` when launched from MATLAB.
- Existing v0.9.1 indentation-path workflow and test execution defaults are unchanged.

## v0.9.1

- Corrected the temporary path feature to read Excel native cell indentation rather than a numeric Depth column.
- Added `st_fill_temp_paths_from_indent`.
- Kept `st_fill_temp_paths_from_depth` as a compatibility wrapper.
