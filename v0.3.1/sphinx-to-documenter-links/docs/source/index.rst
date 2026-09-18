Demo for Linking from Sphinx to Documenter
==========================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

We can link to various elements of the :external+DocumenterInterLinks:doc:`DocumenterInterLinks<index>` and :external+DocInventories:doc:`DocInventories<index>` documentations:

* ``:jl:type:`DocumenterInterLinks.InterLinks``` renders as :jl:type:`DocumenterInterLinks.InterLinks`
* ``:jl:const:`DocInventories.MIME_TYPES``` renders as :jl:const:`DocInventories.MIME_TYPES`
* ``:jl:method:`DocInventories.save``` renders as :jl:method:`DocInventories.save`
*  ``:jl:method:`DocInventories.spec-Tuple{InventoryItem}``` renders as :jl:method:`DocInventories.spec-Tuple{InventoryItem}`
* ``:external+DocInventories:doc:`DocInventories<index>``` renders as :external+DocInventories:doc:`DocInventories<index>`
* Referencing a heading is currently not possible due to a bug in Sphinx: ``:external+DocumenterInterLinks:std:ref:`Syntax``` does not work because Sphinx lowercases the "Syntax"
* In Python, anchor names are lowercased, so referencing headings works: ``:external+sphinx:std:ref:`glossary``` renders as :external+sphinx:std:ref:`glossary`
