#!/bin/bash

set -e  # Останавливать выполнение при ошибке

# Define branches
BRANCHES=("stage" "dev")

# Read optional subtree repository URL from arguments
SUBTREE_REPO_URL=$1

# Function to setup a branch
setup_branch() {
  local BRANCH=$1
  local SUBTREE_BRANCH=$2  # Ветка subtree должна совпадать с веткой проекта

  echo "🚀 Setting up branch: $BRANCH"

  # Create the branch from main
  git checkout -b $BRANCH main

  # Add Git subtree if URL is provided
  if [ -n "$SUBTREE_REPO_URL" ]; then
    echo "🌲 Adding subtree for $BRANCH (branch: $SUBTREE_BRANCH)..."
    git subtree add --prefix=subtree shared-types $SUBTREE_BRANCH --squash
  else
    echo "⚠️ No subtree URL provided, skipping..."
  fi

  # Commit and push changes
  git add .
  git commit -m "Automated setup for $BRANCH"
  git push origin $BRANCH
}

# Ensure we're on main before setup
git checkout main

# Install ESLint & Prettier
yarn ep-setup

# Add Git subtree to main if URL is provided
if [ -n "$SUBTREE_REPO_URL" ]; then
  echo "🌲 Adding subtree for main..."
  git remote add shared-types "$SUBTREE_REPO_URL" || true
  git fetch shared-types
  git subtree add --prefix=subtree shared-types main --squash
fi

# Commit and push main branch setup
git add .
git commit -m "Initial setup for main"
git push origin main

# Create stage & dev branches based on main
for BRANCH in "${BRANCHES[@]}"; do
  setup_branch $BRANCH $BRANCH
done

# Install Git hooks in each branch **after push**
for BRANCH in main "${BRANCHES[@]}"; do
  git checkout $BRANCH
  echo "🔗 Installing Git hooks in $BRANCH..."
  curl -sSL https://raw.githubusercontent.com/AkimovEugeney/githook/refs/heads/main/setup-git-hooks.sh | bash
  git add .git/hooks
  git commit -m "Added Git hooks to $BRANCH"
  git push origin $BRANCH
done

echo "✅ All branches are set up!"
