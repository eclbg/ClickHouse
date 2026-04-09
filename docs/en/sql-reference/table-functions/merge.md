---
description: 'Creates a temporary Merge table. The structure will be derived from underlying tables by using a union of their columns and by deriving common types.'
sidebar_label: 'merge'
sidebar_position: 130
slug: /sql-reference/table-functions/merge
title: 'merge'
doc_type: 'reference'
---

# merge Table Function

Creates a temporary [Merge](../../engines/table-engines/special/merge.md) table.
The table schema is derived from underlying tables by using a union of their columns and by deriving common types.
The same virtual columns are available as for the [Merge](../../engines/table-engines/special/merge.md) table engine.

For compatible `ReplacingMergeTree` source tables, you can opt into a global cross-table `FINAL` merge by passing `preferred_source_table_suffix` as the optional third argument when the database name is specified explicitly. When rows have the same sorting key and the same real version, rows coming from tables whose names end with the configured suffix win the cross-table tie-break.

## Syntax {#syntax}

```sql
merge('tables_regexp')
merge('db_name', 'tables_regexp'[, 'preferred_source_table_suffix'])
```
## Arguments {#arguments}

| Argument        | Description                                                                                                                                                                                                                                                                                     |
|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `db_name`       | Possible values (optional, default is `currentDatabase()`):<br/>    - database name,<br/>    - constant expression that returns a string with a database name, for example, `currentDatabase()`,<br/>    - `REGEXP(expression)`, where `expression` is a regular expression to match the DB names. |
| `tables_regexp` | A regular expression to match the table names in the specified DB or DBs.                                                                                                                                                                                                                       |
| `preferred_source_table_suffix` | Optional suffix used only by the opt-in cross-table `FINAL` path for compatible `ReplacingMergeTree` source tables. If several rows have the same sorting key and the same real version, rows coming from tables whose names end with this suffix win the cross-table tie-break. |

## Related {#related}

- [Merge](../../engines/table-engines/special/merge.md) table engine
