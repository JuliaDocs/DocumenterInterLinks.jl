Demo for Linking from Sphinx to Documenter
==========================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

We can link to various elements of the :external+DocumenterInterLinks:doc:`DocumenterInterLinks<index>` and :external+DocInventories:doc:`DocInventories<index>` documentations:

* ``:jl:type:`DocumenterInterLinks.InterLinks``` renders as :jl:type:`DocumenterInterLinks.InterLinks`
* ``:jl:const:`DocInventories.MIME_TYPES``` renders as :jl:const:`DocInventories.MIME_TYPES`
* ``:jl:method:`DocInventories.save``` renders as :jl:method:`DocInventories.save`
* ``:jl:method:`DocInventories.spec-Tuple{InventoryItem}``` renders as :jl:method:`DocInventories.spec-Tuple{InventoryItem}`
* ``:external+DocInventories:doc:`DocInventories<index>``` renders as :external+DocInventories:doc:`DocInventories<index>`
* ``:external+DocumenterInterLinks:std:ref:`Syntax``` renders as
  :external+DocumenterInterLinks:std:ref:`Syntax`. Note that this
  `requires Sphinx 7.3 <https://www.sphinx-doc.org/en/master/changes.html#release-7-3-0-released-apr-16-2024>`_.
  In older versions of Sphinx, linking to a heading in a Julia project is not possible due to
  `issue #12008 <https://github.com/sphinx-doc/sphinx/issues/12008>`_.
