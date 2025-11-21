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
      setToast({ message: `Re-route created: ${res.data.routeId}`, type: 'success' })
      loadAlerts()
    } else {
      setToast({ message: 'Re-route failed', type: 'error' })
    }
  }

  const columns = [
    { key: 'time', label: 'Time' },
    { key: 'point', label: 'Point' },
    { key: 'vehicle', label: 'Vehicle' },
    { key: 'level', label: 'Level', render: (r) => <span style={{ color: r.level === 'critical' ? '#ef4444' : '#f59e0b' }}>{r.level}</span> },
    { key: 'status', label: 'Status' },
    {
      key: 'action',
      label: 'Action',
      render: (r) =>
        r.status === 'open' ? (
          <button className="btn btn-sm btn-primary" onClick={() => handleReroute(r)} disabled={loading}>
            Re-route
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
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Dynamic Dispatch (CN7)</h1>
            <div className="card">
              <h2>Real-time Alerts</h2>
              <Table columns={columns} data={alerts} emptyText="No alerts" />
            </div>
          </div>
        </main>
      </div>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

