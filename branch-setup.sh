#!/bin/bash

set -e  # Остановить выполнение при ошибке

# Define branches and directories
BRANCHES=("dev" "stage")
DIRECTORIES=("backend" "frontend")

# Read optional subtree repository URL from arguments
SUBTREE_REPO_URL=$1

# Function to setup a branch
setup_branch() {
  local BRANCH=$1
  local DIR=$2

  echo "🚀 Setting up branch: $BRANCH in $DIR"

  # Navigate to project directory
  cd "$DIR"

  # Create or switch to the branch
  git checkout $BRANCH 2>/dev/null || git checkout -b $BRANCH

  # Run ESLint & Prettier setup
  npx ep-setup

  # Install Git hooks
  echo "🔗 Installing Git hooks..."
  curl -sSL https://raw.githubusercontent.com/AkimovEugeney/githook/refs/heads/main/setup-git-hooks.sh | bash

  # Add Git subtree only if the URL is provided
  if [ -n "$SUBTREE_REPO_URL" ] && ! git remote | grep -q "subtree-$BRANCH"; then
    echo "🌲 Adding subtree for $BRANCH..."
    git remote add subtree-$BRANCH "$SUBTREE_REPO_URL"
  else
    echo "⚠️ No subtree URL provided or already added, skipping..."
  fi

  # Commit and push changes
  git add .
  git commit -m "Automated setup for $BRANCH in $DIR"
  git push origin $BRANCH

  # Return to the root directory
  cd ..
}

# Loop through each directory and set up branches (except main)
for DIR in "${DIRECTORIES[@]}"; do
  if [ -d "$DIR" ]; then
    echo "📂 Setting up $DIR"
    for BRANCH in "${BRANCHES[@]}"; do
      setup_branch $BRANCH $DIR
    done
  else
    echo "⚠️ Directory $DIR does not exist, skipping..."
  fi
done

echo "✅ All branches in backend and frontend are set up!"