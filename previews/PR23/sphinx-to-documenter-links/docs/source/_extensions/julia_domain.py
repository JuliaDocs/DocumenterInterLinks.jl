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
        'macro': XRefRole(),
        'keyword': XRefRole(),
        'function': XRefRole(fix_parens=True),
        'func': XRefRole(fix_parens=True),
        'method': XRefRole(),
        'meth': XRefRole(),
        'type': XRefRole(),
        'module': XRefRole(),
        'mod': XRefRole(),
        'constant': XRefRole(),
        'const': XRefRole(),
        'obj': XRefRole(),
    }


def setup(app):
    app.add_domain(JuliaDomain)
