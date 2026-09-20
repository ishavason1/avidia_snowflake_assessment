import streamlit as st

from snowflake.snowpark.context import get_active_session


st.set_page_config(
    page_title="Avidia Data Catalog",
    layout="wide"
)

session = get_active_session()

st.title("Avidia Bank Data Catalog")

st.caption(
    "Governed metadata catalog backed by Snowflake Horizon metadata, "
    "data quality results, lineage, adoption evidence and certification controls."
)


# -------------------------------------------------------------------
# Base catalog data
# -------------------------------------------------------------------

base_query = """
SELECT
    DATABASE_NAME,
    SCHEMA_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    COLUMN_TYPE,
    DESCRIPTION,
    DATA_OWNER,
    DATA_STEWARD,
    CERTIFICATION,
    CDE_FLAG,
    CRITICALITY_LEVEL,
    CLASSIFICATION,
    LATEST_DQ_STATUS,
    LAST_METADATA_REFRESH,
    UPSTREAM_SOURCE,
    QUERY_COUNT,
    DISTINCT_ROLES
FROM GOVERNANCE.CATALOG.CATALOG_MASTER_VIEW
"""

df = session.sql(base_query).to_pandas()


# -------------------------------------------------------------------
# Sidebar filters
# -------------------------------------------------------------------

st.sidebar.header("Catalog Filters")

search_text = st.sidebar.text_input(
    "Search table, column or description"
)

database_options = ["All"] + sorted(
    df["DATABASE_NAME"].dropna().unique().tolist()
)

selected_database = st.sidebar.selectbox(
    "Database",
    database_options
)

schema_options = ["All"] + sorted(
    df["SCHEMA_NAME"].dropna().unique().tolist()
)

selected_schema = st.sidebar.selectbox(
    "Schema",
    schema_options
)

cde_only = st.sidebar.checkbox(
    "Critical Data Elements only"
)

filtered = df.copy()

if search_text:
    search_lower = search_text.lower()

    filtered = filtered[
        filtered["TABLE_NAME"]
        .fillna("")
        .str.lower()
        .str.contains(search_lower, regex=False)
        |
        filtered["COLUMN_NAME"]
        .fillna("")
        .str.lower()
        .str.contains(search_lower, regex=False)
        |
        filtered["DESCRIPTION"]
        .fillna("")
        .str.lower()
        .str.contains(search_lower, regex=False)
    ]

if selected_database != "All":
    filtered = filtered[
        filtered["DATABASE_NAME"] == selected_database
    ]

if selected_schema != "All":
    filtered = filtered[
        filtered["SCHEMA_NAME"] == selected_schema
    ]

if cde_only:
    filtered = filtered[
        filtered["CDE_FLAG"] == "YES"
    ]


# -------------------------------------------------------------------
# Summary metrics
# -------------------------------------------------------------------

m1, m2, m3, m4 = st.columns(4)

m1.metric(
    "Objects",
    filtered[
        ["DATABASE_NAME", "SCHEMA_NAME", "TABLE_NAME"]
    ]
    .drop_duplicates()
    .shape[0]
)

m2.metric(
    "Columns",
    len(filtered)
)

m3.metric(
    "Critical Data Elements",
    int(
        (
            filtered["CDE_FLAG"] == "YES"
        ).sum()
    )
)

m4.metric(
    "Documented Columns",
    int(
        filtered["DESCRIPTION"]
        .fillna("")
        .str.strip()
        .ne("")
        .sum()
    )
)


# -------------------------------------------------------------------
# Main catalog table
# -------------------------------------------------------------------

st.subheader("Catalog")

display_columns = [
    "DATABASE_NAME",
    "SCHEMA_NAME",
    "TABLE_NAME",
    "COLUMN_NAME",
    "COLUMN_TYPE",
    "DESCRIPTION",
    "DATA_OWNER",
    "DATA_STEWARD",
    "CERTIFICATION",
    "CDE_FLAG",
    "CRITICALITY_LEVEL",
    "CLASSIFICATION",
    "LATEST_DQ_STATUS",
]

