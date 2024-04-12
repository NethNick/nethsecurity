#!/bin/bash

#
# Search for ns packages that have been updated since the last release.
# If the package has been updated, bump the version number, create a branch and
# add a commit for each package.
#
# It must be executed from the root of the repository:
# builder/bumper.sh

# prepare empty packages array
packages=()

for dir in $(find packages/ -maxdepth 1 -type d -name ns-\*)
do
    if [ "${dir}" == "packages/" ]; then
        continue
    fi
    last_release_commit=$(git log -1 -L :^PKG_VERSION:${dir}/Makefile -s 2>/dev/null| grep commit | awk '{print $2}')
    if [ -z "$last_release_commit" ]; then
        continue
    fi
    last_commit=$(git log -1 -s "${dir}" | grep '^commit' | awk '{print $2}')
    if [ "$last_commit" != "$last_release_commit" ]; then
        cur_release=$(grep ^PKG_VERSION ${dir}/Makefile | cut -d= -f2)
        new_release=$(echo $cur_release | awk -F. '/[0-9]+\./{$NF++;print}' OFS=.)
        # add the package name and the new version inside and array
        packages+=("$dir $cur_release $new_release")
    fi
done

# if packages is not empty, create a branch and add a commit for each package
if [ ${#packages[@]} -gt 0 ]; then
    # delete the branch if it already exists
    git branch -D bump-ns-packages 2>/dev/null
    git checkout -b bump-ns-packages
    for package in "${packages[@]}"
    do
        dir=$(echo $package | cut -d' ' -f1)
        cur_release=$(echo $package | cut -d' ' -f2)
        new_release=$(echo $package | cut -d' ' -f3)
        sed -i "s/PKG_VERSION:=${cur_release}/PKG_VERSION:=${new_release}/" ${dir}/Makefile
        package_name=$(basename $dir)
        echo "Bump ${package_name} from ${cur_release} to ${new_release}"
        git add ${dir}/Makefile && git commit -m "${package_name}: bump to ${new_release}"
    done
    echo "Branch bump-ns-packages created. Please review and push the changes:"
    echo
    echo "git push -f origin bump-ns-packages"
else
    echo "No packages to bump."
fi
