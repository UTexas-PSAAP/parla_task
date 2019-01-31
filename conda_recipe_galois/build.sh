rm -rf build
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPOE=Release -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_CXX_FLAGS="-I/usr/include -L/usr/lib64 -fPIC" -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX -DBOOST_ROOT=$BUILD_PREFIX ..
make galois_shmem -j
# Manually install runtime static lib.
cp libgalois/libgalois_shmem.a $PREFIX/lib/libgalois_shmem.a
mkdir $PREFIX/include
cp -r ../libgalois/include/galois $PREFIX/include/galois
