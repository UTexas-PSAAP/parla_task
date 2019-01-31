cd $RECIPE_DIR/..
$PYTHON setup.py build_ext --include-dirs=$PREFIX/include --library-dirs=/usr/lib64 --link-objects=$PREFIX/lib/libgalois_shmem.a install
