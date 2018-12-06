# distutils: language = c++
# cython: language_level=2

import cython

from cpython.object cimport PyObject, PyTypeObject, traverseproc, visitproc

from cython.operator cimport dereference as deref

from libcpp.memory cimport shared_ptr
from libcpp.cast cimport static_cast, dynamic_cast

cdef extern from "mylib.h":
    cdef cppclass PyRef:
        PyObject* obj

    cdef cppclass Base:
        Base()
        const char *name() const
        void oops() except+
        @staticmethod
        size_t count()

    cdef cppclass Derived1(Base):
        Derived1()
        Derived1(PyObject*)
        const char *name() const
        void oops() except+
        PyRef ref

    # workaround for https://github.com/cython/cython/issues/2143
    ctypedef Derived1* Derived1p

    cdef cppclass Derived2(Base):
        Derived1()
        const char *name() const
        void oops() except+

@cython.no_gc_clear # pretend we can't break the association through our shared_ptr
cdef class Holder:
    # Reference to c++ object
    cdef shared_ptr[Base] ptr

    # force generation of tp_traverse, otherwise unused
    cdef object dummy

    cdef object __weakref__
    __slot__ = () # prevent creation of unexpected attributes

    @staticmethod
    def make1(obj):
        I = Holder()
        I.ptr.reset(new Derived1(<PyObject*>obj))
        return I

    @staticmethod
    def make2():
        I = Holder()
        I.ptr.reset(new Derived2())
        return I

    @property
    def name(self):
        return deref(self.ptr).name()

    def oops(self):
        deref(self.ptr).oops()

    @staticmethod
    def count():
        return Base.count()

# We will insert our own tp_traverse to the Holder type.
# Store the original here so we can call it later
cdef traverseproc holder_base_traverse

# our replacement
cdef int holder_traverse(PyObject* raw, visitproc visit, void* arg):
    cdef int ret = 0
    cdef Holder self = <Holder>raw
    cdef Derived1* derv

    if self.ptr: # shared pointer may be null
        derv = dynamic_cast[Derived1p](self.ptr.get())
        if derv and derv.ref.obj: # may not point to Derived1, or maybe python ref is null
            visit(derv.ref.obj, arg)

    # call into the generated type
    ret = holder_base_traverse(raw, visit, arg)

    return ret

cdef PyTypeObject* holder = <PyTypeObject*>Holder

holder_base_traverse = holder.tp_traverse
assert holder_base_traverse!=NULL
holder.tp_traverse = holder_traverse
