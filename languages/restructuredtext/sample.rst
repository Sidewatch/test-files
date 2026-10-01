.. This is a comment: an explicit markup start followed by text.
   Indented continuation lines belong to the comment.
   TODO: document the warehouse API. FIXME: link the changelog.

..
   A comment that starts on the line after the marker.

.. meta::
   :description: reStructuredText syntax showcase
   :keywords: inventory, warehouse

.. |version| replace:: 1.4.0
.. |logo| image:: images/logo.png
   :alt: Company logo
   :width: 120px
.. |date| date:: %Y-%m-%d
.. |br| unicode:: U+000A

=====================
Inventory service
=====================
---------------------
A syntax showcase
---------------------

:Author: Acme Reports Team
:Version: |version|
:Date: |date|
:Copyright: Example Ltd
:Abstract: Keeps stock levels for every warehouse.

.. contents:: On this page
   :depth: 2
   :local:

.. sectnum::

Section level one
=================

The **inventory service** keeps stock levels for every *warehouse* and
answers reorder questions. Inline literal: ``GET /orders``. Interpreted
text with a role: :emphasis:`stressed`, :strong:`bold`, :code:`print(1)`,
:sub:`sub`, :sup:`sup`, :math:`E = mc^2`, :ref:`deployment-guide`,
:doc:`other document </guide/start>`, :term:`warehouse`, :pep:`8`, :rfc:`2616`,
:kbd:`Ctrl+C`, :file:`/etc/inventory.conf`, :command:`ls`, :program:`gunicorn`,
:py:func:`os.path.join`, :py:class:`dict`, :c:func:`printf`.
Default role: `interpreted text`. Substitutions: |logo| and |br| .

Standalone hyperlinks: https://example.com and mail me at support@example.com.
Named link: `the deployment guide`_ and an anonymous one: `Example`__ and
an embedded one: `Example <https://example.com/embedded>`_.
Footnotes: [1]_, [#]_, [#label]_, [*]_ and citations [CIT2002]_.
Reference to a target: inventory_ and `phrase target`_ and internal_target_.

Section level two
-----------------

Line blocks keep their line breaks:

| First line
| Second line
|     indented line
| Last line

Section level three
~~~~~~~~~~~~~~~~~~~

Section level four
^^^^^^^^^^^^^^^^^^

Section level five
""""""""""""""""""

Section level six
'''''''''''''''''

Lists
=====

* A bullet list item
* Another item, with a nested list:

  - Nested dash item
  - Another nested item

    + Deeper plus item

#. Auto-numbered item
#. Another auto-numbered item

1. Arabic numbered item
2. Second item

   a. Nested lowercase letter
   b. Second letter

(i) Roman numeral in parentheses
(ii) Second numeral

A. Uppercase letter
B. Second uppercase

term 1
    Definition of term 1, indented below.

term 2 : classifier
    Definition of term 2 with a classifier.

    A second paragraph of the definition.

:Field name: Field body
:Another field: Another body,
                continued on a second line.

-a            Short option description
--long        Long option description
--file=FILE   Option with an argument
-f FILE, --file FILE   Both forms
/V            DOS-style option

Literal blocks
==============

An introduction ending with a double colon::

    Indented literal block.
    No *markup* is processed here.

Quoted literal block::

> Quoted literal line one
> Quoted literal line two

.. code-block:: bash
   :linenos:
   :emphasize-lines: 1

   curl -s https://api.example.com/orders | jq '.[0]'

.. code-block:: python
   :caption: stock.py

   def reorder(qty, point=25):
       return qty <= point

.. code:: json

   {"sku": "AC-1001", "qty": 25}

.. sourcecode:: sql

   SELECT sku, quantity FROM stock WHERE quantity < 10;

.. highlight:: c

.. literalinclude:: ../src/stock.c
   :language: c
   :lines: 1-20

.. parsed-literal::

   Parsed literal with *emphasis* and ``literals``.

Doctest block:

>>> print("doctest")
doctest
>>> 1 + 1
2

Tables
======

Simple table:

=============  =======  =================
Key            Default  Notes
=============  =======  =================
REORDER_POINT  25       per SKU
LOG_LEVEL      info     debug, info, warn
=============  =======  =================

Grid table:

+---------------+-----------+-------------------+
| Header one    | Header    | Header three      |
+===============+===========+===================+
| Row one       | cell      | * bullet in cell  |
+---------------+-----------+-------------------+
| Row two spans two columns | continues         |
+---------------+-----------+-------------------+

.. csv-table:: CSV table
   :header: "SKU", "Quantity", "Price"
   :widths: 10, 10, 10

   "AC-1001", 25, 19.99
   "AC-1002", 3, 5.00

.. list-table:: List table
   :widths: 15 10
   :header-rows: 1

   * - SKU
     - Quantity
   * - AC-1001
     - 25
   * - AC-1002
     - 3

Directives
==========

.. note::

   Cancelled orders are excluded from revenue totals.

.. warning:: Low stock on several bins.

.. tip::
.. important::
.. danger::
.. caution::
.. attention::
.. hint::
.. error::

.. admonition:: Custom title

   A generic admonition.

.. versionadded:: 1.4
   Added support for batch updates.

.. versionchanged:: 1.5
   The ``qty`` field is now required.

.. deprecated:: 2.0
   Use ``reorder`` instead.

.. seealso::

   :ref:`deployment-guide`

.. image:: images/warehouse.png
   :alt: Warehouse floor plan
   :width: 400px
   :align: center
   :target: https://example.com

.. figure:: images/chart.png
   :scale: 50 %

   Figure caption: stock by bin.

   Legend paragraph below the caption.

.. topic:: Topic title

   Topic body.

.. sidebar:: Sidebar title
   :subtitle: Subtitle

   Sidebar text.

.. rubric:: A rubric heading

.. epigraph::

   A quotation.

   -- Source

.. pull-quote::

   Pull quote text.

.. container:: custom-class

   Container content.

.. raw:: html

   <div class="raw">Raw HTML</div>

.. include:: other.rst

.. toctree::
   :maxdepth: 2
   :caption: Contents

   guide/start
   guide/deploy

.. math::

   \text{Total} = \sum_{i=1}^{n} q_i \cdot p_i

.. default-role:: literal

.. role:: custom
   :class: highlight

.. productionlist::
   order: `line` ("," `line`)*
   line: `sku` "x" `quantity`

.. index::
   single: inventory; service
   pair: stock; level

.. only:: html

   Only in HTML output.

.. function:: reorder(qty, point=25)

   Return the amount to reorder.

   :param qty: current quantity
   :type qty: int
   :returns: amount to order
   :rtype: int
   :raises ValueError: if qty is negative

.. py:class:: Warehouse(name)

   .. py:method:: capacity()

      Return the capacity.

Targets and references
======================

.. _deployment-guide:

Deployment guide
----------------

.. _inventory: https://example.com/inventory
.. _the deployment guide: https://example.com/docs/deploy
.. _phrase target: https://example.com/phrase
.. __: https://example.com/anonymous
__ https://example.com/anonymous2

_`internal_target` is an inline internal target.

.. [1] A numbered footnote.
.. [#] An auto-numbered footnote.
.. [#label] An auto-numbered labelled footnote.
.. [*] An auto-symbol footnote.
.. [CIT2002] A citation.

Transitions and blocks
======================

A transition follows:

----------

Block quote:

    An indented block quote.

    -- Attribution

Escapes: \*not emphasis\*, backslash \\, and a non-breaking\ space.
Unicode text: café — 📦 — λ.
