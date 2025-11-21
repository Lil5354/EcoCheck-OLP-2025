/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Main application component
 */

import { useState, useEffect } from 'react'
import { MdSearch, MdOutlineNotifications } from 'react-icons/md'
import './App.css'
import logo from './assets/ecocheck-logo.svg'
import Sidebar from './components/Sidebar.jsx'
import RealtimeMap from './components/RealtimeMap.jsx'
import { AreaChart, DonutChart, Legend } from './components/Charts.jsx'

function App() {
  const [systemStatus, setSystemStatus] = useState('Checking...')
  const [fiwareInfo, setFiwareInfo] = useState({ status: 'Checking...', version: '', uptime: '' })
  const [lastUpdated, setLastUpdated] = useState('')
  const [loading, setLoading] = useState(false)
  const [active, setActive] = useState('overview')
  const [timeseries, setTimeseries] = useState([])
  const [byType, setByType] = useState({})
  const [kpis, setKpis] = useState({ routesActive: 0, collectionRate: 0, todayTons: 0 })

  const refresh = async () => {
    setLoading(true)
    try {
      const [statusRes, fiwareRes, tsRes, sumRes] = await Promise.all([
        fetch('/api/status'),
        fetch('/api/fiware/version'),
        fetch('/api/analytics/timeseries'),
        fetch('/api/analytics/summary')
      ])

      const statusData = await statusRes.json()
      setSystemStatus(statusData.message || 'OK')

      const fw = await fiwareRes.json()
      if (fw.ok) {
        setFiwareInfo({ status: 'Connected', version: fw.data['orionld version'], uptime: fw.data.uptime })
      } else {
        setFiwareInfo({ status: 'Offline', version: '', uptime: '' })
      }

      const ts = await tsRes.json()
      if (ts.ok) {
        setTimeseries(ts.series || [])
        setByType(ts.byType || {})
      }

      const sm = await sumRes.json()
      if (sm.ok) setKpis(sm)
    } catch (e) {
      setSystemStatus('Backend Offline')
      setFiwareInfo({ status: 'Offline', version: '', uptime: '' })
    } finally {
      setLastUpdated(new Date().toLocaleTimeString())
      setLoading(false)
    }
  }

  useEffect(() => {
    refresh()
    const id = setInterval(refresh, 30000)
    return () => clearInterval(id)
  }, [])

  const isBackendOnline = !systemStatus.toLowerCase().includes('offline')
  const isFiwareOnline = fiwareInfo.status === 'Connected'

  return (
    <div className="app layout">
      <Sidebar active={active} onNavigate={setActive} />
      <div className="content">
        <header className="header">
          <div className="container header-row">
            <div className="header-left">
                <div className="brand">
                    <img src={logo} alt="EcoCheck" width="28" height="28" />
                    <h1 className="title">EcoCheck</h1>
                </div>
            </div>
            <div className="header-right">
                <div className="toolbar">
                    <div className="search-bar">
                        <span className="icon"><MdSearch /></span>
                        <input type="text" placeholder="Search..." />
                    </div>
                    <div className="header-item">
                        <span className="icon"><MdOutlineNotifications /></span>
                    </div>
                    <div className="header-item user-profile">
                        <img src="https://via.placeholder.com/32" alt="User" className="user-avatar" />
                    </div>
                </div>
            </div>
          </div>
        </header>

        <main className="main">
          <div className="container">
            <div className="grid">
              <div className="col-4 fade-up">
                <div className="card stat-card border-blue">
                    <div className="stat-body">
                        <h5 className="stat-title">Active Routes</h5>
                        <h2 className="stat-value">{kpis.routesActive || <span className="skeleton" style={{width:50}}/>}</h2>
                        <p className="stat-trend text-success">+2.5%</p>
                    </div>
                    <div className="stat-icon">
                        {/* Placeholder for mini chart */}
                    </div>
                </div>
              </div>
              <div className="col-4 fade-up delay-1">
                <div className="card stat-card border-green">
                    <div className="stat-body">
                        <h5 className="stat-title">Collection Rate</h5>
                        <h2 className="stat-value">{kpis.collectionRate ? `${Math.round(kpis.collectionRate*100)}%` : <span className="skeleton" style={{width:60}}/>}</h2>
                        <p className="stat-trend text-danger">-1.3%</p>
                    </div>
                    <div className="stat-icon">
                        {/* Placeholder for mini chart */}
                    </div>
                </div>
              </div>
              <div className="col-4 fade-up delay-2">
                <div className="card stat-card border-yellow">
                    <div className="stat-body">
                        <h5 className="stat-title">Collected Today</h5>
                        <h2 className="stat-value">{kpis.todayTons || <span className="skeleton" style={{width:50}}/>}t</h2>
                        <p className="stat-trend text-success">+5.2%</p>
                    </div>
                    <div className="stat-icon">
                        {/* Placeholder for mini chart */}
                    </div>
                </div>
              </div>

              <section className="card col-8 fade-up delay-1">
                <h2>Collection Volume (last 12 hours)</h2>
                <AreaChart data={timeseries} color="var(--primary)" stroke={3} />
              </section>

              <section className="card col-4 fade-up delay-2">
                <h2>Waste by Type</h2>
                <DonutChart segments={byType} colors={['var(--success)','var(--accent)','var(--danger)']} />
                <Legend items={[
                  { label: 'Household', color: 'var(--success)' },
                  { label: 'Recyclable', color: 'var(--accent)' },
                  { label: 'Bulky', color: 'var(--danger)' },
                ]} />
              </section>

              <section className="card col-12 fade-up delay-3">
                <h2>Realtime Operation Map</h2>
                <RealtimeMap />
              </section>
            </div>
            <div className="footer">Last updated: {lastUpdated || '—'}</div>
          </div>
        </main>
      </div>
    </div>
  )
}

export default App
