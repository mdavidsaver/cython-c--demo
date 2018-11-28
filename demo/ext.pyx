# distutils: language = c++
# cython: language_level=2

from cpython.object cimport PyObject

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
        @staticmethod
        Derived1* cast(Base*)

    # workaround for https://github.com/cython/cython/issues/2143
    ctypedef Derived1* Derived1p

    cdef cppclass Derived2(Base):
        Derived1()
        const char *name() const
        void oops() except+

cdef class Holder:
    # Reference to c++ object
    cdef shared_ptr[Base] ptr
    # each time self.ptr is retargeted, we inspect the new pointer
    # to see if it is a Derived1.  If so, we store an extra reference here
    # so the garbage collector can "see through" the shared_ptr
    cdef public object seethrough
    cdef object __weakref__
    __slot__ = () # prevent creation of unexpected attributes

    def __cinit__(self):
        self.seethrough = None

    # helper method
    cdef setPtr(self, shared_ptr[Base] ptr):
        cdef Derived1* d1 = dynamic_cast[Derived1p](ptr.get()) # Derived1.cast(ptr.get())
        self.ptr = ptr
        if d1 and d1.ref.obj:
            self.seethrough = static_cast[object](d1.ref.obj)
        else:
            self.seethrough = None

    @staticmethod
    def make1(obj):
        cdef shared_ptr[Base] ptr
        ptr.reset(new Derived1(<PyObject*>obj))
        I = Holder()
        I.setPtr(ptr)
        return I

    @staticmethod
    def make2():
        cdef shared_ptr[Base] ptr
        ptr.reset(new Derived2())
        I = Holder()
        I.setPtr(ptr)
        return I

    @property
    def name(self):
        return deref(self.ptr).name()

    def oops(self):
        deref(self.ptr).oops()

    @staticmethod
    def count():
        return Base.count()
