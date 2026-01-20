-- Test that creating a Materialized View with an Alias table as source is forbidden.
-- Users should reference the target table directly instead.

DROP TABLE IF EXISTS source_table;
DROP TABLE IF EXISTS alias_table;
DROP TABLE IF EXISTS mv_target;
DROP TABLE IF EXISTS mv_on_alias;

CREATE TABLE source_table (id UInt32, value String) ENGINE = MergeTree ORDER BY id;
CREATE TABLE alias_table ENGINE = Alias('source_table') SETTINGS allow_experimental_alias_table_engine=1;
CREATE TABLE mv_target (id UInt32, value String) ENGINE = MergeTree ORDER BY id;

-- This should fail with a helpful error message
CREATE MATERIALIZED VIEW mv_on_alias TO mv_target AS SELECT id, value FROM alias_table; -- { serverError QUERY_IS_NOT_SUPPORTED_IN_MATERIALIZED_VIEW }

-- Creating MV from the target table directly should work
CREATE MATERIALIZED VIEW mv_on_source TO mv_target AS SELECT id, value FROM source_table;

-- Verify it works
INSERT INTO source_table VALUES (1, 'test');
SELECT * FROM mv_target;

DROP TABLE IF EXISTS mv_on_source;
DROP TABLE mv_target;
DROP TABLE alias_table;
DROP TABLE source_table;
