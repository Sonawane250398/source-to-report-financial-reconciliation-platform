-- ============================================================
-- 01_schema.sql
-- Source-to-Report Financial Reconciliation Platform
-- Table definitions and load notes
-- ============================================================

-- Source transactions as received from the operational system.
-- This is the authoritative record before any transformation.
CREATE TABLE source_transactions (
    transaction_id      VARCHAR(20)     PRIMARY KEY,
    transaction_date    DATE            NOT NULL,
    department          VARCHAR(50)     NOT NULL,
    cost_center         VARCHAR(10)     NOT NULL,
    account_code        VARCHAR(10)     NOT NULL,
    transaction_type    VARCHAR(20)     NOT NULL,
    amount              DECIMAL(15,2)   NOT NULL,
    currency            VARCHAR(3)      DEFAULT 'USD',
    status              VARCHAR(20)     NOT NULL
);

-- Transformed reporting layer.
-- Records may be normalized, re-mapped, or aggregated.
-- Duplicates or mapping errors may exist here.
CREATE TABLE transformed_reporting (
    transaction_id          VARCHAR(20)     NOT NULL,
    reporting_period        VARCHAR(7)      NOT NULL,
    mapped_cost_center      VARCHAR(10)     NOT NULL,
    mapped_account          VARCHAR(10)     NOT NULL,
    normalized_amount       DECIMAL(15,2)   NOT NULL,
    transformation_status   VARCHAR(20)     NOT NULL
);

-- Final report output summarized by period, cost center, and account.
CREATE TABLE final_report_output (
    reporting_period        VARCHAR(7)      NOT NULL,
    mapped_cost_center      VARCHAR(10)     NOT NULL,
    mapped_account          VARCHAR(10)     NOT NULL,
    total_amount            DECIMAL(15,2)   NOT NULL,
    record_count            INT             NOT NULL,
    PRIMARY KEY (reporting_period, mapped_cost_center, mapped_account)
);

-- Valid account codes for mapping validation.
CREATE TABLE valid_accounts (
    account_code    VARCHAR(10)     PRIMARY KEY,
    account_name    VARCHAR(100)    NOT NULL
);

INSERT INTO valid_accounts VALUES ('4010', 'Operating Expenses');
INSERT INTO valid_accounts VALUES ('4020', 'General and Administrative');
INSERT INTO valid_accounts VALUES ('5010', 'Sales and Marketing');
INSERT INTO valid_accounts VALUES ('6010', 'Human Resources');
INSERT INTO valid_accounts VALUES ('7010', 'Information Technology');

-- Valid cost centers for mapping validation.
CREATE TABLE valid_cost_centers (
    cost_center     VARCHAR(10)     PRIMARY KEY,
    center_name     VARCHAR(100)    NOT NULL
);

INSERT INTO valid_cost_centers VALUES ('CC-100', 'Operations');
INSERT INTO valid_cost_centers VALUES ('CC-200', 'Finance');
INSERT INTO valid_cost_centers VALUES ('CC-300', 'Marketing');
INSERT INTO valid_cost_centers VALUES ('CC-400', 'Human Resources');
INSERT INTO valid_cost_centers VALUES ('CC-500', 'Information Technology');

-- ============================================================
-- Load notes
-- ============================================================
-- source_transactions.csv      → source_transactions
-- transformed_reporting.csv    → transformed_reporting
-- final_report_output.csv      → final_report_output
--
-- Load order: schema first, then CSVs, then run validation checks.
