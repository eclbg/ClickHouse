#include <Analyzer/Passes/SemanticComparisonOptimizationPass.h>

#include <Functions/FunctionFactory.h>
#include <DataTypes/DataTypesNumber.h>

#include <Analyzer/InDepthQueryTreeVisitor.h>
#include <Analyzer/ConstantNode.h>
#include <Analyzer/FunctionNode.h>
#include <Analyzer/ColumnNode.h>
#include <Analyzer/Utils.h>

namespace DB
{

namespace
{

class SemanticComparisonOptimizationVisitor : public InDepthQueryTreeVisitorWithContext<SemanticComparisonOptimizationVisitor>
{
public:
    using Base = InDepthQueryTreeVisitorWithContext<SemanticComparisonOptimizationVisitor>;
    using Base::Base;

    void enterImpl(QueryTreeNodePtr & node)
    {
        auto * function_node = node->as<FunctionNode>();
        if (!function_node)
            return;

        const auto & function_name = function_node->getFunctionName();

        // Handle comparison functions
        if (function_name == "equals" || function_name == "notEquals")
        {
            optimizeComparisonFunction(node, function_node);
        }
    }

private:
    void optimizeComparisonFunction(QueryTreeNodePtr & node, FunctionNode * function_node)
    {
        const auto & arguments = function_node->getArguments().getNodes();
        if (arguments.size() != 2)
            return;

        // Check if both arguments are the same column
        auto * left_column = arguments[0]->as<ColumnNode>();
        auto * right_column = arguments[1]->as<ColumnNode>();

        if (!left_column || !right_column)
            return;

        // Check if they reference the same column
        if (!areColumnsIdentical(left_column, right_column))
            return;

        const auto & function_name = function_node->getFunctionName();
        const auto & column_type = left_column->getResultType();

        if (function_name == "equals")
        {
            // id = id case
            if (column_type->canBeInsideNullable() && !column_type->isNullable())
            {
                // Non-nullable column: id = id -> true
                node = std::make_shared<ConstantNode>(Field(1u), std::make_shared<DataTypeUInt8>());
            }
            else if (column_type->isNullable())
            {
                // Nullable column: nullable_id = nullable_id -> isNotNull(nullable_id) because (select null = null) is null (falsy)
                createIsNotNullFunction(node, arguments[0]);
            }
        }
        else if (function_name == "notEquals")
        {
            // id != id case
            if (column_type->canBeInsideNullable() && !column_type->isNullable())
            {
                // Non-nullable column: id != id -> false
                node = std::make_shared<ConstantNode>(Field(0u), std::make_shared<DataTypeUInt8>());
            }
            else if (column_type->isNullable())
            {
                // Nullable column: id != id -> false because (select null != null) is null (falsy)
                node = std::make_shared<ConstantNode>(Field(0u), std::make_shared<DataTypeUInt8>());
            }
        }
    }

    bool areColumnsIdentical(const ColumnNode * left, const ColumnNode * right)
    {
        // Check if column names and sources are the same
        if (left->getColumnName() != right->getColumnName())
            return false;

        auto left_source = left->getColumnSourceOrNull();
        auto right_source = right->getColumnSourceOrNull();

        if (left_source != right_source)
            return false;

        return true;
    }

    void createIsNotNullFunction(QueryTreeNodePtr & node, const QueryTreeNodePtr & argument)
    {
        auto & function_factory = FunctionFactory::instance();
        auto is_not_null_function = function_factory.get("isNotNull", getContext());

        auto is_not_null_function_node = std::make_shared<FunctionNode>("isNotNull");
        is_not_null_function_node->getArguments().getNodes().push_back(argument);
        is_not_null_function_node->resolveAsFunction(is_not_null_function);

        node = std::move(is_not_null_function_node);
    }

};

}

void SemanticComparisonOptimizationPass::run(QueryTreeNodePtr & query_tree_node, ContextPtr context)
{
    SemanticComparisonOptimizationVisitor visitor(std::move(context));
    visitor.visit(query_tree_node);
}

}
