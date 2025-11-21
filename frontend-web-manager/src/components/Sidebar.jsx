/*
 * EcoCheck Sidebar Navigation
 */
import React from 'react'

const items = [
  { id: 'overview', label: 'Dashboard', icon: '📊' },
  { id: 'map', label: 'Realtime Map', icon: '🗺️' },
  { id: 'analytics', label: 'Analytics', icon: '📈' },
  { id: 'routes', label: 'Route Planning', icon: '🚚' },
  { id: 'settings', label: 'Settings', icon: '⚙️' },
]

export default function Sidebar({ active = 'overview', onNavigate }) {
  return (
    <aside className="sidebar">
      <nav className="nav">
        {items.map(it => (
          <button
            key={it.id}
            className={`nav-item ${active === it.id ? 'active' : ''}`}
            onClick={() => onNavigate?.(it.id)}
          >
            <span className="nav-ico" aria-hidden>{it.icon}</span>
            <span>{it.label}</span>
          </button>
        ))}
      </nav>
      <div className="sidebar-foot">© {new Date().getFullYear()} EcoCheck</div>
    </aside>
  )
}
