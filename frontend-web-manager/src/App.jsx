/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Main application component
 */

import React from 'react'

import { useState, useEffect } from 'react'
import { MdSearch, MdOutlineNotifications, MdPersonOutline } from 'react-icons/md'
import './App.css'
import logo from './assets/ecocheck-logo.svg'
import SidebarPro from './navigation/SidebarPro.jsx'
import RealtimeMap from './components/RealtimeMap.jsx'
import { AreaChart, DonutChart, Legend } from './components/Charts.jsx'

function App() {
  const [systemStatus, setSystemStatus] = useState('Đang kiểm tra...')
  const [fiwareInfo, setFiwareInfo] = useState({ status: 'Đang kiểm tra...', version: '', uptime: '' })
  const [lastUpdated, setLastUpdated] = useState('')
  const [timeseries, setTimeseries] = useState([])
  const [byType, setByType] = useState({})
  const [kpis, setKpis] = useState({ routesActive: 0, collectionRate: 0, todayTons: 0 })

  const refresh = async () => {
    try {
      const [statusRes, fiwareRes, tsRes, sumRes] = await Promise.all([
        fetch('/api/status'),
        fetch('/api/fiware/version'),
        fetch('/api/analytics/timeseries'),
        fetch('/api/analytics/summary')
      ])

      if (statusRes.ok) {
        try {
          const statusData = await statusRes.json()
          setSystemStatus(statusData.message || 'OK')
        } catch (e) {
          console.warn('Failed to parse status response:', e)
        }
      }

      if (fiwareRes.ok) {
        try {
          const fw = await fiwareRes.json()
          if (fw.ok) {
            setFiwareInfo({ status: 'Đã kết nối', version: fw.data?.['orionld version'] || '', uptime: fw.data?.uptime || '' })
          } else {
            setFiwareInfo({ status: 'Ngoại tuyến', version: '', uptime: '' })
          }
        } catch (e) {
          console.warn('Failed to parse fiware response:', e)
          setFiwareInfo({ status: 'Ngoại tuyến', version: '', uptime: '' })
        }
      } else {
        setFiwareInfo({ status: 'Ngoại tuyến', version: '', uptime: '' })
      }

      if (tsRes.ok) {
        try {
          const ts = await tsRes.json()
          if (ts.ok) {
            // Backend returns both 'series' and 'data' for compatibility
            const seriesData = ts.series || ts.data || []
            console.log('📊 Timeseries data:', seriesData.length, 'points')
            setTimeseries(seriesData)
            if (ts.byType) {
              console.log('📊 ByType data:', ts.byType)
              setByType(ts.byType)
            }
          }
        } catch (e) {
          console.warn('Failed to parse timeseries response:', e)
        }
      }

      if (sumRes.ok) {
        try {
          const sm = await sumRes.json()
          if (sm.ok) {
            // Handle both {ok: true, data: {...}} and {ok: true, ...} formats
            const summaryData = sm.data || sm
            console.log('📊 Summary data:', summaryData)
            setKpis(summaryData)
            // Also set byType from summary if available
            if (summaryData.byType) {
              console.log('📊 ByType from summary:', summaryData.byType)
              setByType(summaryData.byType)
            }
          }
        } catch (e) {
          console.warn('Failed to parse summary response:', e)
        }
      }
    } catch (error) {
      console.error('Error refreshing data:', error)
      setSystemStatus('Backend ngoại tuyến')
      setFiwareInfo({ status: 'Ngoại tuyến', version: '', uptime: '' })
    } finally {
      setLastUpdated(new Date().toLocaleTimeString())
    }
  }

  useEffect(() => {
    refresh()
    const id = setInterval(refresh, 30000)
    return () => clearInterval(id)
  }, [])

  return (
    <div className="app layout">
      <SidebarPro />
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
                        <input type="text" placeholder="Tìm kiếm..." />
                    </div>
                    <div className="header-item">
                        <span className="icon"><MdOutlineNotifications /></span>
                    </div>
                    <div className="header-item user-profile">
                        <span className="icon"><MdPersonOutline /></span>
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
                        <h5 className="stat-title">Tuyến đang hoạt động</h5>
                        <h2 className="stat-value">{kpis.routesActive !== undefined ? kpis.routesActive : <span className="skeleton" style={{width:50}}/>}</h2>
                        {kpis.routesActiveChange !== undefined ? (
                          <p className={`stat-trend ${kpis.routesActiveChange >= 0 ? 'text-success' : 'text-danger'}`}>
                            {kpis.routesActiveChange >= 0 ? '+' : ''}{kpis.routesActiveChange.toFixed(1)}%
                          </p>
                        ) : null}
                    </div>
                    <div className="stat-icon">
                        {/* Placeholder for mini chart */}
                    </div>
                </div>
              </div>
              <div className="col-4 fade-up delay-1">
                <div className="card stat-card border-green">
                    <div className="stat-body">
                        <h5 className="stat-title">Tỷ lệ thu gom</h5>
                        <h2 className="stat-value">{kpis.collectionRate !== undefined ? `${Math.round(kpis.collectionRate*100)}%` : <span className="skeleton" style={{width:60}}/>}</h2>
                        {kpis.collectionRateChange !== undefined ? (
                          <p className={`stat-trend ${kpis.collectionRateChange >= 0 ? 'text-success' : 'text-danger'}`}>
                            {kpis.collectionRateChange >= 0 ? '+' : ''}{kpis.collectionRateChange.toFixed(1)}%
                          </p>
                        ) : null}
                    </div>
                    <div className="stat-icon">
                        {/* Placeholder for mini chart */}
                    </div>
                </div>
              </div>
              <div className="col-4 fade-up delay-2">
                <div className="card stat-card border-yellow">
                    <div className="stat-body">
                        <h5 className="stat-title">Thu gom hôm nay</h5>
                        <h2 className="stat-value">{kpis.todayTons !== undefined ? `${kpis.todayTons.toFixed(1)}` : <span className="skeleton" style={{width:50}}/>}t</h2>
                        {kpis.todayTonsChange !== undefined ? (
                          <p className={`stat-trend ${kpis.todayTonsChange >= 0 ? 'text-success' : 'text-danger'}`}>
                            {kpis.todayTonsChange >= 0 ? '+' : ''}{kpis.todayTonsChange.toFixed(1)}%
                          </p>
                        ) : null}
                    </div>
                    <div className="stat-icon">
                        {/* Placeholder for mini chart */}
                    </div>
                </div>
              </div>

              <section className="card col-8 fade-up delay-1">
                <h2>Khối lượng thu gom (12 giờ qua)</h2>
                {timeseries.length > 0 ? (
                  <AreaChart 
                    data={timeseries} 
                    color="var(--primary)" 
                    stroke={3}
                    width={520}
                    height={140}
                  />
                ) : (
                  <div style={{ padding: 40, textAlign: 'center', color: '#888' }}>
                    Đang tải dữ liệu...
                  </div>
                )}
              </section>

              <section className="card col-4 fade-up delay-2">
                <h2>Rác theo loại</h2>
                {Object.keys(byType).length > 0 ? (
                  <>
                    <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
                      <DonutChart 
                        segments={byType} 
                        colors={['#4caf50', '#2196f3', '#f44336']}
                        size={140}
                      />
                    </div>
                    <Legend items={[
                      { label: 'Sinh hoạt', color: '#4caf50' },
                      { label: 'Tái chế', color: '#2196f3' },
                      { label: 'Cồng kềnh', color: '#f44336' },
                    ]} />
                  </>
                ) : (
                  <div style={{ padding: 40, textAlign: 'center', color: '#888' }}>
                    Chưa có dữ liệu
                  </div>
                )}
              </section>

              <section className="card col-12 fade-up delay-3">
                <h2>Bản đồ vận hành thời gian thực</h2>
                <RealtimeMap />
              </section>
            </div>
            <div className="footer">Cập nhật lần cuối: {lastUpdated || '—'}</div>
          </div>
        </main>
      </div>
    </div>
  )
}

export default App
