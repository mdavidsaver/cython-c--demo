#!/usr/bin/env python

import sys
from setuptools import setup, Extension
from Cython.Build import cythonize

ext = Extension('demo.ext', ['demo/ext.pyx'],
                extra_compile_args=['-std=c++11'])

setup(
    name='cythonxx-demo',
    packages = ['demo', 'demo.test'],
    ext_modules=cythonize([ext]),
)
