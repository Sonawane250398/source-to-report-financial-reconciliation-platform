# Source-to-Report Financial Reconciliation Platform

## Business Problem

Financial reporting data moves through multiple processing layers before reaching the final report. During transformation, records can be dropped, duplicated, incorrectly mapped, or altered in ways that create reporting inaccuracies and weaken financial controls. Without a structured reconciliation step, these issues reach stakeholders undetected.

## Objective

Build a SQL-based reconciliation workflow that validates source transactions against transformed and final reporting outputs, identifies exceptions at every checkpoint, and produces summary reports before the final numbers are published.

## Data Flow Overview

```
Source Transactions → Transformation Layer → Final Report Output
         ↓                    ↓                      ↓
   (20 records)         (22 records*)          (11 summary rows)
                              ↓
                    Validation Checks (SQL)
                              ↓
              Exception Report + Reconciliation Summary
```

*Transformed layer contains 22 rows due to 2 duplicates and 2 missing source records.

## Validation Checks Performed

| Check | What It Detects |
|-------|-----------------|
| Completeness | Source records missing from the transformed layer |
| Uniqueness | Duplicate transaction IDs in the transformed layer |
| Amount integrity | Dollar differences between source and transformed amounts |
| Account mapping | Transformed accounts not in the approved account master |
| Cost center mapping | Transformed cost centers not in the approved cost center master |
| Final report coverage | Transformed records dropped before final aggregation |
| Balance variance | Period-level total differences between transformed and final layers |

## Outputs Generated

### Exception Report (`outputs/exception_report.csv`)

Each row represents one failed validation check with the issue type, transaction ID, source and transformed values, and a remark explaining the failure.

**Issues found:**
- 2 missing records (TXN-1005, TXN-1017)
- 2 duplicate transactions (TXN-1008, TXN-1009)
- 3 amount mismatches (TXN-1003, TXN-1012, TXN-1018)
- 1 invalid account mapping (TXN-1007 → account 9999)
- 1 invalid cost center mapping (TXN-1014 → CC-999)

### Reconciliation Summary (`outputs/reconciliation_summary.csv`)

Period-level totals across all three layers with variance amounts and exception counts. Used for management review before report sign-off.

## Key Findings

- **$8,200 total variance** between transformed and final report totals across both periods, driven by duplicate records inflating the final numbers.
- **2 posted source records** were never transformed, meaning $7,000 in expenses was excluded from reporting.
- **Invalid mappings** for 2 transactions would cause those records to be excluded from standard departmental reports.
- **3 amount mismatches** totaling $850 in net difference would distort cost center-level accuracy.

## Tools Used

- SQL (PostgreSQL-compatible syntax)
- CSV for data files and outputs
- Markdown for documentation

## How to Run

1. Load the schema and reference data using `sql/01_schema.sql`.
2. Import the three CSV files from the `data/` folder into their respective tables.
3. Run `sql/02_validation_checks.sql` to identify all exceptions.
4. Run `sql/03_reconciliation_summary.sql` to generate period-level variance totals.
5. Compare SQL output to the pre-built files in `outputs/` to verify results.

## Project Structure

```
├── data/
│   ├── source_transactions.csv         Source system extract (20 records)
│   ├── transformed_reporting.csv       Transformed layer (22 records, includes issues)
│   └── final_report_output.csv         Final aggregated report (11 summary rows)
├── sql/
│   ├── 01_schema.sql                   Table definitions and reference data
│   ├── 02_validation_checks.sql        All exception detection queries
│   └── 03_reconciliation_summary.sql   Period-level variance summary
├── outputs/
│   ├── exception_report.csv            Flagged records from validation checks
│   └── reconciliation_summary.csv      Aggregated metrics for management review
├── docs/
│   └── business_rules.md               Validation rules and approval process
└── README.md
```
