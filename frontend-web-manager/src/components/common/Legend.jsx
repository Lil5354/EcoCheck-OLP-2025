import React from 'react'

export default function Legend({ items = [] }) {
  return (
    <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', justifyContent: 'center', marginTop: 16 }}>
      {items.map((it, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 10, height: 10, borderRadius: 3, background: it.color }} />
          <span style={{ fontSize: 12, color: '#888' }}>{it.label}</span>
        </div>
      ))}
    </div>
  )
}

