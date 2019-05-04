cd $RECIPE_DIR/..
rm -rf build
$PYTHON setup.py --verbose build_ext --verbose --include-dirs=$BUILD_PREFIX/include --library-dirs=/usr/lib64 --libraries=numa install
