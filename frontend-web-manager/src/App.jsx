/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Main application component
 */

import { useState, useEffect } from 'react'
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
            <div className="brand">
              <img src={logo} alt="EcoCheck" width="28" height="28" />
              <h1 className="title">EcoCheck Dashboard</h1>
            </div>
            <div className="toolbar">
              <div className="status">
                <span className={`badge ${isBackendOnline ? 'online' : 'offline'}`}>Backend</span>
                <span className={`badge ${isFiwareOnline ? 'online' : 'offline'}`}>Orion-LD</span>
              </div>
              <button className="btn" onClick={refresh} disabled={loading}>
                {loading && <span className="spin" />} Refresh
              </button>
            </div>
          </div>
        </header>

        <main className="main">
          <div className="container">
            <div className="grid">
              <section className="card col-4 fade-up">
                <h2>Active Routes</h2>
                <div className="stat-number">{kpis.routesActive || <span className="skeleton" style={{width:50}}/>}</div>
              </section>
              <section className="card col-4 fade-up delay-1">
                <h2>Collection Rate</h2>
                <div className="stat-number">{kpis.collectionRate ? `${Math.round(kpis.collectionRate*100)}%` : <span className="skeleton" style={{width:60}}/>}</div>
              </section>
              <section className="card col-4 fade-up delay-2">
                <h2>Collected Today</h2>
                <div className="stat-number">{kpis.todayTons || <span className="skeleton" style={{width:50}}/>}t</div>
              </section>

              <section className="card col-8 fade-up delay-1">
                <h2>Collection Volume (last 12 hours)</h2>
                <AreaChart data={timeseries} color="var(--primary)" />
              </section>

              <section className="card col-4 fade-up delay-2">
                <h2>Waste by Type</h2>
                <DonutChart segments={byType} colors={['#22c55e','#06b6d4','#ef4444']} />
                <Legend items={[
                  { label: 'Household', color: '#22c55e' },
                  { label: 'Recyclable', color: '#06b6d4' },
                  { label: 'Bulky', color: '#ef4444' },
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
