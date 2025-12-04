/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager - Sidebar Navigation Component
 */

import React from 'react'
import logo from '../assets/ecocheck-logo.svg'
import { MdOutlineDashboard, MdOutlineMap, MdOutlineAnalytics, MdOutlineRoute, MdOutlineSettings } from 'react-icons/md'

const navGroups = [
  {
    title: 'NAVIGATION',
    items: [
      { id: 'overview', label: 'Dashboard', icon: <MdOutlineDashboard /> },
      { id: 'map', label: 'Realtime Map', icon: <MdOutlineMap /> },
      { id: 'analytics', label: 'Analytics', icon: <MdOutlineAnalytics /> },
    ]
  },
  {
    title: 'MANAGEMENT',
    items: [
      { id: 'routes', label: 'Route Planning', icon: <MdOutlineRoute /> },
      { id: 'settings', label: 'Settings', icon: <MdOutlineSettings /> },
    ]
  }
]

export default function Sidebar({ active = 'overview', onNavigate }) {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <img src={logo} alt="EcoCheck" className="sidebar-logo" />
        <span className="sidebar-brand">EcoCheck</span>
      </div>
      <nav className="nav">
        {navGroups.map(group => (
          <div key={group.title} className="nav-group">
            <h6 className="nav-group-title">{group.title}</h6>
            {group.items.map(it => (
              <button
                key={it.id}
                className={`nav-item ${active === it.id ? 'active' : ''}`}
                onClick={() => onNavigate?.(it.id)}
              >
                <span className="nav-ico" aria-hidden>{it.icon}</span>
                <span>{it.label}</span>
              </button>
            ))}
          </div>
        ))}
      </nav>
      <div className="sidebar-foot">© {new Date().getFullYear()} EcoCheck</div>
    </aside>
  )
}
