rm -rf build
mkdir build
cd build
#CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")
cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_CXX_FLAGS="-I/usr/include -L/usr/lib64 -fPIC" -DCMAKE_INSTALL_PREFIX=$PREFIX -DBOOST_ROOT=$BUILD_PREFIX ..
make galois_shmem -j
make install
# Manually install runtime static lib.
#cp libgalois/libgalois_shmem.a $PREFIX/lib/libgalois_shmem.a
#mkdir -p $PREFIX/include
#cp -r ../libgalois/include/galois $PREFIX/include/galois
