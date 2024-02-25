# Demo for Linking from Sphinx to Documenter

This Python project demos a Sphinx documentation that links to an external Julia project documentation via Intersphinx.

See the [Compatibility with Sphinx](http://juliadocs.org/DocumenterInterLinks.jl/stable/sphinx/) section in the [`DocumenterInterLinks`](http://juliadocs.org/DocumenterInterLinks.jl/stable/) documentation.


## Building the Documentation

This requires a recent version of [Python](https://www.python.org) and [Hatch](https://hatch.pypa.io/latest/) to be installed 

If you have the `make` installed, you can run

```
make docs
```

Or alternatively,

```
hatch run docs:build
```
