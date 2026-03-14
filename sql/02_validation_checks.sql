-- ============================================================
-- 02_validation_checks.sql
-- All exception checks between source, transformed, and final layers
-- ============================================================

-- ------------------------------------------------------------
-- CHECK 1: Missing records
-- Source transactions not found in the transformed layer.
-- ------------------------------------------------------------
SELECT
    'Missing Record'            AS issue_type,
    s.transaction_id,
    s.amount                    AS source_amount,
    NULL                        AS transformed_amount,
    s.cost_center               AS source_cost_center,
    NULL                        AS mapped_cost_center,
    s.account_code              AS source_account,
    NULL                        AS mapped_account,
    'Source record not found in transformed layer' AS remarks
FROM source_transactions s
LEFT JOIN transformed_reporting t
    ON s.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL
  AND s.status = 'Posted';

-- ------------------------------------------------------------
-- CHECK 2: Duplicate transaction IDs in transformed layer
-- Any transaction_id appearing more than once.
-- ------------------------------------------------------------
SELECT
    'Duplicate Transaction'     AS issue_type,
    t.transaction_id,
    s.amount                    AS source_amount,
    t.normalized_amount         AS transformed_amount,
    s.cost_center               AS source_cost_center,
    t.mapped_cost_center,
    s.account_code              AS source_account,
    t.mapped_account,
    'Transaction ID appears ' || CAST(COUNT(*) AS VARCHAR) || ' times in transformed layer' AS remarks
FROM transformed_reporting t
JOIN source_transactions s
    ON t.transaction_id = s.transaction_id
GROUP BY t.transaction_id, s.amount, t.normalized_amount,
         s.cost_center, t.mapped_cost_center,
         s.account_code, t.mapped_account
HAVING COUNT(*) > 1;

-- ------------------------------------------------------------
-- CHECK 3: Amount mismatches between source and transformed
-- Compare original amount to normalized amount.
-- ------------------------------------------------------------
SELECT
    'Amount Mismatch'           AS issue_type,
    s.transaction_id,
    s.amount                    AS source_amount,
    t.normalized_amount         AS transformed_amount,
    s.cost_center               AS source_cost_center,
    t.mapped_cost_center,
    s.account_code              AS source_account,
    t.mapped_account,
    'Source and transformed amounts differ by '
        || CAST(ABS(s.amount - t.normalized_amount) AS VARCHAR) AS remarks
FROM source_transactions s
JOIN (
    SELECT DISTINCT transaction_id, mapped_cost_center, mapped_account, normalized_amount
    FROM transformed_reporting
) t ON s.transaction_id = t.transaction_id
WHERE s.amount <> t.normalized_amount;

-- ------------------------------------------------------------
-- CHECK 4: Invalid account mappings
-- Transformed accounts not in the valid account master.
-- ------------------------------------------------------------
SELECT
    'Invalid Account Mapping'   AS issue_type,
    t.transaction_id,
    s.amount                    AS source_amount,
    t.normalized_amount         AS transformed_amount,
    s.cost_center               AS source_cost_center,
    t.mapped_cost_center,
    s.account_code              AS source_account,
    t.mapped_account,
    'Account ' || t.mapped_account || ' is not in the valid account master' AS remarks
FROM transformed_reporting t
JOIN source_transactions s
    ON t.transaction_id = s.transaction_id
LEFT JOIN valid_accounts va
    ON t.mapped_account = va.account_code
WHERE va.account_code IS NULL;

-- ------------------------------------------------------------
-- CHECK 5: Invalid cost center mappings
-- Transformed cost centers not in the valid cost center master.
-- ------------------------------------------------------------
SELECT
    'Invalid Cost Center Mapping' AS issue_type,
    t.transaction_id,
    s.amount                    AS source_amount,
    t.normalized_amount         AS transformed_amount,
    s.cost_center               AS source_cost_center,
    t.mapped_cost_center,
    s.account_code              AS source_account,
    t.mapped_account,
    'Cost center ' || t.mapped_cost_center || ' is not in the valid cost center master' AS remarks
FROM transformed_reporting t
JOIN source_transactions s
    ON t.transaction_id = s.transaction_id
LEFT JOIN valid_cost_centers vc
    ON t.mapped_cost_center = vc.cost_center
WHERE vc.cost_center IS NULL;

-- ------------------------------------------------------------
-- CHECK 6: Source records dropped before final reporting
-- Posted source records with no match in the final report layer
-- after accounting for cost center and account mappings.
-- ------------------------------------------------------------
SELECT
    'Dropped Before Final Report' AS issue_type,
    s.transaction_id,
    s.amount                    AS source_amount,
    t.normalized_amount         AS transformed_amount,
    s.cost_center               AS source_cost_center,
    t.mapped_cost_center,
    s.account_code              AS source_account,
    t.mapped_account,
    'Record exists in transformed layer but cost center/account combination not in final report' AS remarks
FROM source_transactions s
JOIN transformed_reporting t
    ON s.transaction_id = t.transaction_id
LEFT JOIN final_report_output f
    ON t.reporting_period = f.reporting_period
    AND t.mapped_cost_center = f.mapped_cost_center
    AND t.mapped_account = f.mapped_account
WHERE f.reporting_period IS NULL
  AND s.status = 'Posted';
