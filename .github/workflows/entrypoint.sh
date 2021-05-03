#!/bin/bash
# Install mecab, then build wheels
set -e

# install MeCab
# TODO specify the commit used here
git clone --depth=1 git://github.com/taku910/mecab.git
cd mecab/mecab
./configure --build='aarch64'  #--enable-utf8-only
make
make install

# Hack
# see here:
# https://github.com/RalfG/python-wheels-manylinux-build/issues/26
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

# Build the wheels
for PYVER in cp35-cp35m cp36-cp36m cp37-cp37m cp38-cp38 cp39-cp39; do
  # build the wheels
  /opt/python/$PYVER/bin/pip wheel /github/workspace -w /github/workspace/wheels || { echo "Failed while buiding $PYVER wheel"; exit 1; }
done

# fix the wheels (bundles libs)
for wheel in /github/workspace/wheels/*.whl; do
  if [ `uname -m` == 'aarch64' ]; then
    auditwheel repair "$wheel" --plat manylinux2014_aarch64 -w /github/workspace/manylinux2014-wheels
  else
    auditwheel repair "$wheel" --plat manylinux1_x86_64 -w /github/workspace/manylinux1-wheels
  fi
done

echo "Built wheels:"
ls /github/workspace/manylinux1-wheels
ls /github/workspace/manylinux2014-wheels