st.dataframe(
    filtered[display_columns],
    use_container_width=True,
)


# -------------------------------------------------------------------
# Selected asset details
# -------------------------------------------------------------------

st.subheader("Asset Details")

objects = (
    filtered[
        [
            "DATABASE_NAME",
            "SCHEMA_NAME",
            "TABLE_NAME",
        ]
    ]
    .drop_duplicates()
)

objects["OBJECT_NAME"] = (
    objects["DATABASE_NAME"]
    + "."
    + objects["SCHEMA_NAME"]
    + "."
    + objects["TABLE_NAME"]
)

object_options = sorted(
    objects["OBJECT_NAME"].tolist()
)


if object_options:

    selected_object = st.selectbox(
        "Select an object",
        object_options
    )

    db_name, schema_name, table_name = (
        selected_object.split(".", 2)
    )

    asset = filtered[
        (
            filtered["DATABASE_NAME"]
            == db_name
        )
        &
        (
            filtered["SCHEMA_NAME"]
            == schema_name
        )
        &
        (
            filtered["TABLE_NAME"]
            == table_name
        )
    ]

    if not asset.empty:

        first = asset.iloc[0]

        # -----------------------------------------------------------
        # Certification display
        #
        # For MART_DEPOSITS use latest certification run directly.
        # This avoids ACCOUNT_USAGE tag latency in the catalog view.
        # -----------------------------------------------------------

        certification_display = (
            first["CERTIFICATION"]
            if first["CERTIFICATION"]
            else "Not certified"
        )

        if (
            selected_object
            == "ANALYTICS.MARTS.MART_DEPOSITS"
        ):

            latest_cert_query = """
            SELECT
                FINAL_STATUS,
                PASSED_CONTROLS,
                TOTAL_CONTROLS,
                COMPLETED_AT
            FROM GOVERNANCE.CATALOG.CERTIFICATION_RUN
            WHERE DATABASE_NAME = 'ANALYTICS'
              AND SCHEMA_NAME = 'MARTS'
              AND OBJECT_NAME = 'MART_DEPOSITS'
            ORDER BY COMPLETED_AT DESC
            LIMIT 1
            """

            latest_cert_df = session.sql(
                latest_cert_query
            ).to_pandas()

            if not latest_cert_df.empty:
                certification_display = (
                    latest_cert_df.iloc[0][
                        "FINAL_STATUS"
                    ]
                )


        # -----------------------------------------------------------
        # High-level asset metrics
        # -----------------------------------------------------------

        c1, c2, c3, c4 = st.columns(4)

        c1.metric(
            "Owner",
            first["DATA_OWNER"]
            if first["DATA_OWNER"]
            else "Not assigned"
        )

        c2.metric(
            "Steward",
            first["DATA_STEWARD"]
            if first["DATA_STEWARD"]
            else "Not assigned"
        )

        c3.metric(
            "Certification",
            certification_display
        )

        c4.metric(
            "Latest DQ",
            first["LATEST_DQ_STATUS"]
            if first["LATEST_DQ_STATUS"]
            else "Not available"
        )


        # -----------------------------------------------------------
        # Column-level metadata
        # -----------------------------------------------------------

        st.write("### Columns")

        st.dataframe(
            asset[
                [
                    "COLUMN_NAME",
                    "COLUMN_TYPE",
                    "DESCRIPTION",
                    "CDE_FLAG",
                    "CRITICALITY_LEVEL",
                    "CLASSIFICATION",
                ]
            ],
            use_container_width=True
        )


        # -----------------------------------------------------------
        # Certified MART_DEPOSITS data product
        # -----------------------------------------------------------

        if (
            selected_object
            == "ANALYTICS.MARTS.MART_DEPOSITS"
        ):

            # -------------------------------------------------------
            # Governance scorecard
            # -------------------------------------------------------

            st.write("### Governance Scorecard")

            scorecard_query = """
            SELECT
                CONTROL_NAME,
                CONTROL_STATUS,
                EVIDENCE_VALUE,
                EVIDENCE_DETAILS,
                EVALUATED_AT
            FROM GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD_CURRENT
            ORDER BY
                CASE CONTROL_NAME
                    WHEN 'OWNED' THEN 1
                    WHEN 'DEFINED' THEN 2
                    WHEN 'TRACEABLE' THEN 3
                    WHEN 'TRUSTED' THEN 4
                    WHEN 'SECURE' THEN 5
                    WHEN 'ADOPTED' THEN 6
                    WHEN 'RECONCILED' THEN 7
                    ELSE 99
                END
            """

            scorecard_df = session.sql(
                scorecard_query
            ).to_pandas()

            if not scorecard_df.empty:

                passed_controls = int(
                    (
                        scorecard_df[
                            "CONTROL_STATUS"
                        ]
                        == "PASS"
                    ).sum()
                )

                s1, s2, s3 = st.columns(3)

                s1.metric(
                    "Scorecard",
                    f"{passed_controls}/7"
                )

                s2.metric(
                    "Overall Status",
                    "CERTIFIED"
                    if passed_controls == 7
                    else "IN PROGRESS"
                )

                s3.metric(
                    "Last Evaluated",
                    str(
                        scorecard_df[
                            "EVALUATED_AT"
                        ].max()
                    )
                )

                st.dataframe(
                    scorecard_df[
                        [
                            "CONTROL_NAME",
                            "CONTROL_STATUS",
                            "EVIDENCE_VALUE",
                            "EVIDENCE_DETAILS",
                        ]
                    ],
                    use_container_width=True
                )

            else:

                st.info(
                    "No certification scorecard "
                    "is currently available."
                )


            # -------------------------------------------------------
            # Lineage
            # -------------------------------------------------------

            st.write("### Lineage")

            lineage_query = """
            SELECT
                SOURCE_DATABASE,
                SOURCE_SCHEMA,
                SOURCE_OBJECT,
                SOURCE_COLUMN,
                TARGET_DATABASE,
                TARGET_SCHEMA,
                TARGET_OBJECT,
                TARGET_COLUMN,
                DIRECTION,
                DISTANCE,
                LINEAGE_SOURCE
            FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
            WHERE
                (
                    TARGET_DATABASE = 'ANALYTICS'
                    AND TARGET_SCHEMA = 'MARTS'
                    AND TARGET_OBJECT = 'MART_DEPOSITS'
                )
                OR
                (
                    SOURCE_DATABASE = 'ANALYTICS'
                    AND SOURCE_SCHEMA = 'MARTS'
                    AND SOURCE_OBJECT = 'MART_DEPOSITS'
                )
            ORDER BY
                DIRECTION,
                DISTANCE,
                SOURCE_DATABASE,
                SOURCE_SCHEMA,
                SOURCE_OBJECT,
                SOURCE_COLUMN
            """

            lineage_df = session.sql(
                lineage_query
            ).to_pandas()

            if not lineage_df.empty:

                native_lineage_count = int(
                    (
                        lineage_df[
                            "LINEAGE_SOURCE"
                        ]
                        == "SNOWFLAKE_GET_LINEAGE"
                    ).sum()
                )

                l1, l2 = st.columns(2)

                l1.metric(
                    "Lineage Edges",
                    len(lineage_df)
                )

                l2.metric(
                    "Native Snowflake Edges",
                    native_lineage_count
                )

                st.dataframe(
                    lineage_df,
                    use_container_width=True
                )

            else:

                st.info(
                    "No lineage snapshot is "
                    "currently available."
                )


            # -------------------------------------------------------
            # Adoption / usage
            # -------------------------------------------------------

            st.write("### Adoption")

            adoption_query = """
            SELECT
                ROLE_NAME,
                COUNT(*) AS QUERY_COUNT,
                MAX(QUERY_START_TIME) AS LAST_QUERY_TIME
            FROM GOVERNANCE.CATALOG.ADOPTION_EVIDENCE
            WHERE DATABASE_NAME = 'ANALYTICS'
              AND SCHEMA_NAME = 'MARTS'
              AND OBJECT_NAME = 'MART_DEPOSITS'
            GROUP BY ROLE_NAME
            ORDER BY ROLE_NAME
            """

            adoption_df = session.sql(
                adoption_query
            ).to_pandas()

            if not adoption_df.empty:

                total_queries = int(
                    adoption_df[
                        "QUERY_COUNT"
                    ].sum()
                )

                distinct_roles = int(
                    adoption_df[
                        "ROLE_NAME"
                    ].nunique()
                )

                a1, a2 = st.columns(2)

                a1.metric(
                    "Recent Consumer Queries",
                    total_queries
                )

                a2.metric(
                    "Consumer Roles",
                    distinct_roles
                )

                st.dataframe(
                    adoption_df,
                    use_container_width=True
                )

            else:

                st.info(
                    "No recent consumer usage "
                    "evidence is available."
                )


            # -------------------------------------------------------
            # Worked lineage trace
            # -------------------------------------------------------

            st.write("### Worked Lineage Trace")

            st.caption(
                "Trace showing how the certified "
                "total deposits metric is derived "
                "from upstream transaction data."
            )

            trace_query = """
            SELECT
                EVIDENCE_TYPE,
                SOURCE_DATABASE,
                SOURCE_SCHEMA,
                SOURCE_OBJECT,
                SOURCE_COLUMN,
                TARGET_DATABASE,
                TARGET_SCHEMA,
                TARGET_OBJECT,
                TARGET_COLUMN,
                DISTANCE,
                EVIDENCE_NOTE
            FROM GOVERNANCE.CATALOG.TOTAL_CREDITS_LINEAGE_TRACE
            ORDER BY
                EVIDENCE_TYPE,
                DISTANCE,
                SOURCE_DATABASE,
                SOURCE_SCHEMA,
                SOURCE_OBJECT
            """

            trace_df = session.sql(
                trace_query
            ).to_pandas()

            if not trace_df.empty:

                st.dataframe(
                    trace_df,
                    use_container_width=True
                )

            else:

                st.info(
                    "Worked lineage trace is "
                    "not currently available."
                )


            # -------------------------------------------------------
            # Impact analysis
            # -------------------------------------------------------

            st.write("### Impact Analysis")

            st.caption(
                "Downstream impact if the source "
                "BRANCH_CODE column changes."
            )

            impact_query = """
            SELECT
                SOURCE_COLUMN,
                TARGET_DATABASE,
                TARGET_SCHEMA,
                TARGET_OBJECT,
                AFFECTED_COLUMN,
                HOP,
                IMPACT_EVIDENCE_TYPE,
                DATA_OWNER,
                DATA_STEWARD
            FROM GOVERNANCE.CATALOG.BRANCH_CODE_IMPACT_ANALYSIS
            ORDER BY
                HOP,
                TARGET_DATABASE,
                TARGET_SCHEMA,
                TARGET_OBJECT
            """

            impact_df = session.sql(
                impact_query
            ).to_pandas()

            if not impact_df.empty:

                st.dataframe(
                    impact_df,
                    use_container_width=True
                )

            else:

                st.info(
                    "No impact-analysis evidence "
                    "is currently available."
                )

        else:

            st.info(
                "Detailed certification, lineage, adoption "
                "and impact evidence is currently available "
                "for the certified MART_DEPOSITS data product."
            )

else:

    st.info(
        "No catalog records match the selected filters."
    )