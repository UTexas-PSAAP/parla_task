# distutils: language = c++

cdef extern from "map_onto_gpu.h" nogil:
    struct cublasHandle_t:
        pass
    struct cusolverDnHandle_t:
        pass

    void bind_threads_to_gpus()
    unsigned int get_thread_id() 
    cublasHandle_t get_cublas_context()
    cusolverDnHandle_t get_cusolver_context()
    int get_lwork_size()
    double *get_lwork()
    int *get_dev_info()

def bind_devices():
    bind_threads_to_gpus()

def get_device():
    if get_thread_id():
        return ("gpu", get_thread_id() - 1)
    return ("cpu", 0)
