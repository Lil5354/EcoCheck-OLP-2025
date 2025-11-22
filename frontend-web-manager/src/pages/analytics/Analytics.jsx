import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import KPI from '../../components/common/KPI.jsx'
import api from '../../lib/api.js'

export default function AnalyticsPage() {
  const [summary, setSummary] = useState(null)
  const [timeseries, setTimeseries] = useState([])
  const [forecast, setForecast] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    setLoading(true)
    const [s, ts] = await Promise.all([api.getSummary(), api.getTimeseries()])
    setLoading(false)
    if (s.ok) setSummary(s.data)
    if (ts.ok) setTimeseries(ts.data)
  }

  async function handlePredict() {
    setLoading(true)
    const res = await api.predict({ days: 7, weather: 'sunny' })
    setLoading(false)
    if (res.ok) setForecast(res.data)
  }

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Phân tích & Dự đoán (CN8)</h1>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginBottom: 24 }}>
              {summary && (
                <>
                  <div className="card">
                    <KPI label="Tổng thu gom" value={summary.totalTons} unit="tấn" color="var(--success)" />
                  </div>
                  <div className="card">
                    <KPI label="Điểm hoàn thành" value={summary.completed} color="var(--primary)" />
                  </div>
                  <div className="card">
                    <KPI label="Tiết kiệm nhiên liệu" value={`${Math.round(summary.fuelSaving * 100)}%`} color="var(--warning)" />
                  </div>
                </>
              )}
            </div>
            <div className="card" style={{ marginBottom: 24 }}>
              <h2>Chuỗi thời gian thu gom</h2>
              <div style={{ marginTop: 16, color: '#888', fontSize: 14 }}>
                Đã tải {timeseries.length} điểm dữ liệu. (Biểu đồ tạm thời)
              </div>
            </div>
            <div className="card">
              <h2>Dự báo</h2>
              <button className="btn btn-primary" onClick={handlePredict} disabled={loading}>
                {loading ? 'Đang dự đoán...' : 'Dự đoán 7 ngày tới'}
              </button>
              {forecast && (
                <div style={{ marginTop: 16 }}>
                  <div style={{ fontSize: 14, color: '#888' }}>
                    Thực tế: {forecast.actual.length} ngày · Dự báo: {forecast.forecast.length} ngày
                  </div>
                </div>
              )}
            </div>
          </div>
        </main>
      </div>
    </div>
  )
}

