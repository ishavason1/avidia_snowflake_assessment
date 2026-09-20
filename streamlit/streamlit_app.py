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
    "data quality results and governance metadata."
)

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

# ---------------------------
# Sidebar filters
# ---------------------------

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
        filtered["TABLE_NAME"].fillna("").str.lower().str.contains(
            search_lower, regex=False
        )
        |
        filtered["COLUMN_NAME"].fillna("").str.lower().str.contains(
            search_lower, regex=False
        )
        |
        filtered["DESCRIPTION"].fillna("").str.lower().str.contains(
            search_lower, regex=False
        )
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

# ---------------------------
# Summary metrics
# ---------------------------

m1, m2, m3, m4 = st.columns(4)

m1.metric(
    "Objects",
    filtered[["DATABASE_NAME", "SCHEMA_NAME", "TABLE_NAME"]]
    .drop_duplicates()
    .shape[0]
)

m2.metric(
    "Columns",
    len(filtered)
)

m3.metric(
    "Critical Data Elements",
    int((filtered["CDE_FLAG"] == "YES").sum())
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

# ---------------------------
# Catalog
# ---------------------------

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

# ---------------------------
# Selected asset details
# ---------------------------

st.subheader("Asset Details")

objects = (
    filtered[
        ["DATABASE_NAME", "SCHEMA_NAME", "TABLE_NAME"]
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

object_options = sorted(objects["OBJECT_NAME"].tolist())

if object_options:

    selected_object = st.selectbox(
        "Select an object",
        object_options
    )

    db_name, schema_name, table_name = selected_object.split(".", 2)

    asset = filtered[
        (filtered["DATABASE_NAME"] == db_name)
        & (filtered["SCHEMA_NAME"] == schema_name)
        & (filtered["TABLE_NAME"] == table_name)
    ]

    if not asset.empty:

        first = asset.iloc[0]

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
            first["CERTIFICATION"]
            if first["CERTIFICATION"]
            else "Not certified"
        )

        c4.metric(
            "Latest DQ",
            first["LATEST_DQ_STATUS"]
            if first["LATEST_DQ_STATUS"]
            else "Not available"
        )

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

        st.write("### Lineage and Usage")

        st.info(
            "Lineage and usage metrics will be populated from "
            "Snowflake lineage metadata and ACCESS_HISTORY."
        )

else:
    st.info("No catalog records match the selected filters.")