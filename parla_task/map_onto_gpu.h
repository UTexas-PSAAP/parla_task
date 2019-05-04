#pragma once

#include <cublas_v2.h>
#include <cuda_runtime.h>
#include <cusolverDn.h>

#include "galois/Galois.h"

// TODO!!! RAII wrappers for all these pointers are needed.

static galois::substrate::PerThreadStorage<cublasHandle_t> cublas_contexts(nullptr);
static galois::substrate::PerThreadStorage<cusolverDnHandle_t> cusolver_handles(nullptr);
// Allow each device to have a permanent scratch space.
// Currently just initialize it to a given size before running anything.
// Later we should maybe make it dynamically expand as needed.
static galois::substrate::PerThreadStorage<int> lwork_sizes(0);
static galois::substrate::PerThreadStorage<double*> lworks(nullptr);
// Also pre-allocate a spot for cublas/cusolver error flags.
static galois::substrate::PerThreadStorage<int*> dev_infos;

inline static void bind_threads_to_gpus() {
  int devices = 0;
  auto stat1 = cudaGetDeviceCount(&devices);
  // TODO: better error handling here.
  if (stat1 != cudaSuccess) {
    GALOIS_DIE("Failed to detect number of available GPUs.");
  }
  // One thread for CPU.
  // Others for GPU.
  unsigned int nthreads = devices + 1;
  galois::setActiveThreads(nthreads);

  galois::on_each([&](unsigned int tid, unsigned int nthreads) {
    if (tid != 0) {
      stat1 = cudaSetDevice(tid - 1);
      if (stat1 != cudaSuccess) GALOIS_DIE("Failed to allocate one device per thread.");
      auto stat2 = cublasCreate(cublas_contexts.getLocal());
      if (stat2 != CUBLAS_STATUS_SUCCESS) GALOIS_DIE("Failed to initialize cublas.");
      auto stat3 = cusolverDnCreate(cusolver_handles.getLocal());
      if (stat3 != CUSOLVER_STATUS_SUCCESS) GALOIS_DIE("Failed to initialize cusolver.");
      stat1 = cudaMalloc(dev_infos.getLocal(), sizeof(int));
      if (stat1 != cudaSuccess) GALOIS_DIE("Failed to allocate GPU int for cusolver call status.");
    }
  });
}

inline static unsigned int get_thread_id() noexcept {
  return galois::substrate::ThreadPool::getTID();
}

inline static cublasHandle_t get_cublas_context() noexcept {
  return *cublas_contexts.getLocal();
}

inline static cusolverDnHandle_t get_cusolver_context() noexcept {
  return *cusolver_handles.getLocal();
}

// NOTE! This sticks 
inline static int get_lwork_size() noexcept {
  return *lwork_sizes.getLocal();
}

inline static double *get_lwork() noexcept {
  return *lworks.getLocal();
}

// Using an int for the lwork size is silly, but that's the BLAS/LAPACK ABI,
// so cublas/cusolver follow it.
inline static void alloc_all_lworks(int size) noexcept {
  assert(size >= 0);
  std::size_t proper_size = size;
  galois::on_each([&](unsigned int tid, unsigned int nthreads) noexcept {
    if (tid == 0) {
      if (*lworks.getLocal() != nullptr) std::free(*lworks.getLocal());
      *lworks.getLocal() = reinterpret_cast<double*>(std::aligned_alloc(sizeof(double), proper_size * sizeof(double)));
    } else {
      if (*lworks.getLocal() != nullptr) {
        auto stat = cudaFree(*lworks.getLocal());
        if (stat != cudaSuccess) GALOIS_DIE("Cuda free failed.");
      }
      auto stat = cudaMalloc(lworks.getLocal(), proper_size * sizeof(double));
      if (stat != cudaSuccess) GALOIS_DIE("Failed to allocate work buffers.");
    }
    *lwork_sizes.getLocal() = size;
  });
}

inline static int *get_dev_info() noexcept {
  return *dev_infos.getLocal();
}

