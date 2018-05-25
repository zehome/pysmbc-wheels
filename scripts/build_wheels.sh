#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y gettext

# Build samba > 3.2 (Samba4 is too much of a pain to build on such old distribution)
mkdir -p /io/samba
(
	cd /io/samba
	curl https://download.samba.org/pub/samba/stable/samba-3.6.25.tar.gz -o samba-3.6.25.tar.gz
	tar xf samba-3.6.25.tar.gz
	cd samba-3.6.25/source3
	./configure
	make
	make install
	install -m644 pkgconfig/*.pc /usr/local/lib/pkgconfig/
)

(
	cd /io/pysmbc
	# Compile wheels
	for PYBIN in /opt/python/*/bin; do
	    "${PYBIN}/python" setup.py bdist_wheel --dist-dir /io/wheelhouse/
	done

	# Bundle external shared libraries into the wheels
	for whl in wheelhouse/*.whl; do
	    auditwheel repair "$whl" -w /io/wheelhouse/
	done
	sha1sum wheelhouse/*.whl
	ls -la wheelhouse/
)
