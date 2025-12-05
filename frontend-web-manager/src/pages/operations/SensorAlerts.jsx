/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Smart Container Sensors - Alerts Page
 * Displays containers that need collection (fill level > threshold)
 */

import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import api from '../../lib/api.js'
import Toast from '../../components/common/Toast.jsx'

export default function SensorAlerts() {
  const [containers, setContainers] = useState([])
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)
  const [threshold, setThreshold] = useState(80)
  const [selectedContainer, setSelectedContainer] = useState(null)
  const [sensorData, setSensorData] = useState(null)
  const [observations, setObservations] = useState([])

  useEffect(() => {
    loadAlerts()
  }, [threshold])

  async function loadAlerts() {
    setLoading(true)
    try {
      const res = await api.getSensorAlerts(threshold)
      if (res.ok) {
        setContainers(res.data || [])
        if (res.data.length === 0) {
          setToast({ message: `Không có container nào có mức đầy > ${threshold}%`, type: 'info' })
        }
      } else {
        setToast({ message: res.error || 'Không thể tải dữ liệu', type: 'error' })
      }
    } catch (error) {
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
    } finally {
      setLoading(false)
    }
  }

  async function loadContainerDetails(containerId) {
    setSelectedContainer(containerId)
    setSensorData(null)
    setObservations([])
    
    try {
      // Get container level
      const levelRes = await api.getContainerLevel(containerId)
      if (levelRes.ok) {
        setSensorData(levelRes.data)
      }

      // Get sensors for container
      const sensorsRes = await api.getContainerSensors(containerId)
      if (sensorsRes.ok && sensorsRes.data.length > 0) {
        // Get observations for first sensor
        const sensorId = sensorsRes.data[0].id
        const obsRes = await api.getSensorObservations(sensorId, 50)
        if (obsRes.ok) {
          setObservations(obsRes.data || [])
        }
      }
    } catch (error) {
      setToast({ message: 'Lỗi tải chi tiết: ' + error.message, type: 'error' })
    }
  }

  function getFillLevelColor(level) {
    if (level < 50) return '#10b981' // green
    if (level < 80) return '#f59e0b' // yellow
    return '#ef4444' // red
  }

  function formatDate(dateString) {
    if (!dateString) return 'N/A'
    return new Date(dateString).toLocaleString('vi-VN')
  }

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>
              Cảnh báo thùng rác thông minh
            </h1>

            {/* Filters */}
            <div className="card" style={{ marginBottom: 16 }}>
              <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}>
                <div style={{ flex: '1 1 200px' }}>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                    Ngưỡng cảnh báo (%)
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={threshold}
                    onChange={(e) => setThreshold(parseInt(e.target.value) || 80)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                  />
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
                  <button
                    className="btn btn-primary"
                    onClick={loadAlerts}
                    disabled={loading}
                    style={{ padding: '8px 16px' }}
                  >
                    {loading ? '⏳ Đang tải...' : '🔄 Làm mới'}
                  </button>
                </div>
              </div>
              <div style={{ marginTop: 8, fontSize: 14, color: '#666' }}>
                Hiển thị containers có mức đầy &gt; {threshold}%
              </div>
            </div>

            {/* Containers List */}
            <div className="card" style={{ marginBottom: 16 }}>
              <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
                🚨 Danh sách containers cần thu gom ({containers.length})
              </h2>

              {loading && (
                <div style={{ textAlign: 'center', padding: 48 }}>
                  <div style={{ fontSize: 18, color: '#666' }}>⏳ Đang tải...</div>
                </div>
              )}

              {!loading && containers.length === 0 && (
                <div style={{ textAlign: 'center', padding: 48 }}>
                  <div style={{ fontSize: 18, color: '#666' }}>✅ Không có container nào cần thu gom</div>
                </div>
              )}

              {!loading && containers.length > 0 && (
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ backgroundColor: '#f9fafb', borderBottom: '2px solid #e5e7eb' }}>
                        <th style={{ padding: '12px', textAlign: 'left', fontSize: 14, fontWeight: 600 }}>Container ID</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontSize: 14, fontWeight: 600 }}>Mức đầy</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontSize: 14, fontWeight: 600 }}>Vị trí</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontSize: 14, fontWeight: 600 }}>Thời gian</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontSize: 14, fontWeight: 600 }}>Thao tác</th>
                      </tr>
                    </thead>
                    <tbody>
                      {containers.map((container, idx) => (
                        <tr
                          key={idx}
                          style={{
                            borderBottom: '1px solid #e5e7eb',
                            cursor: 'pointer',
                            backgroundColor: selectedContainer === container.containerId ? '#f0f9ff' : 'white'
                          }}
                          onClick={() => loadContainerDetails(container.containerId)}
                        >
                          <td style={{ padding: '12px', fontSize: 14 }}>
                            {container.name || container.containerId.substring(0, 8)}
                          </td>
                          <td style={{ padding: '12px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                              <div
                                style={{
                                  width: 60,
                                  height: 8,
                                  backgroundColor: '#e5e7eb',
                                  borderRadius: 4,
                                  overflow: 'hidden'
                                }}
                              >
                                <div
                                  style={{
                                    width: `${Math.min(container.fillLevel, 100)}%`,
                                    height: '100%',
                                    backgroundColor: getFillLevelColor(container.fillLevel)
                                  }}
                                />
                              </div>
                              <span
                                style={{
                                  fontSize: 14,
                                  fontWeight: 600,
                                  color: getFillLevelColor(container.fillLevel)
                                }}
                              >
                                {container.fillLevel.toFixed(1)}%
                              </span>
                            </div>
                          </td>
                          <td style={{ padding: '12px', fontSize: 14 }}>
                            {container.lat && container.lon
                              ? `${container.lat.toFixed(4)}, ${container.lon.toFixed(4)}`
                              : 'N/A'}
                          </td>
                          <td style={{ padding: '12px', fontSize: 14 }}>
                            {formatDate(container.timestamp)}
                          </td>
                          <td style={{ padding: '12px' }}>
                            <button
                              className="btn btn-secondary"
                              onClick={(e) => {
                                e.stopPropagation()
                                loadContainerDetails(container.containerId)
                              }}
                              style={{ padding: '4px 12px', fontSize: 12 }}
                            >
                              Chi tiết
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* Container Details */}
            {selectedContainer && (
              <div className="card">
                <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
                  📊 Chi tiết Container: {selectedContainer.substring(0, 8)}
                </h2>

                {sensorData && (
                  <div style={{ marginBottom: 24 }}>
                    <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 12 }}>Mức đầy hiện tại</h3>
                    <div
                      style={{
                        padding: 24,
                        borderRadius: 12,
                        backgroundColor: getFillLevelColor(sensorData.fillLevel),
                        color: 'white',
                        textAlign: 'center'
                      }}
                    >
                      <div style={{ fontSize: 48, fontWeight: 700, marginBottom: 8 }}>
                        {sensorData.fillLevel.toFixed(1)}%
                      </div>
                      <div style={{ fontSize: 14, opacity: 0.9 }}>
                        Cập nhật: {formatDate(sensorData.timestamp)}
                      </div>
                    </div>
                  </div>
                )}

                {observations.length > 0 && (
                  <div>
                    <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 12 }}>
                      Lịch sử quan sát (50 gần nhất)
                    </h3>
                    <div style={{ overflowX: 'auto' }}>
                      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                          <tr style={{ backgroundColor: '#f9fafb' }}>
                            <th style={{ padding: '8px', textAlign: 'left', fontSize: 12 }}>Thời gian</th>
                            <th style={{ padding: '8px', textAlign: 'left', fontSize: 12 }}>Giá trị</th>
                            <th style={{ padding: '8px', textAlign: 'left', fontSize: 12 }}>Đơn vị</th>
                          </tr>
                        </thead>
                        <tbody>
                          {observations.map((obs, idx) => (
                            <tr key={idx} style={{ borderBottom: '1px solid #e5e7eb' }}>
                              <td style={{ padding: '8px', fontSize: 12 }}>{formatDate(obs.resultTime)}</td>
                              <td style={{ padding: '8px', fontSize: 12, fontWeight: 600 }}>
                                {obs.resultValue.toFixed(2)}
                              </td>
                              <td style={{ padding: '8px', fontSize: 12 }}>{obs.unit}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </main>
      </div>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}


