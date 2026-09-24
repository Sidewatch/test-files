// React: an orders table with a filter, hooks and a small child component.
import { useMemo, useState } from "react";

const money = (n) => new Intl.NumberFormat("en-GB", { style: "currency", currency: "GBP" }).format(n);

function StatusBadge({ status }) {
  const tone = status === "paid" ? "ok" : status === "cancelled" ? "bad" : "muted";
  return <span className={`badge badge-${tone}`}>{status}</span>;
}

export default function Orders({ orders = [] }) {
  const [query, setQuery] = useState("");
  const visible = useMemo(
    () => orders.filter((o) => String(o.number).includes(query) || o.status.includes(query)),
    [orders, query]
  );

  if (orders.length === 0) return <p className="muted">No orders yet.</p>;

  return (
    <>
      <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Filter…" />
      <table>
        <tbody>
          {visible.map((o) => (
            <tr key={o.id}>
              <td>#{o.number}</td>
              <td>{money(o.total)}</td>
              <td><StatusBadge status={o.status} /></td>
            </tr>
          ))}
        </tbody>
      </table>
      <p>{visible.length} of {orders.length}</p>
    </>
  );
}
