## 1. Update export_service.dart — Therion export method

- [x] 1.1 Add `encoding  utf-8` as the first line of the output buffer
- [x] 1.2 Replace `units length meters` with `units length depth meters`
- [x] 1.3 Add `walls on` directive inside the centerline block
- [x] 1.4 Add `date` field derived from the first survey point's timestamp (`YYYY.MM.DD` format)
- [x] 1.5 Add comment block (source file reference and column description) before data rows
- [x] 1.6 Change data declaration from `data normal from to length compass clino` to `data diving from to length compass fromdepth todepth`
- [x] 1.7 Filter out points where `rtype == 'auto'` before building legs
- [x] 1.8 Build a sequential 0-based index map over the remaining non-auto points
- [x] 1.9 Compute each leg using the new index: `from = index[i]`, `to = index[i+1]`, `length = point[i+1].distance - point[i].distance`, `compass = point[i+1].heading`, `fromdepth = point[i].depth`, `todepth = point[i+1].depth`
- [x] 1.10 In the `data dimensions` centerline block, use the same 0-based sequential index for station numbers (matching the renumbered centerline stations)

## 2. Update spec

- [x] 2.1 Mark `MODIFIED` requirement for Therion Export in `data-import-export` spec delta

## 3. Tests

- [x] 3.1 Update / add widget or unit test covering:
  - Auto points absent from exported output
  - Station numbers are 0-based sequential
  - `encoding  utf-8` present as first line
  - `data diving` declaration present
  - `fromdepth` / `todepth` values match point depth fields
  - `date` line present in correct format
