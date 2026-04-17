DROP TABLE IF EXISTS plain_03831_v1;
DROP TABLE IF EXISTS plain_03831_v1_rt;
DROP TABLE IF EXISTS plain_03831_merge;

CREATE TABLE plain_03831_v1
(
    id UInt64,
    value String
)
ENGINE = ReplacingMergeTree
ORDER BY id;

CREATE TABLE plain_03831_v1_rt
(
    id UInt64,
    value String
)
ENGINE = ReplacingMergeTree
ORDER BY id;

CREATE TABLE plain_03831_merge AS plain_03831_v1
ENGINE = Merge(currentDatabase(), '^plain_03831_v1(_rt)?$', '_rt');

INSERT INTO plain_03831_v1 VALUES (1, 'base_old'), (1, 'base_new'), (2, 'base_only');
INSERT INTO plain_03831_v1_rt VALUES (1, 'rt_old'), (1, 'rt_new'), (3, 'rt_only');

SELECT 'merge engine without version';
SELECT id, value, _table FROM plain_03831_merge FINAL ORDER BY id;

SELECT 'table function without version';
SELECT id, value, _table FROM merge(currentDatabase(), '^plain_03831_v1(_rt)?$', '_rt') FINAL ORDER BY id;

DROP TABLE plain_03831_merge;
DROP TABLE plain_03831_v1;
DROP TABLE plain_03831_v1_rt;

DROP TABLE IF EXISTS versioned_03831_v1;
DROP TABLE IF EXISTS versioned_03831_v1_rt;
DROP TABLE IF EXISTS versioned_03831_merge;

CREATE TABLE versioned_03831_v1
(
    id UInt64,
    ver UInt64,
    value String
)
ENGINE = ReplacingMergeTree(ver)
ORDER BY id;

CREATE TABLE versioned_03831_v1_rt
(
    id UInt64,
    ver UInt64,
    value String
)
ENGINE = ReplacingMergeTree(ver)
ORDER BY id;

CREATE TABLE versioned_03831_merge AS versioned_03831_v1
ENGINE = Merge(currentDatabase(), '^versioned_03831_v1(_rt)?$', '_rt');

INSERT INTO versioned_03831_v1 VALUES (1, 1, 'base_v1'), (1, 2, 'base_v2'), (2, 3, 'base_v3');
INSERT INTO versioned_03831_v1_rt VALUES (1, 2, 'rt_v2_tie'), (2, 2, 'rt_v2_lower'), (3, 1, 'rt_v1_only');

SELECT 'merge engine with version';
SELECT id, ver, value, _table FROM versioned_03831_merge FINAL ORDER BY id;

SELECT 'table function with version';
SELECT id, ver, value, _table FROM merge(currentDatabase(), '^versioned_03831_v1(_rt)?$', '_rt') FINAL ORDER BY id;

DROP TABLE versioned_03831_merge;
DROP TABLE versioned_03831_v1;
DROP TABLE versioned_03831_v1_rt;
