-- ============================================================
-- 03_reconciliation_summary.sql
-- Aggregated counts and balance variances by reporting period
-- ============================================================

-- ------------------------------------------------------------
-- Summary: Balance variance by reporting period
-- Compares source totals, transformed totals, and final report totals.
-- ------------------------------------------------------------
WITH source_totals AS (
    SELECT
        CASE
            WHEN transaction_date BETWEEN '2024-01-01' AND '2024-01-31' THEN '2024-01'
            WHEN transaction_date BETWEEN '2024-02-01' AND '2024-02-29' THEN '2024-02'
        END AS reporting_period,
        SUM(amount) AS source_total,
        COUNT(*) AS source_count
    FROM source_transactions
    WHERE status = 'Posted'
    GROUP BY reporting_period
),
transformed_totals AS (
    SELECT
        reporting_period,
        SUM(normalized_amount) AS transformed_total,
        COUNT(*) AS transformed_count
    FROM transformed_reporting
    GROUP BY reporting_period
),
final_totals AS (
    SELECT
        reporting_period,
        SUM(total_amount) AS final_total,
        SUM(record_count) AS final_count
    FROM final_report_output
    GROUP BY reporting_period
),
missing_counts AS (
    SELECT
        CASE
            WHEN s.transaction_date BETWEEN '2024-01-01' AND '2024-01-31' THEN '2024-01'
            WHEN s.transaction_date BETWEEN '2024-02-01' AND '2024-02-29' THEN '2024-02'
        END AS reporting_period,
        COUNT(*) AS missing_record_count
    FROM source_transactions s
    LEFT JOIN transformed_reporting t ON s.transaction_id = t.transaction_id
    WHERE t.transaction_id IS NULL AND s.status = 'Posted'
    GROUP BY reporting_period
),
duplicate_counts AS (
    SELECT
        reporting_period,
        COUNT(*) AS duplicate_count
    FROM (
        SELECT reporting_period, transaction_id
        FROM transformed_reporting
        GROUP BY reporting_period, transaction_id
        HAVING COUNT(*) > 1
    ) dups
    GROUP BY reporting_period
),
mismatch_counts AS (
    SELECT
        t.reporting_period,
        COUNT(*) AS mismatch_count
    FROM source_transactions s
    JOIN (
        SELECT DISTINCT transaction_id, reporting_period, normalized_amount
        FROM transformed_reporting
    ) t ON s.transaction_id = t.transaction_id
    WHERE s.amount <> t.normalized_amount
    GROUP BY t.reporting_period
)

SELECT
    st.reporting_period,
    st.source_total,
    tt.transformed_total,
    ft.final_total          AS final_report_total,
    ft.final_total - tt.transformed_total AS variance_amount,
    COALESCE(mc.missing_record_count, 0) AS missing_record_count,
    COALESCE(dc.duplicate_count, 0) AS duplicate_count,
    COALESCE(mmc.mismatch_count, 0) AS mismatch_count
FROM source_totals st
LEFT JOIN transformed_totals tt ON st.reporting_period = tt.reporting_period
LEFT JOIN final_totals ft ON st.reporting_period = ft.reporting_period
LEFT JOIN missing_counts mc ON st.reporting_period = mc.reporting_period
LEFT JOIN duplicate_counts dc ON st.reporting_period = dc.reporting_period
LEFT JOIN mismatch_counts mmc ON st.reporting_period = mmc.reporting_period
ORDER BY st.reporting_period;
