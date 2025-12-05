/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Air Quality Monitoring Page
 * Displays air quality data for collection points
 */

import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import api from '../../lib/api.js'
import Toast from '../../components/common/Toast.jsx'

export default function AirQuality() {
  const [aqiData, setAqiData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)
  const [location, setLocation] = useState({ lat: 10.78, lon: 106.70 }) // HCMC default
  const [customLocation, setCustomLocation] = useState({ lat: '', lon: '' })

  useEffect(() => {
    loadAirQuality()
  }, [location])

  async function loadAirQuality() {
    setLoading(true)
    try {
      const res = await api.getAirQuality(location.lat, location.lon)
      if (res.ok) {
        setAqiData(res.data)
      } else {
        setToast({ message: res.error || 'Không thể tải dữ liệu chất lượng không khí', type: 'error' })
      }
    } catch (error) {
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
    } finally {
      setLoading(false)
    }
  }

  function handleCustomLocation() {
    const lat = parseFloat(customLocation.lat)
    const lon = parseFloat(customLocation.lon)
    if (!isNaN(lat) && !isNaN(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      setLocation({ lat, lon })
    } else {
      setToast({ message: 'Tọa độ không hợp lệ', type: 'error' })
    }
  }

  function getAQIColor(aqi) {
    if (aqi <= 50) return '#10b981' // green
    if (aqi <= 100) return '#f59e0b' // yellow
    if (aqi <= 150) return '#f97316' // orange
    if (aqi <= 200) return '#ef4444' // red
    if (aqi <= 300) return '#8b5cf6' // purple
    return '#991b1b' // maroon
  }

  function getAQIIcon(aqi) {
    if (aqi <= 50) return '✅'
    if (aqi <= 100) return '⚠️'
    if (aqi <= 150) return '🔶'
    if (aqi <= 200) return '🔴'
    if (aqi <= 300) return '🟣'
    return '⚫'
  }

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>
              Chất lượng không khí
            </h1>

            {/* Location Selector */}
            <div className="card" style={{ marginBottom: 16 }}>
              <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 12 }}>Vị trí</h2>
              <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}>
                <button
                  className="btn btn-secondary"
                  onClick={() => setLocation({ lat: 10.78, lon: 106.70 })}
                  style={{ padding: '8px 16px' }}
                >
                  📍 Hồ Chí Minh (Mặc định)
                </button>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <input
                    type="number"
                    placeholder="Latitude"
                    value={customLocation.lat}
                    onChange={(e) => setCustomLocation({ ...customLocation, lat: e.target.value })}
                    style={{ width: 120, padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                    step="0.0001"
                  />
                  <input
                    type="number"
                    placeholder="Longitude"
                    value={customLocation.lon}
                    onChange={(e) => setCustomLocation({ ...customLocation, lon: e.target.value })}
                    style={{ width: 120, padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                    step="0.0001"
                  />
                  <button
                    className="btn btn-primary"
                    onClick={handleCustomLocation}
                    style={{ padding: '8px 16px' }}
                  >
                    Tìm kiếm
                  </button>
                </div>
                <button
                  className="btn btn-secondary"
                  onClick={loadAirQuality}
                  disabled={loading}
                  style={{ padding: '8px 16px' }}
                >
                  {loading ? '⏳ Đang tải...' : '🔄 Làm mới'}
                </button>
              </div>
              <div style={{ marginTop: 8, fontSize: 14, color: '#666' }}>
                Tọa độ: {location.lat.toFixed(4)}, {location.lon.toFixed(4)}
              </div>
            </div>

            {/* Air Quality Display */}
            {aqiData && (
              <div className="card" style={{ marginBottom: 16 }}>
                <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
                  {getAQIIcon(aqiData.aqi)} Chỉ số chất lượng không khí (AQI)
                </h2>
                
                <div
                  style={{
                    padding: 24,
                    borderRadius: 12,
                    backgroundColor: getAQIColor(aqiData.aqi),
                    color: 'white',
                    textAlign: 'center',
                    marginBottom: 16
                  }}
                >
                  <div style={{ fontSize: 48, fontWeight: 700, marginBottom: 8 }}>
                    {aqiData.aqi}
                  </div>
                  <div style={{ fontSize: 20, fontWeight: 600, marginBottom: 4 }}>
                    {aqiData.category}
                  </div>
                  <div style={{ fontSize: 14, opacity: 0.9 }}>
                    {aqiData.location || 'Hồ Chí Minh'}
                  </div>
                </div>

                {/* Details */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16 }}>
                  <div style={{ padding: 16, backgroundColor: '#f9fafb', borderRadius: 8 }}>
                    <div style={{ fontSize: 14, color: '#666', marginBottom: 4 }}>PM2.5</div>
                    <div style={{ fontSize: 24, fontWeight: 600 }}>{aqiData.pm25?.toFixed(1) || 'N/A'}</div>
                    <div style={{ fontSize: 12, color: '#666' }}>μg/m³</div>
                  </div>
                  <div style={{ padding: 16, backgroundColor: '#f9fafb', borderRadius: 8 }}>
                    <div style={{ fontSize: 14, color: '#666', marginBottom: 4 }}>PM10</div>
                    <div style={{ fontSize: 24, fontWeight: 600 }}>{aqiData.pm10?.toFixed(1) || 'N/A'}</div>
                    <div style={{ fontSize: 12, color: '#666' }}>μg/m³</div>
                  </div>
                  {aqiData.distance > 0 && (
                    <div style={{ padding: 16, backgroundColor: '#f9fafb', borderRadius: 8 }}>
                      <div style={{ fontSize: 14, color: '#666', marginBottom: 4 }}>Khoảng cách</div>
                      <div style={{ fontSize: 24, fontWeight: 600 }}>{(aqiData.distance / 1000).toFixed(1)}</div>
                      <div style={{ fontSize: 12, color: '#666' }}>km</div>
                    </div>
                  )}
                </div>

                {/* Health Recommendations */}
                <div style={{ marginTop: 16, padding: 16, backgroundColor: '#fef3c7', borderRadius: 8 }}>
                  <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>💡 Khuyến nghị</h3>
                  {aqiData.aqi <= 50 && (
                    <p style={{ margin: 0, fontSize: 14 }}>
                      Chất lượng không khí tốt. Có thể hoạt động ngoài trời bình thường.
                    </p>
                  )}
                  {aqiData.aqi > 50 && aqiData.aqi <= 100 && (
                    <p style={{ margin: 0, fontSize: 14 }}>
                      Chất lượng không khí ở mức chấp nhận được. Những người nhạy cảm nên hạn chế hoạt động ngoài trời.
                    </p>
                  )}
                  {aqiData.aqi > 100 && aqiData.aqi <= 150 && (
                    <p style={{ margin: 0, fontSize: 14, color: '#d97706' }}>
                      ⚠️ Chất lượng không khí không tốt cho nhóm nhạy cảm. Nhân viên nên đeo khẩu trang khi làm việc ngoài trời.
                    </p>
                  )}
                  {aqiData.aqi > 150 && (
                    <p style={{ margin: 0, fontSize: 14, color: '#dc2626' }}>
                      🚨 Chất lượng không khí kém. Nhân viên nên đeo khẩu trang và hạn chế thời gian làm việc ngoài trời.
                    </p>
                  )}
                </div>
              </div>
            )}

            {loading && !aqiData && (
              <div className="card" style={{ textAlign: 'center', padding: 48 }}>
                <div style={{ fontSize: 18, color: '#666' }}>⏳ Đang tải dữ liệu...</div>
              </div>
            )}

            {!loading && !aqiData && (
              <div className="card" style={{ textAlign: 'center', padding: 48 }}>
                <div style={{ fontSize: 18, color: '#666' }}>Không có dữ liệu</div>
              </div>
            )}
          </div>
        </main>
      </div>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}


