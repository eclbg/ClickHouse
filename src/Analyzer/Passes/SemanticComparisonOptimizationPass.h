#pragma once

#include <Analyzer/IQueryTreePass.h>

namespace DB
{

/** Optimize comparison functions based on semantic analysis.
  * 
  * Handles cases like:
  * - id != id (where id is non-nullable) -> false
  * - id = id (where id is non-nullable) -> true
  * - nullable_id = nullable_id -> isNotNull(nullable_id)
  * - nullable_id != nullable_id -> isNull(nullable_id)
  */
class SemanticComparisonOptimizationPass final : public IQueryTreePass
{
public:
    String getName() override { return "SemanticComparisonOptimization"; }

    String getDescription() override { return "Optimize comparison functions based on semantic analysis (e.g., id != id)."; }

    void run(QueryTreeNodePtr & query_tree_node, ContextPtr context) override;
};

}
