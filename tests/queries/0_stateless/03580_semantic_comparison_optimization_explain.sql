SET enable_analyzer = 1;

-- Test that semantic comparison optimization is working by checking query plans
DROP TABLE IF EXISTS test_table_semantic_opt_explain;
CREATE TABLE test_table_semantic_opt_explain 
(
    id UInt32,
    nullable_id Nullable(UInt32)
) ENGINE = Memory;

-- Check that id = id is optimized to a constant true 
SELECT 'EXPLAIN for id = id (should show constant true):';
EXPLAIN QUERY TREE SELECT * FROM test_table_semantic_opt_explain WHERE id = id;

-- Check that id != id is optimized to a constant false
SELECT 'EXPLAIN for id != id (should show constant false):';
EXPLAIN QUERY TREE SELECT * FROM test_table_semantic_opt_explain WHERE id != id;

-- Check that nullable_id = nullable_id is optimized to isNotNull(nullable_id)
SELECT 'EXPLAIN for nullable_id = nullable_id (should show isNotNull function):';
EXPLAIN QUERY TREE SELECT * FROM test_table_semantic_opt_explain WHERE nullable_id = nullable_id;

-- Check that nullable_id != nullable_id is optimized to constant false
SELECT 'EXPLAIN for nullable_id != nullable_id (should show false):';
EXPLAIN QUERY TREE SELECT * FROM test_table_semantic_opt_explain WHERE nullable_id != nullable_id;

DROP TABLE test_table_semantic_opt_explain;
