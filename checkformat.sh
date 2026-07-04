#!/bin/bash
# Script: check-tf-format.sh

echo "🔍 Checking Terraform formatting..."
echo ""

ISSUES=0

for file in $(find . -name "*.tf" -type f); do
  if ! terraform fmt -check "$file" 2>/dev/null; then
    echo "❌ $file"
    echo "   Run: terraform fmt $file"
    ISSUES=$((ISSUES+1))
  else
    echo "✅ $file"
  fi
done

echo ""
echo "Summary: $ISSUES files need formatting"

if [ $ISSUES -gt 0 ]; then
  echo ""
  echo "Fix all with: terraform fmt -recursive ."
  exit 1
fi