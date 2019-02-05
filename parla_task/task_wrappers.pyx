# distutils: language = c++
# Note: above comments guarantee linkage to Galois runtime and
# that a C++ file is generated instead of C.

# The corresponding pxd file of the same name is implicitly included.

from libcpp cimport bool
from libcpp.vector cimport vector
from libc.stddef cimport size_t
from libc.stdint cimport uintptr_t

import numba
import numba.ccallback
import ctypes
import psutil

cdef extern from "task_graph.hpp" nogil:
    cdef cppclass cpp_task "task":
        cpp_task()
        bool operator==(cpp_task &)
        bool operator!=(cpp_task &)
    cdef cppclass cpp_task_ref "task_ref":
        cpp_task_ref()
        cpp_task_ref(cpp_task)
        bool operator==(cpp_task_ref &)
        bool operator!=(cpp_task_ref &)
    void run_generation_task_cpp "run_generation_task"(void (*operation)(void*, void*), void *closure)
    cpp_task create_task_cpp "create_task"(void *ctx, void (*operation)(void*, void*), void *closure, size_t num_deps, cpp_task_ref *dependencies)

cdef extern from "galois/Threads.h" nogil:
    unsigned int setActiveThreads(unsigned int num);

cdef class task(object):
    cdef cpp_task owned_task
    cdef object operation
    cdef object closure
    def __eq__(task self, task other):
        return self.owned_task == other.owned_task
    def __ne__(task self, task other):
        return self.owned_task != other.owned_task

cdef cpp_task_ref _get_cpp_task_ref(task t) except *:
    if t is None:
        raise ValueError("Cannot extract underlying task object from None.")
    return cpp_task_ref(t.owned_task)

setActiveThreads(psutil.cpu_count(logical=False))

ctypedef void(*_operation_ptr)(void*, void*) nogil;

cdef _operation_ptr _get_operation_ptr(operation) except NULL:
    if type(operation) is numba.ccallback.CFunc:
        # Not immediately obvious how to assert that the signature is correct,
        # so trust the user for now.
        return <_operation_ptr>(<uintptr_t>operation.address)
    elif type(operation) is numba.targets.registry.CPUDispatcher:
        compile_result = operation.overloads[(numba.voidptr, numba.pyobject)]
        if compile_result.signature.return_type is not numba.void:
            raise ValueError("Function run inside task must "
                             "not return anything.")
        raise NotImplementedError("Please use cfunc decorator instead. "
                                  "Using a compiler result object is "
                                  "not yet supported.")
    return (<_operation_ptr*>(<uintptr_t>(int(ctypes.addressof(operation)))))[0]

def run_generation_task(operation, closure):
    # TODO: What is a better way to allow passing the context pointer?
    # For now just assume it's being passed as an actual Python object,
    # but that seems like a dubious way to do things.
    run_generation_task_cpp(_get_operation_ptr(operation),
                            <void*>(<uintptr_t>id(closure)))

# For now assume context is a Python object wrapping the raw void pointer.
# TODO: Make thie JIT callable without interpreter overhead.
def create_task(context, operation, closure, list dependencies):
    cdef size_t size = len(dependencies)
    cdef vector[cpp_task_ref] deps
    cdef size_t i
    for i in range(size):
        if type(dependencies[i]) is not task:
            raise ValueError("Non-task object passed as dependency.")
        deps.push_back(_get_cpp_task_ref(dependencies[i]))
    cdef task ret = task.__new__(task)
    ret.owned_task = create_task_cpp(<void*>(<size_t>context), _get_operation_ptr(operation), <void*>(<uintptr_t>id(closure)), size, deps.data())
    ret.operation = operation
    ret.closure = closure
    return ret
