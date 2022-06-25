#/bin/bash

set -e

commit() {
  git commit -m "Deploy"
}

if ! git diff --exit-code --quiet --cached; then
  echo Aborting due to uncommitted changes in the index >&2
  return 1
fi

rm -rf build/
NO_CONTRACTS=true bundle exec middleman build

if git show-ref --verify --quiet "refs/heads/gh-pages"
then
  git symbolic-ref HEAD refs/heads/gh-pages
  git --work-tree "build" reset --mixed --quiet
  git --work-tree "build" add --all

  set +o errexit
  diff=$(git --work-tree "build" diff --exit-code --quiet HEAD --)$?
  set -o errexit
  case $diff in
    0) echo No changes to files in build/. Skipping commit.;;
    1) commit;;
    *)
      echo git diff exited with code $diff. Aborting.
    ;;
  esac
else
  git --work-tree "build" checkout --orphan gh-pages
  git --work-tree "build" add --all
  commit
fi

git symbolic-ref HEAD refs/heads/master
git reset --mixed
