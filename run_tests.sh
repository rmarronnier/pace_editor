#!/bin/bash

# Script to run tests for pace_editor

echo "🔧 Setting up test environment..."
echo "================================"

# Check if we're in the right directory
if [ ! -f "shard.yml" ]; then
    echo "❌ Error: Must run from pace_editor directory"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
shards install

echo ""
echo "🧪 Running tests..."
echo "=================="

# Run all specs
echo "Running all specs..."
crystal spec

echo ""
echo "📊 Test Summary"
echo "==============="

# Run specific test suites with summary
echo ""
echo "1️⃣ Enhanced UI Helpers:"
crystal spec spec/ui/ui_helpers_enhanced_spec.cr 2>/dev/null && echo "✅ Passed" || echo "❌ Failed"

echo ""
echo "2️⃣ Enhanced Scene Editor:"
crystal spec spec/editors/scene_editor_enhanced_spec.cr 2>/dev/null && echo "✅ Passed" || echo "❌ Failed"

echo ""
echo "3️⃣ Backward Compatibility:"
crystal spec spec/migration/backward_compatibility_spec.cr 2>/dev/null && echo "✅ Passed" || echo "❌ Failed"

echo ""
echo "4️⃣ Feature Comparison:"
crystal spec spec/editors/scene_editor_comparison_spec.cr 2>/dev/null && echo "✅ Passed" || echo "❌ Failed"

echo ""
echo "✨ Test run complete!"