import React from 'react'
import { NavLink } from 'react-router-dom'
import logo from '../assets/ecocheck-logo.svg'
import { MdOutlineDashboard, MdOutlineMap, MdOutlineAnalytics, MdOutlineRoute, MdSettings, MdLocalShipping, MdPeopleAlt, MdWarehouse, MdWarningAmber } from 'react-icons/md'

const groups = [
  {
    title: 'ĐIỀU HƯỚNG',
    items: [
      { to: '/', label: 'Bảng điều khiển', icon: <MdOutlineDashboard /> },
    ]
  },
  {
    title: 'VẬN HÀNH',
    items: [
      { to: '/operations/route-optimization', label: 'Tối ưu tuyến đường', icon: <MdOutlineRoute /> },
      { to: '/operations/dynamic-dispatch', label: 'Điều phối động', icon: <MdOutlineMap /> },
    ]
  },
  {
    title: 'PHÂN TÍCH',
    items: [
      { to: '/analytics', label: 'Phân tích & Dự đoán', icon: <MdOutlineAnalytics /> },
    ]
  },
  {
    title: 'DỮ LIỆU CHỦ',
    items: [
      { to: '/master/fleet', label: 'Đội xe', icon: <MdLocalShipping /> },
      { to: '/master/personnel', label: 'Nhân sự', icon: <MdPeopleAlt /> },
      { to: '/master/depots-dumps', label: 'Trạm & Bãi rác', icon: <MdWarehouse /> },
    ]
  },
  {
    title: 'NGOẠI LỆ',
    items: [
      { to: '/exceptions', label: 'Xử lý ngoại lệ', icon: <MdWarningAmber /> },
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

