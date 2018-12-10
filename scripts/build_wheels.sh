#!/bin/bash

set -e -x

rm -rf /io/wheelhouse

# Install a system package required by our library
yum install -y gettext

PACKAGE_NAME="pysmbc-binary"

# Build samba
mkdir -p /io/samba
(
	cd /io/samba
	yum install -y libacl-devel e2fsprogs-devel readline-deve gdb gcc gcc-c++ zlib-devel
	curl https://download.samba.org/pub/samba/stable/samba-4.9.3.tar.gz -o samba-4.9.3.tar.gz
	tar xf samba-4.9.3.tar.gz
	cd samba-4.9.3
	PATH=/opt/python/cp27-cp27m/bin/:$PATH
	./configure --prefix=/usr/local --disable-python --without-ad-dc --enable-fhs --without-ldap --without-ads --without-pam --without-json-audit
	make -j4
	make install
)

(
	cd /io/pysmbc
	# Replace the package name
	if [[ "${PACKAGE_NAME:-}" ]]; then
		sed -i 's/name="pysmbc"/name="pysmbc-binary"/' setup.py
	fi
	# Compile wheels
	for PYVER in /opt/python/*; do
	    LD_LIBRARY_PATH=$PYVER/lib:/usr/local/lib:$LD_LIBRARY_PATH PATH=$PYVER/bin:$PATH ${PYVER}/bin/python setup.py bdist_wheel --dist-dir /io/wheelhouse/
        rm -rf dist build
	done

	# Bundle external shared libraries into the wheels
	for whl in /io/wheelhouse/*.whl; do
	    auditwheel repair "$whl" -w /io/wheelhouse/
	done
	sha1sum /io/wheelhouse/*.whl
	ls -la /io/wheelhouse/
)
