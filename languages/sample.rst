Inventory service
=================

.. contents:: On this page
   :depth: 2

The **inventory service** keeps stock levels for every *warehouse* and
answers reorder questions. See `the deployment guide`_ for rollout steps.

Endpoints
---------

``GET /orders``
    The orders, newest first.
``POST /orders``
    Place an order; returns ``201 Created``.

.. code-block:: bash

   curl -s https://api.example.com/orders | jq '.[0]'

Configuration
-------------

=============  =======  =================
Key            Default  Notes
=============  =======  =================
REORDER_POINT  25       per SKU
LOG_LEVEL      info     debug, info, warn
=============  =======  =================

.. note::

   Cancelled orders are excluded from revenue totals.

.. _the deployment guide: https://example.com/docs/deploy
