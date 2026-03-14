# Business Rules — Source-to-Report Financial Reconciliation

## Overview

This document defines the business rules applied during the reconciliation of financial transaction data across three layers: source, transformed, and final reporting.

## Data Flow

1. **Source transactions** are received monthly from the operational finance system.
2. **Transformation** normalizes amounts, maps cost centers and accounts, and assigns reporting periods.
3. **Final report** aggregates transformed records by period, cost center, and account for management reporting.

## Validation Rules

### Rule 1 — Completeness Check

Every posted source transaction must appear in the transformed layer. A missing record indicates data was dropped during transformation and must be investigated before the report is published.

### Rule 2 — Uniqueness Check

Each transaction ID should appear exactly once in the transformed layer. Duplicates inflate reported balances and distort cost center totals.

### Rule 3 — Amount Integrity

The source amount must equal the normalized amount in the transformed layer. Any difference, regardless of size, is flagged as a mismatch because financial reconciliation requires dollar-for-dollar accuracy.

### Rule 4 — Account Mapping Validity

Every mapped account in the transformed layer must exist in the approved account master. Unmapped or invalid accounts indicate a configuration issue in the transformation logic.

### Rule 5 — Cost Center Mapping Validity

Every mapped cost center in the transformed layer must exist in the approved cost center master. Invalid cost centers will cause the record to be excluded from departmental reporting.

### Rule 6 — Final Report Coverage

Transformed records should roll up into the final report. If a cost center and account combination exists in the transformed layer but not in the final report, the record was dropped during aggregation.

### Rule 7 — Balance Variance

The sum of transformed amounts by period should equal the corresponding total in the final report. Any variance indicates records were added, removed, or altered between layers.

## Exception Handling

All records that fail any validation check are written to the exception report with the issue type, affected transaction ID, and a remark explaining the failure. The reconciliation summary provides period-level counts and variances for management review.

## Approval Process

The exception report and reconciliation summary must be reviewed and resolved before the final report is approved for distribution. Unresolved exceptions block the reporting close process.
