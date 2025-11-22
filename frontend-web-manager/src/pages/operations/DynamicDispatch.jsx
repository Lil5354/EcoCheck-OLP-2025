import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import api from '../../lib/api.js'
import Toast from '../../components/common/Toast.jsx'

export default function DynamicDispatch() {
  const [alerts, setAlerts] = useState([])
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadAlerts()
    const id = setInterval(loadAlerts, 5000)
    return () => clearInterval(id)
  }, [])

  async function loadAlerts() {
    const res = await api.getAlerts()
    if (res.ok) setAlerts(res.data)
  }

  async function handleReroute(alert) {
    setLoading(true)
    const res = await api.reroute({ alertId: alert.id, vehicleId: alert.vehicle })
    setLoading(false)
    if (res.ok) {
      setToast({ message: `Đã tạo tuyến mới: ${res.data.routeId}`, type: 'success' })
      loadAlerts()
    } else {
      setToast({ message: 'Tạo tuyến mới thất bại', type: 'error' })
    }
  }

  const columns = [
    { key: 'time', label: 'Thời gian' },
    { key: 'point', label: 'Điểm' },
    { key: 'vehicle', label: 'Phương tiện' },
    { key: 'level', label: 'Mức độ', render: (r) => <span style={{ color: r.level === 'critical' ? '#ef4444' : '#f59e0b' }}>{r.level === 'critical' ? 'Nghiêm trọng' : 'Cảnh báo'}</span> },
    { key: 'status', label: 'Trạng thái' },
    {
      key: 'action',
      label: 'Hành động',
      render: (r) =>
        r.status === 'open' ? (
          <button className="btn btn-sm btn-primary" onClick={() => handleReroute(r)} disabled={loading}>
            Tạo tuyến mới
          </button>
        ) : null
    }
  ]

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Điều phối động (CN7)</h1>
            <div className="card">
              <h2>Cảnh báo thời gian thực</h2>
              <Table columns={columns} data={alerts} emptyText="Không có cảnh báo" />
            </div>
          </div>
        </main>
      </div>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

