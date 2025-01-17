#!/usr/bin/env bash

# Echo each command
set -x

# Exit on error.
set -e

if [[ ${PYKEP_BUILD} == *37 ]]; then
	PYTHON_DIR="cp37-cp37m"
	BOOST_PYTHON_LIBRARY_NAME="libboost_python37.so"
	PYTHON_VERSION="37"
elif [[ ${PYKEP_BUILD} == *36 ]]; then
	PYTHON_DIR="cp36-cp36m"
	BOOST_PYTHON_LIBRARY_NAME="libboost_python36.so"
	PYTHON_VERSION="36"
elif [[ ${PYKEP_BUILD} == *27mu ]]; then
	PYTHON_DIR="cp27-cp27mu"
	BOOST_PYTHON_LIBRARY_NAME="libboost_python27mu.so"
	PYTHON_VERSION="27"
elif [[ ${PYKEP_BUILD} == *27 ]]; then
	PYTHON_DIR="cp27-cp27m"
	BOOST_PYTHON_LIBRARY_NAME="libboost_python27.so"
	PYTHON_VERSION="27"
else
	echo "Invalid build type: ${PYKEP_BUILD}"
	exit 1
fi

cd
cd install

# Install and compile pykep
cd /pykep
cd build
cmake -DBoost_NO_BOOST_CMAKE=ON \
      -DBUILD_MAIN=no \
	  -DBUILD_PYKEP=yes \
	  -DBUILD_SPICE=yes \
	  -DBUILD_TESTS=no \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DBoost_PYTHON${PYTHON_VERSION}_LIBRARY_RELEASE=/usr/local/lib/${BOOST_PYTHON_LIBRARY_NAME} \
	  -DPYTHON_EXECUTABLE=/opt/python/${PYTHON_DIR}/bin/python ../;
make -j2 install

# Compile wheels
cd wheel
# Copy the installed pyaudi files, wherever they might be in /usr/local,
# into the current dir.
cp -a `find /usr/local/lib -type d -iname 'pykep'` ./

# Create the wheel and repair it.
/opt/python/${PYTHON_DIR}/bin/python setup.py bdist_wheel
auditwheel repair dist/pykep* -w ./dist2
# Try to install it and run the tests.
cd /
/opt/python/${PYTHON_DIR}/bin/pip install /pykep/build/wheel/dist2/pykep*
/opt/python/${PYTHON_DIR}/bin/python -c "from pykep import test; test.run_test_suite();"

# Upload in PyPi
# This variable will contain something if this is a tagged build (vx.y.z), otherwise it will be empty.
export PYKEP_RELEASE_VERSION=`echo "${TRAVIS_TAG}"|grep -E 'v[0-9]+\.[0-9]+.*'|cut -c 2-`
if [[ "${PYKEP_RELEASE_VERSION}" != "" ]]; then
	echo "Release build detected, uploading to PyPi."
	/opt/python/${PYTHON_DIR}/bin/pip install twine
	/opt/python/${PYTHON_DIR}/bin/twine upload -u darioizzo /pykep/build/wheel/dist2/pykep*
fi


