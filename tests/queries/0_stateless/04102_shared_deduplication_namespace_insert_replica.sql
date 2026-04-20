DROP TABLE IF EXISTS shared_dedup_owner_04102 SYNC;
DROP TABLE IF EXISTS shared_dedup_follower_04102 SYNC;
DROP TABLE IF EXISTS shared_dedup_control_04102 SYNC;

SELECT 'create owner and seed dedup history';
CREATE TABLE shared_dedup_owner_04102
(
    id Int32,
    val UInt32
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/test_04102/shared_dedup_owner', 'r1')
ORDER BY id;

INSERT INTO shared_dedup_owner_04102
SETTINGS insert_deduplication_token = 'shared-token'
VALUES (1, 1001);
SELECT * FROM shared_dedup_owner_04102 ORDER BY id;

SELECT 'create follower with shared dedup namespace';
CREATE TABLE shared_dedup_follower_04102
(
    id Int32,
    val UInt32
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/test_04102/shared_dedup_follower', 'r1')
ORDER BY id
SETTINGS shared_deduplication_namespace = '/clickhouse/tables/test_04102/shared_dedup_owner';

INSERT INTO shared_dedup_follower_04102
SETTINGS insert_deduplication_token = 'shared-token'
VALUES (1, 1001);
SELECT count() FROM shared_dedup_follower_04102;

SYSTEM FLUSH LOGS system.part_log;
SELECT DISTINCT exception FROM system.part_log
WHERE event_date >= yesterday() AND event_time >= now() - 600 AND table = 'shared_dedup_follower_04102'
  AND database = currentDatabase()
  AND event_type = 'NewPart'
  AND error = 389;

SELECT 'same data without token is also deduplicated through shared namespace';
INSERT INTO shared_dedup_owner_04102 VALUES (2, 1002);
INSERT INTO shared_dedup_follower_04102 VALUES (2, 1002);
SELECT count() FROM shared_dedup_follower_04102;

SELECT 'same token without shared namespace is still inserted';
CREATE TABLE shared_dedup_control_04102
(
    id Int32,
    val UInt32
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/test_04102/shared_dedup_control', 'r1')
ORDER BY id;

INSERT INTO shared_dedup_control_04102
SETTINGS insert_deduplication_token = 'shared-token'
VALUES (1, 1001);
SELECT * FROM shared_dedup_control_04102 ORDER BY id;

DROP TABLE shared_dedup_owner_04102 SYNC;
DROP TABLE shared_dedup_follower_04102 SYNC;
DROP TABLE shared_dedup_control_04102 SYNC;
