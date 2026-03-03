# Configuration file for the Sphinx documentation builder.
#
# See https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
import sys
from pathlib import Path

DOCS = Path(__file__).parent
sys.path.insert(0, str((DOCS / "_extensions").resolve()))


# -- Project information -----------------------------------------------------

project = 'test-sphinx-to-documenter-links'
copyright = '2024, Michael Goerz'
author = 'Michael Goerz'

# The full version, including alpha/beta/rc tags
release = '0.0.1'


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "julia_domain",
    "sphinx.ext.intersphinx",
]

intersphinx_mapping = {
    "sphinx": ("https://www.sphinx-doc.org/en/master/", None),
    "DocumenterInterLinks":
        ("http://juliadocs.org/DocumenterInterLinks.jl/stable/", None),
    "DocInventories":
        ("https://juliadocs.org/DocInventories.jl/stable/", None),
}

# -- Options for HTML output -------------------------------------------------

html_theme = 'sphinx_rtd_theme'
