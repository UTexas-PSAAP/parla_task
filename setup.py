from setuptools import setup
from Cython.Build import cythonize
from distutils.extension import Extension

Extensions = [
    Extension("parla_task.task_wrappers",
        ["parla_task/task_wrappers.pyx"],
        #libraries = ["numa"]
        extra_compile_args = ["-std=c++14"]
    )
]

setup(
    name = "parla_task",
    packages = ["parla_task"],
    ext_modules = cythonize(Extensions)
)
