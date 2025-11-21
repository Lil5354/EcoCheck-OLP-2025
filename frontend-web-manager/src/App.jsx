/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Main application component
 */

import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [systemStatus, setSystemStatus] = useState('Checking...')
  const [environmentalData, setEnvironmentalData] = useState([])

  useEffect(() => {
    // Check backend status
    fetch('/api/status')
      .then(res => res.json())
      .then(data => setSystemStatus(data.message))
      .catch(() => setSystemStatus('Backend Offline'))

    // Fetch environmental data
    fetch('/api/environmental-data')
      .then(res => res.json())
      .then(data => setEnvironmentalData(data.data || []))
      .catch(err => console.error('Failed to fetch environmental data:', err))
  }, [])

  return (
    <div className="app">
      <header className="app-header">
        <div className="header-content">
          <h1>🌍 EcoCheck Manager Dashboard</h1>
          <p>Environmental Monitoring & Waste Management System</p>
          <div className="status-indicator">
            Status: <span className={systemStatus.includes('Offline') ? 'status-offline' : 'status-online'}>
              {systemStatus}
            </span>
          </div>
        </div>
      </header>

      <main className="main-content">
        <div className="dashboard-grid">
          <div className="card">
            <h2>📊 Environmental Monitoring</h2>
            <div className="metrics">
              <div className="metric">
                <span className="metric-label">Air Quality Index</span>
                <span className="metric-value">Good (45)</span>
              </div>
              <div className="metric">
                <span className="metric-label">Temperature</span>
                <span className="metric-value">24°C</span>
              </div>
              <div className="metric">
                <span className="metric-label">Humidity</span>
                <span className="metric-value">65%</span>
              </div>
            </div>
          </div>

          <div className="card">
            <h[object Object] Waste Collection</h2>
            <div className="collection-stats">
              <div className="stat">
                <span className="stat-number">12</span>
                <span className="stat-label">Active Routes</span>
              </div>
              <div className="stat">
                <span className="stat-number">85%</span>
                <span className="stat-label">Collection Rate</span>
              </div>
              <div className="stat">
                <span className="stat-number">3.2t</span>
                <span className="stat-label">Today's Collection</span>
              </div>
            </div>
          </div>

          <div className="card">
            <h2>🗺️ FIWARE Integration</h2>
            <div className="fiware-status">
              <p>Context Broker: <span className="status-connected">Connected</span></p>
              <p>Active Entities: <span className="entity-count">24</span></p>
              <p>Last Update: <span className="last-update">2 minutes ago</span></p>
            </div>
          </div>

          <div className="card">
            <h2>📱 Mobile App Status</h2>
            <div className="mobile-stats">
              <p>Active Citizens: <span className="user-count">156</span></p>
              <p>Active Collectors: <span className="user-count">8</span></p>
              <p>Reports Today: <span className="report-count">23</span></p>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}

export default App
