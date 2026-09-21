# AI_DISCLOSURE.md

## AI tools used
AI assistants were used during this assessment as an engineering aid for design discussion, code review, troubleshooting, documentation drafting and interview-style validation.

The primary assistant used was **ChatGPT**.

AI assistance was used for reviewing Snowflake architecture choices and assessment requirements, discussing metadata/classification/masking/row-access/DQ/lineage/certification design, reviewing and refining SQL/dbt logic, troubleshooting Snowflake CLI/dbt/GitHub Actions issues, explaining Snowflake behavior and error messages, drafting documentation structure and wording, and identifying validation queries and edge cases.

## What AI did not replace
All Snowflake objects, SQL, dbt models, policies, tests, CI configuration and evidence were executed and validated against the actual assessment environment.

AI-generated suggestions were not treated as proof of correctness. Where a suggestion did not match actual Snowflake behavior, the implementation was changed based on observed execution results.

Examples include:
- validating real classification output against the sealed sensitive-column list
- using actual DQ outcomes rather than hard-coded PASS values
- diagnosing masking behavior by querying active Snowflake policy references
- validating key-pair authentication with the real `SVC_PIPELINE_USER`
- testing the CI pipeline on GitHub Actions until the end-to-end workflow passed

## Human decisions retained
The final architecture and implementation decisions were made and reviewed by the candidate, including RAW → STAGING → MARTS layering, dbt for STAGING → MARTS transformations, governance metadata-store design, CDE/tag taxonomy, steward confirmation before classification drives protection, six-dimension DQ design, certification evidence model, native plus external lineage approach, seven-word scorecard, and the non-ACCOUNTADMIN CI service-user pattern.

## Code-generation disclosure
AI provided code snippets and revisions during implementation. Every submitted script remains the candidate's responsibility and was reviewed for purpose, privileges, object dependencies and expected behavior before use.

The candidate is prepared to explain and modify every submitted object and line of code during the live review.

## Sensitive information
No private RSA key, password or other secret is intentionally committed to the repository.

GitHub Actions credentials are stored as repository secrets, while private/public local key material and generated local files are excluded through `.gitignore`.

## Final validation principle
The submission favors reproducible code and observed Snowflake state over hand-applied UI configuration or fabricated outputs.

Where Snowflake trial limitations or metadata latency affect a feature, the limitation is documented and the committed DDL/query path is retained so the intended implementation remains reviewable.
