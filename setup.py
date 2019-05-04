from setuptools import setup
from Cython.Build import cythonize
from distutils.extension import Extension

Extensions = [
    Extension("parla_task.task_wrappers",
        ["parla_task/task_wrappers.pyx"],
        libraries = ["galois_shmem"],
        #libraries = ["numa"]
        extra_compile_args = ["-std=c++17"]
    ),
    Extension("parla_task.gpu_map",
        ["parla_task/gpu_map.pyx"],
        libraries = ["cudart", "cublas", "cusolver", "galois_shmem"],
        extra_compile_args = ["-std=c++17"]
    ),
]

setup(
    name = "parla_task",
    packages = ["parla_task"],
    ext_modules = cythonize(Extensions)
)
