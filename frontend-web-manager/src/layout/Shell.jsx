import React from 'react'
import SidebarPro from '../navigation/SidebarPro.jsx'

export default function Shell({ children, active }) {
  return (
    <div className="app layout">
      <SidebarPro active={active} />
      <div className="content">
        <main className="main">
          <div className="container">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}

