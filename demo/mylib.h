#ifndef MYLIB_H
#define MYLIB_H

#include <stdlib.h>
#include <stdexcept>

#include <Python.h>

// smart pointer to manage python refcounter
struct PyRef {
    PyObject *obj;

    PyRef() :obj(0) {}
    PyRef(PyObject* obj) :obj(obj) {}
    PyRef(const PyRef&) = delete;
    PyRef(PyRef&& o) :obj(o.obj) {
        o.obj = 0;
    }
    ~PyRef() { Py_XDECREF(obj); }

    static
    PyRef borrow(PyObject *obj) {
        PyRef ret(obj);
        Py_XINCREF(ret.obj);
        return ret;
    }
};

struct Base {
    static size_t num_instances;

    Base() {num_instances++;}
    Base(const Base&) = delete;
    Base& operator=(const Base&) = delete;
    virtual ~Base() {num_instances--;}

    virtual const char *name() const { return "Base"; }
    virtual void oops() =0;

    static size_t count() { return num_instances; }
};

size_t Base::num_instances;

// This derived class also holds a reference to a python object
struct Derived1 : public Base {
    Derived1() {}
    explicit Derived1(PyObject *obj) :ref(PyRef::borrow(obj)) {}
    virtual ~Derived1() {}
    virtual const char *name() const { return "Derived1"; }
    virtual void oops() {
        throw std::runtime_error("oops");
    }
    PyRef ref;
};

// workaround for https://github.com/cython/cython/issues/2143
typedef Derived1* Derived1p;

struct Derived2 : public Base {
    virtual ~Derived2() {}
    virtual const char *name() const { return "Derived2"; }
    virtual void oops() {
        throw std::runtime_error("oops");
    }
};

#endif // MYLIB_H
