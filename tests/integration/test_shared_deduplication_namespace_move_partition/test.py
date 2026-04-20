import uuid

import pytest

from helpers.cluster import ClickHouseCluster
from helpers.test_tools import assert_eq_with_retry


cluster = ClickHouseCluster(__file__)
node1 = cluster.add_instance("node1", with_zookeeper=True)
node2 = cluster.add_instance("node2", with_zookeeper=True)
nodes = [node1, node2]


@pytest.fixture(scope="module")
def started_cluster():
    try:
        cluster.start()
        yield cluster
    finally:
        cluster.shutdown()


def sync_replicas(table_name):
    for node in nodes:
        node.query(f"SYSTEM SYNC REPLICA {table_name}", timeout=30)


def assert_count_on_all_replicas(table_name, expected_count):
    query = f"SELECT count() FROM {table_name}"
    expected = f"{expected_count}\n"
    for node in nodes:
        assert_eq_with_retry(node, query, expected)


def drop_table_on_all_replicas(table_name):
    for node in nodes:
        node.query(f"DROP TABLE IF EXISTS {table_name} SYNC")


def test_move_partition_keeps_shared_deduplication_tokens(started_cluster):
    suffix = uuid.uuid4().hex
    source_table = f"shared_dedup_move_src_{suffix}"
    destination_table = f"shared_dedup_move_dst_{suffix}"
    source_path = f"/clickhouse/tables/test_shared_dedup_move_partition/{suffix}/source"
    destination_path = f"/clickhouse/tables/test_shared_dedup_move_partition/{suffix}/destination"

    try:
        for node in nodes:
            node.query(
                f"""
                CREATE TABLE {source_table}
                (
                    p UInt64,
                    id UInt64
                )
                ENGINE = ReplicatedMergeTree('{source_path}', '{node.name}')
                PARTITION BY p
                ORDER BY id
                """
            )
            node.query(
                f"""
                CREATE TABLE {destination_table}
                (
                    p UInt64,
                    id UInt64
                )
                ENGINE = ReplicatedMergeTree('{destination_path}', '{node.name}')
                PARTITION BY p
                ORDER BY id
                SETTINGS shared_deduplication_namespace = '{source_path}'
                """
            )

        # We insert with and without a defined deduplication token to check that the behaviour is the same.
        node1.query(
            f"INSERT INTO {source_table} SETTINGS insert_deduplication_token = 'shared-token' VALUES (1, 100)"
        )
        node1.query(f"INSERT INTO {source_table} VALUES (1, 200)")
        sync_replicas(source_table)

        node1.query(
            f"ALTER TABLE {source_table} MOVE PARTITION 1 TO TABLE {destination_table}"
        )
        sync_replicas(source_table)
        sync_replicas(destination_table)

        assert_count_on_all_replicas(source_table, 0)
        assert_count_on_all_replicas(destination_table, 2)

        node2.query(
            f"INSERT INTO {source_table} SETTINGS insert_deduplication_token = 'shared-token' VALUES (1, 100)"
        )
        node2.query(
            f"INSERT INTO {destination_table} SETTINGS insert_deduplication_token = 'shared-token' VALUES (1, 100)"
        )
        node2.query(f"INSERT INTO {source_table} VALUES (1, 200)")
        node2.query(f"INSERT INTO {destination_table} VALUES (1, 200)")
        sync_replicas(source_table)
        sync_replicas(destination_table)

        assert_count_on_all_replicas(source_table, 0)
        assert_count_on_all_replicas(destination_table, 2)
    finally:
        drop_table_on_all_replicas(destination_table)
        drop_table_on_all_replicas(source_table)
