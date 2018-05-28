#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y gettext

PACKAGE_NAME="pysmbc-binary"

# Build samba
mkdir -p /io/samba
(
	cd /io/samba
	yum install -y libacl-devel e2fsprogs-devel readline-deve gdb gcc gcc-c++ zlib-devel
	curl https://download.samba.org/pub/samba/stable/samba-4.8.2.tar.gz -o samba-4.8.2.tar.gz
	tar xf samba-4.8.2.tar.gz
	cd samba-4.8.2
	PATH=/opt/python/cp27-cp27m/bin/:$PATH
	./configure --prefix=/usr/local --disable-python --without-ad-dc --enable-fhs --without-ldap --without-ads --without-pam
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
	LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
	for PYBIN in /opt/python/*/bin; do
	    "${PYBIN}/python" setup.py bdist_wheel --dist-dir /io/wheelhouse/
        rm -rf dist build
	done

	# Bundle external shared libraries into the wheels
	for whl in /io/wheelhouse/*.whl; do
	    auditwheel repair "$whl" -w /io/wheelhouse/
	done
	sha1sum /io/wheelhouse/*.whl
	ls -la /io/wheelhouse/
)
