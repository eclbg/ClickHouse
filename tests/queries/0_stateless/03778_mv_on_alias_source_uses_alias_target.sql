-- Test that a Materialized View created with an Alias table as source
-- correctly triggers on inserts to both the alias and the target table.

DROP TABLE IF EXISTS source_table;
DROP TABLE IF EXISTS alias_table;
DROP TABLE IF EXISTS mv_target;
DROP TABLE IF EXISTS mv_on_alias;

CREATE TABLE source_table (id UInt32, value String) ENGINE = MergeTree ORDER BY id;
CREATE TABLE alias_table ENGINE = Alias('source_table') settings allow_experimental_alias_table_engine=1;
CREATE TABLE mv_target (id UInt32, value String) ENGINE = MergeTree ORDER BY id;
CREATE MATERIALIZED VIEW mv_on_alias TO mv_target AS SELECT id, value FROM alias_table;

-- Test 1: Insert to the alias table triggers the MV
SELECT 'After INSERT INTO alias_table (1, via_alias):';
INSERT INTO alias_table VALUES (1, 'via_alias');
SELECT 'mv_target contents:';
SELECT * FROM mv_target ORDER BY id;

-- Test 2: Insert to the source table
-- BUG: The MV reads from the full table instead of just the inserted block,
-- so we get duplicate rows (the previous row is re-inserted)
SELECT 'After INSERT INTO source_table (2, direct):';
INSERT INTO source_table VALUES (2, 'direct');
SELECT 'mv_target contents (should be 2 rows, but has duplicates):';
SELECT * FROM mv_target ORDER BY id, value;

-- Test 3: Insert to the alias table again - does it use just the block or full table?
SELECT 'After INSERT INTO alias_table (3, via_alias_again):';
INSERT INTO alias_table VALUES (3, 'via_alias_again');
SELECT 'mv_target contents:';
SELECT * FROM mv_target ORDER BY id, value;

DROP TABLE mv_on_alias;
DROP TABLE mv_target;
DROP TABLE alias_table;
DROP TABLE source_table;
