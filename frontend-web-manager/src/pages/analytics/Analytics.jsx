import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import KPI from '../../components/common/KPI.jsx'
import { AreaChart, DonutChart, Legend } from '../../components/Charts.jsx'
import api from '../../lib/api.js'

// Forecast Chart Component - shows actual vs forecast
function ForecastChart({ actual = [], forecast = [] }) {
  if (actual.length === 0 && forecast.length === 0) {
    return (
      <div style={{ padding: 40, textAlign: 'center', color: '#888' }}>
        Chưa có dữ liệu dự báo
      </div>
    )
  }

  // Convert to format: { value }
  const actualValues = actual.map(item => item.v || item.value || 0)
  const forecastValues = forecast.map(item => item.v || item.value || 0)
  
  // Combine all values for scaling
  const allValues = [...actualValues, ...forecastValues]
  const min = Math.min(...allValues)
  const max = Math.max(...allValues)
  const range = max - min || 1

  // Chart dimensions
  const width = 520
  const height = 200
  const pad = 16
  const actualColor = '#2196f3'
  const forecastColor = '#ff9800'

  // Calculate positions
  // Combine all data points for even distribution
  const totalPoints = actualValues.length + forecastValues.length
  const allXs = Array.from({ length: totalPoints }, (_, i) => 
    pad + i * ((width - 2 * pad) / (totalPoints - 1 || 1))
  )
  
  const actualXs = allXs.slice(0, actualValues.length)
  // Forecast Xs should start from the last actual point and continue
  const forecastXs = allXs.slice(actualValues.length > 0 ? actualValues.length - 1 : 0)
  
  // Ensure forecastXs has the same length as forecastValues
  if (forecastXs.length !== forecastValues.length) {
    // Recalculate forecastXs to match forecastValues length
    const startX = actualValues.length > 0 ? actualXs[actualXs.length - 1] : pad
    const endX = width - pad
    const forecastXStep = forecastValues.length > 1 ? (endX - startX) / (forecastValues.length - 1) : 0
    for (let i = 0; i < forecastValues.length; i++) {
      if (i === 0 && actualValues.length > 0) {
        forecastXs[i] = startX
      } else {
        forecastXs[i] = startX + i * forecastXStep
      }
    }
  }
  
  // Calculate Y positions with validation
  const actualYs = actualValues.map(v => {
    const numValue = Number(v) || 0
    const y = height - pad - ((numValue - min) / range) * (height - 2 * pad)
    return isNaN(y) ? height - pad : y
  })
  
  const forecastYs = forecastValues.map(v => {
    const numValue = Number(v) || 0
    const y = height - pad - ((numValue - min) / range) * (height - 2 * pad)
    return isNaN(y) ? height - pad : y
  })
  
  const forecastStartX = actualXs.length > 0 ? actualXs[actualXs.length - 1] : pad

  // Build paths with validation
  const actualPath = actualXs.map((x, i) => {
    const xVal = Number(x) || 0
    const yVal = Number(actualYs[i]) || height - pad
    return `${i ? 'L' : 'M'}${xVal},${yVal}`
  }).join(' ')
  
  const forecastPath = forecastXs.map((x, i) => {
    const xVal = Number(x) || 0
    const yVal = Number(forecastYs[i]) || height - pad
    return `${i ? 'L' : 'M'}${xVal},${yVal}`
  }).join(' ')
  
  // Build areas for gradient
  const actualArea = `M${pad},${height - pad} ${actualPath} L${forecastStartX},${height - pad} Z`
  const forecastArea = `M${forecastStartX},${height - pad} ${forecastPath} L${width - pad},${height - pad} Z`

  const actualGradientId = 'forecast-actual-gradient'
  const forecastGradientId = 'forecast-forecast-gradient'

  return (
    <div>
      <svg width="100%" height={height} viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none">
        <defs>
          <linearGradient id={actualGradientId} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor={actualColor} stopOpacity="0.35"/>
            <stop offset="100%" stopColor={actualColor} stopOpacity="0"/>
          </linearGradient>
          <linearGradient id={forecastGradientId} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor={forecastColor} stopOpacity="0.35"/>
            <stop offset="100%" stopColor={forecastColor} stopOpacity="0"/>
          </linearGradient>
        </defs>
        
        {/* Actual area */}
        {actualValues.length > 0 && (
          <>
            <path d={actualArea} fill={`url(#${actualGradientId})`} vectorEffect="non-scaling-stroke" />
            <path d={actualPath} fill="none" stroke={actualColor} strokeWidth={3} strokeLinejoin="round" strokeLinecap="round" vectorEffect="non-scaling-stroke" />
            {actualXs.map((x, i) => (
              <circle key={`actual-${i}`} cx={x} cy={actualYs[i]} r={4} fill={actualColor} stroke="#fff" strokeWidth="1" vectorEffect="non-scaling-stroke" />
            ))}
          </>
        )}
        
        {/* Forecast area */}
        {forecastValues.length > 0 && (
          <>
            <path d={forecastArea} fill={`url(#${forecastGradientId})`} vectorEffect="non-scaling-stroke" />
            <path d={forecastPath} fill="none" stroke={forecastColor} strokeWidth={3} strokeLinejoin="round" strokeLinecap="round" strokeDasharray="5,5" vectorEffect="non-scaling-stroke" />
            {forecastXs.map((x, i) => (
              <circle key={`forecast-${i}`} cx={x} cy={forecastYs[i]} r={4} fill={forecastColor} stroke="#fff" strokeWidth="1" vectorEffect="non-scaling-stroke" />
            ))}
          </>
        )}
        
        {/* Vertical separator line between actual and forecast */}
        {actualValues.length > 0 && forecastValues.length > 0 && (
          <line
            x1={forecastStartX}
            y1={pad}
            x2={forecastStartX}
            y2={height - pad}
            stroke="#ccc"
            strokeWidth={1}
            strokeDasharray="2,2"
            opacity={0.5}
            vectorEffect="non-scaling-stroke"
          />
        )}
      </svg>
      
      <div style={{ display: 'flex', gap: 24, marginTop: 16, justifyContent: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 12, height: 12, borderRadius: 2, backgroundColor: actualColor }} />
          <span style={{ fontSize: 12, color: '#666' }}>Thực tế ({actualValues.length} ngày)</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 12, height: 12, borderRadius: 2, backgroundColor: forecastColor, border: '1px dashed #ff9800' }} />
          <span style={{ fontSize: 12, color: '#666' }}>Dự báo ({forecastValues.length} ngày)</span>
        </div>
      </div>
      <div style={{ marginTop: 8, fontSize: 12, color: '#888', textAlign: 'center' }}>
        Đã tải {actualValues.length + forecastValues.length} điểm dữ liệu
      </div>
    </div>
  )
}

