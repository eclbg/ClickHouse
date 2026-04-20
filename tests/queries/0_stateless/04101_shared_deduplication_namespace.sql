-- Tags: zookeeper, no-replicated-database, no-shared-merge-tree
-- Tag no-replicated-database: Unsupported type of ALTER query
-- Tag no-shared-merge-tree: for smt works

DROP TABLE IF EXISTS shared_deduplication_namespace_replica;
DROP TABLE IF EXISTS shared_deduplication_namespace_plain;

CREATE TABLE shared_deduplication_namespace_replica
(
    id UInt64
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/test_04101/shared_deduplication_namespace', '1')
ORDER BY id
SETTINGS
    shared_deduplication_namespace = 'namespace-1',
    allow_remote_fs_zero_copy_replication = 1,
    storage_policy = 's3_no_cache';

SHOW CREATE TABLE shared_deduplication_namespace_replica;

ALTER TABLE shared_deduplication_namespace_replica MODIFY SETTING shared_deduplication_namespace = 'namespace-2'; -- { serverError READONLY_SETTING }

DETACH TABLE shared_deduplication_namespace_replica;
ATTACH TABLE shared_deduplication_namespace_replica;

SHOW CREATE TABLE shared_deduplication_namespace_replica;

DROP TABLE shared_deduplication_namespace_replica;

CREATE TABLE shared_deduplication_namespace_plain
(
    id UInt64
)
ENGINE = MergeTree
ORDER BY id
SETTINGS shared_deduplication_namespace = 'namespace-1'; -- { serverError BAD_ARGUMENTS }

CREATE TABLE shared_deduplication_namespace_replica
(
    id UInt64
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/test_04101/shared_deduplication_namespace_empty', '1')
ORDER BY id
SETTINGS shared_deduplication_namespace = ''; -- { serverError BAD_ARGUMENTS }
