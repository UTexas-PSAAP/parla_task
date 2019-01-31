cd $RECIPE_DIR/..
$PYTHON setup.py build_ext --include-dirs=$BUILD_PREFIX/include --library-dirs=/usr/lib64 --link-objects=$BUILD_PREFIX/lib/libgalois_shmem.a install
