import { useState, useCallback } from "react";

interface BadgeProps {
  label: string;
  count?: number;
  onSelect?: (id: string) => void;
}

type Variant = "primary" | "ghost";

function Badge({ label, count = 0, onSelect }: BadgeProps) {
  return (
    <span className="badge" data-count={count} onClick={() => onSelect?.(label)}>
      {label}
    </span>
  );
}

export default function Toolbar<T extends { id: string }>({ items }: { items: T[] }) {
  const [active, setActive] = useState<string | null>(null);
  const pick = useCallback((id: string) => setActive(id), []);

  return (
    <>
      <nav className="toolbar" aria-label="Main">
        {items.map((item) => (
          <Badge key={item.id} label={item.id} count={items.length} onSelect={pick} />
        ))}
        <button type="button" disabled={active === null} onClick={() => setActive(null)}>
          Clear
        </button>
      </nav>
      {active && <p className="hint">Selected: {active}</p>}
    </>
  );
}
