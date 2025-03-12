#!/bin/bash

set -e  # Exit on any error

# Define branches
BRANCHES=("stage" "dev")

# Read optional subtree repository URL from arguments
SUBTREE_REPO_URL=$1

# Ensure we're on main before setup
git checkout main

# Install ESLint & Prettier
npx ep-setup

# Add Git remote for subtree if URL is provided
if [ -n "$SUBTREE_REPO_URL" ]; then
  echo "🌲 Setting up subtree..."
  git remote add shared-types "$SUBTREE_REPO_URL" || true
  git fetch shared-types
fi

# Commit main setup
git add .
git commit -m "Initial setup for main" || echo "⚠️ Nothing to commit"
git push origin main

# Function to setup a branch
setup_branch() {
  local BRANCH=$1
  local SUBTREE_BRANCH=$2  # Subtree branch should match the project branch

  echo "🚀 Setting up branch: $BRANCH"

  # Create the branch from main
  git checkout $BRANCH

  # Install Git hooks **before commit**
  if [ ! -d ".git-hooks" ]; then
    echo "🔗 Installing Git hooks in $BRANCH..."
    curl -sSL https://raw.githubusercontent.com/AkimovEugeney/githook/main/setup-git-hooks.sh | bash
  fi

  # Add Git subtree if URL is provided
  if [ -n "$SUBTREE_REPO_URL" ]; then
    echo "🌲 Adding subtree for $BRANCH (branch: $SUBTREE_BRANCH)..."
    git subtree add --prefix=shared-types shared-types $SUBTREE_BRANCH  --squash || echo "⚠️ Subtree already exists"
  else
    echo "⚠️ No subtree URL provided, skipping..."
  fi

  # Commit and push changes
if [ -n "$SUBTREE_REPO_URL" ] || [ ! -d ".git-hooks" ]; then
  git add .
  git commit -m "Automated setup for $BRANCH" || echo "⚠️ Nothing to commit"
  git push origin $BRANCH
fi

}

# Create stage & dev branches based on main
for BRANCH in "${BRANCHES[@]}"; do
  if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
      echo "⚠️ Branch $BRANCH already exists, skipping creation..."
  else
    echo "🚀 Creating branch $BRANCH from main..."
    git branch $BRANCH main
  fi
done

git subtree add --prefix=shared-types shared-types main  --squash || echo "⚠️ Subtree already exists"

for BRANCH in "${BRANCHES[@]}"; do
  setup_branch $BRANCH $BRANCH
done

echo "✅ All branches are set up!"
