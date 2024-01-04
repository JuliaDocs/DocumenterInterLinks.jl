# Compatibility with Sphinx

!!! info
    This section goes into some fairly technical details. You do not need to read it unless you use both Documenter and Sphinx and plan to link both ways between Julia and Python projects.

`DocumenterInterLinks` is interoperable with [Sphinx](@extref sphinx :doc:`index`) and [Intersphinx](@extref sphinx :doc:`usage/extensions/intersphinx`): The [`InterLinks`](@ref) object can refer to the [`objects.inv`](@extref sphinx :doc:`usage/extensions/intersphinx`) file that Sphinx automatically writes out for every project. This makes it possible to easily link to virtually every Python project (as well as any other C/C++/Fortran project that uses Sphinx for its documentation).

The possible specification ```:domain:role:`name` ``` in an `@extref` link mimics [the cross-referencing syntax in Sphinx](@extref sphinx xref-syntax). However, Sphinx [reStructuredText](@extref sphinx :doc:`usage/restructuredtext/index`) is much more explicit than Documenter's [markdown syntax](@extref Documenter :doc:`man/syntax`). In particular, the domain and role are *required* for every reference (although projects can set up a default domain, usually `py`, which can then be omitted). This is not the case in the `@extref` syntax defined by `DocumenterInterLinks`, where domain and role are for disambiguation only and can (and usually should) be omitted.

Moreover, [domains and roles](@extref sphinx :module:`sphinx.domains`) must be *formally  defined* in Sphinx. In fact, Sphinx makes a distinction between "type" and "role". Strictly speaking, the `objects.inv` file records an "object type", like `function` or `module`, which [`DocInventories.InventoryItem`](@extref) reads in as `role`. A Sphinx domain then defines "roles" on top of that which are used for *referencing* object. The formal definition of the domain includes a mapping between an object type and one or more roles. Consider for example the code of the [`PythonDomain`](https://www.sphinx-doc.org/en/master/_modules/sphinx/domains/python.html#PythonDomain), which defines an object type `function` with associated roles `func` and `obj`. In contrast, `DocumenterInterLinks` has no formally defined domains and makes no distinction between object types and roles. Thus, the inventory item ```links["matplotlib"][":py:function:`matplotlib.get_backend`"]``` would be referenced as ```:py:func:`matplotlib.get_backend` ``` (using `:func:`, not `:function:`!) or ```:py:obj:`matplotlib.get_backend` ``` in Sphinx, but as ```[`get_backend`](@extref :py:function:`matplotlib.get_backend`)``` in `DocumenterInterLinks`, or more simply without any domain or role as ```[`matplotlib.get_backend`](@extref)```.


### Referencing the Julia domain in Sphinx

The formal nature of Sphinx domains also has consequences for referencing Julia objects from within a Sphinx project. Linking from a project using Sphinx as a documentation generator to a Julia project using Documenter and the automatic [inventory generation](@ref Inventory-Generation) provided by `DocumenterInterLinks` will not work out of the box. This is because Sphinx does not know about the `jl` domain. In this sense, the `jl` domain is considered "ad-hoc".

There is a [Sphinx-Julia](https://github.com/bastikr/sphinx-julia) package, but that package is currently not functional, and only partially supports the object types / roles used here in [The Julia Domain](@ref).

Thus, any Sphinx project that wants to link to inventory items in the `jl` domain must first formally specify that domain. This could be done by adding the following code to the Sphinx [`conf.py` file](@extref sphinx :doc:`usage/quickstart`) (or an [extension](@extref sphinx :doc:`development/index`)):


```python
from sphinx.domains import Domain, ObjType
from sphinx.roles import XRefRole

class JuliaDomain(Domain):
    """A minimal Julia language domain."""

    name = 'jl'
    label = 'Julia'
    object_types = {
        # name => (localized name, *roles)
        'macro': ObjType('macro', 'macro', 'obj'),
        'keyword': ObjType('keyword', 'keyword', 'obj'),
        'function': ObjType('function', 'func', 'function', 'obj'),
        'method': ObjType('method', 'meth', 'method', 'obj'),
        'type': ObjType('type', 'type', 'obj'),
        'module': ObjType('module', 'mod', 'module', 'obj'),
        'constant': ObjType('constant', 'const', 'constant', 'obj'),
    }

    roles = {
        'macro': XRefRole(fix_parens=True),
        'keyword': XRefRole(),
        'function': XRefRole(fix_parens=True),
        'func': XRefRole(fix_parens=True),
        'method': XRefRole(fix_parens=True),
        'meth': XRefRole(fix_parens=True),
        'type': XRefRole(fix_parens=True),
        'module': XRefRole(),
        'mod': XRefRole(),
        'constant': XRefRole(),
        'const': XRefRole(),
        'obj': XRefRole(),
    }


def setup(app):
    app.add_domain(JuliaDomain)
```

We have used Sphinx' [Domain API](@extref sphinx domain-api) here to define the object types matching our [Julia Domain](@ref The-Julia-Domain). For each object type, we define a role of the same name, as well as abbreviated roles in line with Sphinx' usual conventions, such as `:func:` as a shorthand for `:function:` and `obj` for any type.
