SET enable_analyzer = 1;

-- Test semantic comparison optimization for non-nullable columns
DROP TABLE IF EXISTS test_table_semantic_optimization;
CREATE TABLE test_table_semantic_optimization 
(
    id UInt32,
    nullable_id Nullable(UInt32),
    name String
) ENGINE = Memory;

INSERT INTO test_table_semantic_optimization VALUES (1, 1, 'test1'), (2, NULL, 'test2'), (3, 3, 'test3');

-- Test id = id with non-nullable column (should be optimized to true)
SELECT 'Non-nullable id = id should return all rows:';
SELECT * FROM test_table_semantic_optimization WHERE id = id ORDER BY id;

-- Test id != id with non-nullable column (should be optimized to false)
SELECT 'Non-nullable id != id should return no rows:';
SELECT * FROM test_table_semantic_optimization WHERE id != id;

-- Test nullable_id = nullable_id (should be optimized to isNotNull(nullable_id))
SELECT 'Nullable id = id should return rows where nullable_id is NOT NULL:';
SELECT * FROM test_table_semantic_optimization WHERE nullable_id = nullable_id ORDER BY id;

-- Test nullable_id != nullable_id (should be optimized to false)
SELECT 'Nullable id != id should not return any rows:';
SELECT * FROM test_table_semantic_optimization WHERE nullable_id != nullable_id ORDER BY id;

-- Test with more complex expressions to ensure optimization doesn't break other cases
SELECT 'Complex expression with self-comparison:';
SELECT * FROM test_table_semantic_optimization WHERE (id + 1) != (id + 1) ORDER BY id;

SELECT 'Different columns comparison (should not be optimized):';
SELECT * FROM test_table_semantic_optimization WHERE id = nullable_id ORDER BY id;

DROP TABLE test_table_semantic_optimization;