export default function AnalyticsPage() {
  const [summary, setSummary] = useState(null)
  const [timeseries, setTimeseries] = useState([])
  const [byType, setByType] = useState({})
  const [forecast, setForecast] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    setLoading(true)
    const [s, ts] = await Promise.all([api.getSummary(), api.getTimeseries()])
    setLoading(false)
    if (s.ok) {
      setSummary(s.data)
      // Map byType from summary if available
      if (s.data.byType) {
        setByType({
          household: s.data.byType.household || 0,
          recyclable: s.data.byType.recyclable || 0,
          bulky: s.data.byType.bulky || 0
        })
      }
    }
    if (ts.ok) {
      if (Array.isArray(ts.data)) {
        setTimeseries(ts.data)
      } else if (Array.isArray(ts.series)) {
        setTimeseries(ts.series)
      }
      if (ts.byType) {
        setByType(ts.byType)
      }
    }
  }

  async function handlePredict() {
    setLoading(true)
    const res = await api.predict({ days: 7 })
    setLoading(false)
    if (res.ok) setForecast(res.data)
  }

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Phân tích & Dự đoán</h1>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginBottom: 24 }}>
              <div className="card" style={{ borderLeft: '4px solid #4caf50' }}>
                <KPI 
                  label="Tổng thu gom" 
                  value={summary?.totalTons || summary?.todayTons || '0'} 
                  unit="tấn" 
                  color="#4caf50" 
                />
              </div>
              <div className="card" style={{ borderLeft: '4px solid #2196f3' }}>
                <KPI 
                  label="Điểm hoàn thành" 
                  value={summary?.completed || summary?.routesActive || '0'} 
                  color="#2196f3" 
                />
              </div>
              <div className="card" style={{ borderLeft: '4px solid #ff9800' }}>
                <KPI 
                  label="Tiết kiệm nhiên liệu" 
                  value={summary?.fuelSaving ? `${Math.round(summary.fuelSaving * 100)}%` : '0%'} 
                  color="#ff9800" 
                />
              </div>
            </div>
            
            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 24, marginBottom: 24 }}>
              <div className="card">
                <h2>Chuỗi thời gian thu gom</h2>
                {timeseries.length > 0 ? (
                  <>
                    <AreaChart data={timeseries} color="var(--primary)" stroke={3} />
                    <div style={{ marginTop: 8, color: '#888', fontSize: 12 }}>
                      Đã tải {timeseries.length} điểm dữ liệu
                    </div>
                  </>
                ) : (
                  <div style={{ padding: 40, textAlign: 'center', color: '#888' }}>
                    Đang tải dữ liệu...
                  </div>
                )}
              </div>
              
              <div className="card">
                <h2>Rác theo loại</h2>
                {Object.keys(byType).length > 0 ? (
                  <>
                    <DonutChart 
                      segments={byType} 
                      colors={['#4caf50', '#2196f3', '#f44336']} 
                    />
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
              </div>
            </div>
            
            <div className="card">
              <h2>Dự báo</h2>
              <button className="btn btn-primary" onClick={handlePredict} disabled={loading} style={{ marginBottom: 16 }}>
                {loading ? 'Đang dự đoán...' : 'Dự đoán 7 ngày tới'}
              </button>
              {forecast && (
                <div style={{ marginTop: 16 }}>
                  <div style={{ fontSize: 14, color: '#888', marginBottom: 16 }}>
                    Thực tế: {forecast.actual?.length || 0} ngày · Dự báo: {forecast.forecast?.length || 0} ngày
                  </div>
                  {forecast.actual && forecast.forecast && (
                    <ForecastChart actual={forecast.actual} forecast={forecast.forecast} />
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

