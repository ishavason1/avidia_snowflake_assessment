-- protection/00_block3_run_all.sql
-- CANONICAL PROTECTION ORCHESTRATION
-- Classification approval and tag synchronization are prerequisites:
-- classification/10_sync_confirmed_classification_tags.sql

SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT 'PROTECTION: TAG-BASED MASKING AND BRANCH ACCESS' as title;
SELECT 'Executing the canonical protection flow' as description;
SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT '' as blank;

-- ============================================
-- STEP 1: One-time grants
-- ============================================
SELECT '→ STEP 1: Applying required permissions...' as step_header;
!source protection/01_permissions.sql
SELECT '✓ STEP 1 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 2: Create tag-based masking policies
-- ============================================
SELECT '→ STEP 2: Creating tag-based masking policies...' as step_header;
!source protection/02_create_tag_based_masking_policies.sql
SELECT '✓ STEP 2 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 3: Bind policies to the approved-classification tag
-- ============================================
SELECT '→ STEP 3: Binding policies to CLASSIFICATION tag...' as step_header;
!source protection/03_bind_masking_policies.sql
SELECT '✓ STEP 3 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 4: Create branch entitlements
-- ============================================
SELECT '→ STEP 4: Creating branch entitlements...' as step_header;
!source protection/04_create_branch_entitlements.sql
SELECT '✓ STEP 4 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 5: Create branch row access policy
-- ============================================
SELECT '→ STEP 5: Creating branch row access policy...' as step_header;
!source protection/05_create_row_access_policy.sql
SELECT '✓ STEP 5 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 6: Apply branch row access policy
-- ============================================
SELECT '→ STEP 6: Applying branch row access policy...' as step_header;
!source protection/06_apply_row_access_policy.sql
SELECT '✓ STEP 6 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 7: Validate masking by role
-- ============================================
SELECT '→ STEP 7: Validating masking by role...' as step_header;
!source protection/07_validate_masking_by_role.sql
SELECT '✓ STEP 7 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 8: Validate branch access
-- ============================================
SELECT '→ STEP 8: Validating branch access...' as step_header;
!source protection/08_validate_branch_access.sql
SELECT '✓ STEP 8 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- STEP 9: Report sensitive-policy gaps
-- ============================================
SELECT '→ STEP 9: Reporting sensitive-policy gaps...' as step_header;
!source protection/09_sensitive_policy_gap_report.sql
SELECT '✓ STEP 9 COMPLETE' as validation;
SELECT '' as blank;

-- ============================================
-- FINAL SUMMARY
-- ============================================
SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT '✓ CANONICAL PROTECTION FLOW COMPLETE' as final_status;
SELECT '════════════════════════════════════════════════════════════════' as header;
SELECT '' as blank;

SELECT 'Inspect GOVERNANCE.CATALOG.SENSITIVE_POLICY_GAPS; zero rows is the live coverage result.' as next_step;
