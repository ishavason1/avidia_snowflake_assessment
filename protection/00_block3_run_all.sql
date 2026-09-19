-- protection/00_block3_run_all.sql
-- BLOCK 3 MASTER ORCHESTRATION
-- Executes all 7 steps by calling individual SQL files sequentially

SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT 'BLOCK 3: PROTECTION & POLICIES - MASTER ORCHESTRATION' as title;
SELECT 'Executing all 7 steps from individual SQL files' as description;
SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT '' as blank;

-- ============================================
-- STEP 1: Create masking policies
-- ============================================
SELECT '→ STEP 1: Creating masking policies...' as step_header;
!source protection/01_create_masking_policies.sql
SELECT '✓ STEP 1 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 2: Create parametric masking procedure
-- ============================================
SELECT '→ STEP 2: Creating parametric masking procedure...' as step_header;
!source protection/02_create_masking_procedures.sql
SELECT '✓ STEP 2 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 3: Create bulk masking procedure
-- ============================================
SELECT '→ STEP 3: Creating bulk masking procedure...' as step_header;
!source protection/03_apply_masking_bulk.sql
SELECT '✓ STEP 3 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 4: Create validation views
-- ============================================
SELECT '→ STEP 4: Creating validation views...' as step_header;
!source protection/04_create_validation_views.sql
SELECT '✓ STEP 4 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 5: Create rollback procedure
-- ============================================
SELECT '→ STEP 5: Creating rollback procedure...' as step_header;
!source protection/05_create_rollback_procedure.sql
SELECT '✓ STEP 5 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 6: Create evidence artifacts
-- ============================================
SELECT '→ STEP 6: Creating evidence artifacts...' as step_header;
!source protection/06_create_evidence_artifacts.sql
SELECT '✓ STEP 6 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 7: Full verification
-- ============================================
SELECT '→ STEP 7: Running full verification...' as step_header;
!source protection/07_full_verification.sql
SELECT '✓ STEP 7 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- FINAL SUMMARY
-- ============================================
SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT '✓✓✓ BLOCK 3 COMPLETE - ALL STEPS EXECUTED ✓✓✓' as final_status;
SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT '' as blank;

SELECT 'Summary:' as section;
SELECT '✓ Step 1: 4 masking policies created' as step;
SELECT '✓ Step 2: Parametric procedure created' as step;
SELECT '✓ Step 3: Bulk procedure created' as step;
SELECT '✓ Step 4: 4 validation views created' as step;
SELECT '✓ Step 5: Rollback procedure created' as step;
SELECT '✓ Step 6: 3 evidence artifacts created' as step;
SELECT '✓ Step 7: Full verification passed' as step;
SELECT '' as blank;

SELECT 'Next Steps:' as section;
SELECT '→ CALL APPLY_MASKING_TO_CONFIRMED_COLUMNS();' as next_step;
SELECT '→ OR: CALL APPLY_MASKING_TO_COLUMN(database, schema, table, column);' as next_step;
SELECT '→ Then: Proceed to Block 4 - Quality & Reconciliation' as next_step;

