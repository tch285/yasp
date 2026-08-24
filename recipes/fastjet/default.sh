#!/bin/bash

cd "{{workdir}}"
url=https://gitlab.com/fastjet/fastjet.git
if [ -d "{{workdir}}"/fastjet ]; then rm -rf "{{workdir}}"/fastjet; fi
git clone "{{url}}"

srcdir="{{workdir}}/fastjet"
cd "{{srcdir}}"
# Remove fastjet- prefix from git tags
version=$(git tag --sort=v:refname --merged=HEAD | tail -1 | sed 's/^fastjet-//')
echo Latest FastJet version: $version
echo FastJet version to be installed: "{{version}}"
git switch --detach fastjet-"{{version}}"
git submodule update --init
autoreconf --install
cd plugins/SISCone/siscone; autoreconf --install; cd ../../..

cd "{{builddir}}"
if [ -d "${CGAL_DIR}" ]; then
	# cgal_opt="--with-cgaldir=${CGAL_DIR} --enable-cgal-header-only"
	# echo "$CGAL_DIR"
	cgal_opt="--enable-cgal-header-only --with-cgaldir=${CGAL_DIR}"
else
	cgal_opt="--disable-cgal"
fi
other_opts="--enable-allcxxplugins --enable-allplugins"
# not enabling the swig interface --enable-pyext
#system=$(gcc -dumpmachine)
#echo "{{srcdir}}/configure --prefix={{prefix}} --build=${system} --host=${system} ${cgal_opt} ${other_opts} "
{{srcdir}}/configure --prefix={{prefix}} --build=${system} --host=${system} ${cgal_opt} ${other_opts} && make -j {{n_cores}} && make install
exit $?
