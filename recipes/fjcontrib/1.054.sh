#!/bin/bash

source ${YASP_DIR}/src/util/bash/util.sh

fjconfig=$(which fastjet-config)
if [ ! -e "${fjconfig}" ]; then
	echo_error "no fastjet-config [${fjconfig} ] this will not work"
	exit -1
else
	echo_info "using ${fjconfig}"
fi
fastjet_prefix=$(fastjet-config --prefix)
echo_info "fastjet prefix: ${fastjet_prefix}"
fjlibs=$(${fjconfig} --libs --plugins)
echo_info "fastjet libs: ${fjlibs}"
# get so lib extention depending on the os
if [ "Darwin" == $(uname) ]; then
	soext=dylib
else
	soext=so
fi

if [ "{{rebuild}}" == "yes" ]; then
		echo_warning "rebuilding..."
	else
		if [ -e "${fastjet_prefix}/lib/libfastjetcontribfragile.${soext}" ]; then
			echo_warning "${fastjet_prefix}/lib/libfastjetcontribfragile.${soext} exists - skipping - --define rebuild=yes to force rebuild"
			exit 0
		fi
fi

cd {{workdir}}
version=1.054
url=https://fastjet.hepforge.org/contrib/downloads/fjcontrib-{{version}}.tar.gz
local_file={{workdir}}/fjcontrib-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}

if [ "Darwin" == $(uname) ]; then
	tar zxvf {{local_file}}
else
	tar zxvf {{local_file}} --warning=no-unknown-keyword
fi
srcdir={{workdir}}/fjcontrib-{{version}}
cd {{srcdir}}
rm .[!.]* */.[!.]*  # Remove unnecessary dotfiles
# the line below would use the default fj picked by yasp - not always what wanted...
#if [ -z "${fastjet_prefix}" ]; then
#	   fastjet_prefix=$({{yasp}} -q feature prefix -i fastjet)
#fi

# assume we do not need distclean
make distclean
if [ "x{{make_check}}" == "xNone" ]; then
	./configure --fastjet-config=${fjconfig} --prefix=${fastjet_prefix} LDFLAGS="${fjlibs}" && make -j {{n_cores}} all && make install  # Static libraries
else
	./configure --fastjet-config=${fjconfig} --prefix=${fastjet_prefix} LDFLAGS="${fjlibs}" && make -j {{n_cores}} all && make check && make install  # Static libraries
fi
if [ $? -eq 0 ]
then
	# it seems the compilation is stable - now build the shared libraries
	make distclean
	./configure --fastjet-config=${fjconfig} --prefix=${fastjet_prefix} CXXFLAGS=-fPIC LDFLAGS="${fjlibs}"
	make -j {{n_cores}} all && make check && make install  # Static libraries
	contribs=$(./configure --list)
	for c in ${contribs}
	do
		cd ${c}
		echo "[i] building ${c} in directory ${PWD}"
		rm *example*.o
		shlib=${fastjet_prefix}/lib/lib${c}.so
		# {{CXX}} -fPIC -shared -o ${shlib} *.o -Wl,-rpath,${fastjet_prefix}/lib -L${fastjet_prefix}/lib -lfastjettools -lfastjet
		ofiles=$(ls *.o)
		if [ -z "${ofiles}" ]; then
			echo "[i] Skipping so build for ${c} - no object files"
		else
			{{CXX}} -fPIC -shared -o ${shlib} *.o ${fjlibs}
		fi
		if [ -f ${shlib} ]; then
			echo "[i] shared lib created ${shlib}"
		else
			echo "[i] shared lib NOT created ${shlib}"
		fi
		cd {{srcdir}}
	done

    # Modify the fastjet module to include fjcontrib version
    fjmodule="{{yasp_dir}}/software/modules/fastjet/${FASTJET_VERSION}"
		# this is more generic - path independent...
		fjmodule=$(module show fastjet 2>&1 | grep modules/fastjet | cut -d':' -f1)
    echo "[i] Saving fjcontrib version to ${fjmodule}"
    echo "setenv FJCONTRIB_VERSION ${version}" >> ${fjmodule}
fi

exit $?
