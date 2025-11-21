import React from 'react'
import { NavLink } from 'react-router-dom'
import logo from '../assets/ecocheck-logo.svg'
import { MdOutlineDashboard, MdOutlineMap, MdOutlineAnalytics, MdOutlineRoute, MdSettings, MdLocalShipping, MdPeopleAlt, MdWarehouse, MdWarningAmber } from 'react-icons/md'

const groups = [
  {
    title: 'NAVIGATION',
    items: [
      { to: '/', label: 'Dashboard', icon: <MdOutlineDashboard /> },
    ]
  },
  {
    title: 'OPERATIONS',
    items: [
      { to: '/operations/route-optimization', label: 'Route Optimization', icon: <MdOutlineRoute /> },
      { to: '/operations/dynamic-dispatch', label: 'Dynamic Dispatch', icon: <MdOutlineMap /> },
    ]
  },
  {
    title: 'ANALYTICS',
    items: [
      { to: '/analytics', label: 'Analytics & Prediction', icon: <MdOutlineAnalytics /> },
    ]
  },
  {
    title: 'MASTER DATA',
    items: [
      { to: '/master/fleet', label: 'Fleet', icon: <MdLocalShipping /> },
      { to: '/master/personnel', label: 'Personnel', icon: <MdPeopleAlt /> },
      { to: '/master/depots-dumps', label: 'Depots & Dumps', icon: <MdWarehouse /> },
    ]
  },
  {
    title: 'EXCEPTIONS',
    items: [
      { to: '/exceptions', label: 'Exception Handling', icon: <MdWarningAmber /> },
    ]
  }
]

export default function SidebarPro() {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <img src={logo} alt="EcoCheck" className="sidebar-logo" />
        <span className="sidebar-brand">EcoCheck</span>
      </div>
      <nav className="nav">
        {groups.map(g => (
          <div key={g.title} className="nav-group">
            <h6 className="nav-group-title">{g.title}</h6>
            {g.items.map(it => (
              <NavLink key={it.to} to={it.to} className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
                <span className="nav-ico" aria-hidden>{it.icon}</span>
                <span>{it.label}</span>
              </NavLink>
            ))}
          </div>
        ))}
      </nav>
      <div className="sidebar-foot">© {new Date().getFullYear()} EcoCheck</div>
    </aside>
  )
}

