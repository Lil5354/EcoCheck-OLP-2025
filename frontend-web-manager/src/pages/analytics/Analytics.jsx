import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import KPI from '../../components/common/KPI.jsx'
import { AreaChart, Legend } from '../../components/Charts.jsx'
import api from '../../lib/api.js'

export default function AnalyticsPage() {
  const [summary, setSummary] = useState(null)
  const [timeseries, setTimeseries] = useState([])
  const [timeseriesByType, setTimeseriesByType] = useState({})
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
    if (ts.ok) {
      if (Array.isArray(ts.data)) {
        setTimeseries(ts.data)
      } else if (Array.isArray(ts.data?.series)) {
        setTimeseries(ts.data.series)
      }
      if (ts.data?.byType) {
        setTimeseriesByType(ts.data.byType)
      }
    }
  }

  async function handlePredict() {
    setLoading(true)
    const res = await api.predict({ days: 7, weather: 'sunny' })
    setLoading(false)
    if (res.ok) {
      setForecast(res.data)
    }
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
              {timeseries.length > 0 ? (
                <div style={{ marginTop: 16 }}>
                  <AreaChart
                    width={800}
                    height={200}
                    data={timeseries.map(item => ({
                      value: item.value || item.v || 0,
                      label: item.t ? new Date(item.t).toLocaleDateString('vi-VN', { month: 'short', day: 'numeric' }) : ''
                    }))}
                    color="var(--primary)"
                    stroke={3}
                    showLabels={true}
                    labelEvery={Math.max(1, Math.floor(timeseries.length / 8))}
                    labelFormatter={(value) => `${value.toFixed(1)}t`}
                  />
                  <div style={{ marginTop: 8, fontSize: 12, color: '#888', textAlign: 'center' }}>
                    Đã tải {timeseries.length} điểm dữ liệu
                  </div>
                </div>
              ) : (
                <div style={{ marginTop: 16, color: '#888', fontSize: 14 }}>
                  Đang tải dữ liệu...
                </div>
              )}
            </div>
            <div className="card">
              <h2>Dự báo</h2>
              <button className="btn btn-primary" onClick={handlePredict} disabled={loading} style={{ marginBottom: 16 }}>
                {loading ? 'Đang dự đoán...' : 'Dự đoán 7 ngày tới'}
              </button>
              {forecast && (
                <div style={{ marginTop: 16 }}>
                  <div style={{ marginBottom: 16, fontSize: 14, color: '#888' }}>
                    Thực tế: {forecast.actual?.length || 0} ngày · Dự báo: {forecast.forecast?.length || 0} ngày
                  </div>
                  {forecast.actual && forecast.forecast && (
                    <div>
                      {/* Actual data chart */}
                      <div style={{ marginBottom: 24 }}>
                        <h3 style={{ fontSize: 14, fontWeight: 500, marginBottom: 8, color: 'var(--primary)' }}>Dữ liệu thực tế</h3>
                        <AreaChart
                          width={800}
                          height={180}
                          data={(forecast.actual || []).map(item => ({
                            value: item.v || item.value || 0,
                            label: item.d ? new Date(item.d).toLocaleDateString('vi-VN', { month: 'short', day: 'numeric' }) : ''
                          }))}
                          color="var(--primary)"
                          stroke={3}
                          showLabels={true}
                          labelEvery={Math.max(1, Math.floor((forecast.actual?.length || 0) / 6))}
                          labelFormatter={(value) => `${value.toFixed(1)}t`}
                        />
                      </div>
                      {/* Forecast data chart */}
                      <div>
                        <h3 style={{ fontSize: 14, fontWeight: 500, marginBottom: 8, color: 'var(--warning)' }}>Dự báo</h3>
                        <AreaChart
                          width={800}
                          height={180}
                          data={(forecast.forecast || []).map(item => ({
                            value: item.v || item.value || 0,
                            label: item.d ? new Date(item.d).toLocaleDateString('vi-VN', { month: 'short', day: 'numeric' }) : ''
                          }))}
                          color="var(--warning)"
                          stroke={3}
                          showLabels={true}
                          labelEvery={Math.max(1, Math.floor((forecast.forecast?.length || 0) / 6))}
                          labelFormatter={(value) => `${value.toFixed(1)}t`}
                        />
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </main>
      </div>
    </div>
  )
}

