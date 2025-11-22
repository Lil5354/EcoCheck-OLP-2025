import React, { useState, useEffect, useRef } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import api from '../../lib/api.js'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import Toast from '../../components/common/Toast.jsx'

export default function RouteOptimization() {
  const mapRef = useRef(null)
  const mapObj = useRef(null)
  const [fleet, setFleet] = useState([])
  const [points, setPoints] = useState([])
  const [selectedVehicles, setSelectedVehicles] = useState([])
  const [routes, setRoutes] = useState([])
  const [loading, setLoading] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadData()
    initMap()
  }, [])

  async function loadData() {
    const [f, p] = await Promise.all([api.getFleet(), api.getPoints()])
    if (f.ok && Array.isArray(f.data)) setFleet(f.data)
    if (p.ok && Array.isArray(p.data)) setPoints(p.data.filter(pt => pt.status !== 'grey'))
  }

  function initMap() {
    if (mapObj.current) return
    mapObj.current = new maplibregl.Map({
      container: mapRef.current,
      style: {
        version: 8,
        sources: {
          osm: {
            type: 'raster',
            tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
            tileSize: 256,
            maxzoom: 19
          }
        },
        layers: [
          { id: 'background', type: 'background', paint: { 'background-color': '#eef2f7' } },
          { id: 'osm', type: 'raster', source: 'osm', minzoom: 0, maxzoom: 22 }
        ]
      },
      center: [106.7, 10.78],
      zoom: 11,
      attributionControl: false
    })
  }

  async function handleOptimize() {
    if (selectedVehicles.length === 0) {
      setToast({ message: 'Vui lòng chọn ít nhất một phương tiện', type: 'error' })
      return
    }
    setLoading(true)
    const vehicles = fleet.filter(v => selectedVehicles.includes(v.id))
    const payload = {
      timeWindow: { start: '19:00', end: '05:00' },
      vehicles,
      depot: { lon: 106.7, lat: 10.78 },
      dump: { lon: 106.72, lat: 10.81 },
      points
    }
    const res = await api.optimizeVRP(payload)
    setLoading(false)
    if (res.ok) {
      setRoutes(res.data.routes || [])
      setToast({ message: 'Tối ưu tuyến đường thành công', type: 'success' })
    } else {
      setToast({ message: 'Tối ưu thất bại', type: 'error' })
    }
  }

  function handleSend() {
    setConfirmOpen(true)
  }

  async function confirmSend() {
    setConfirmOpen(false)
    setLoading(true)
    const res = await api.sendRoutes({ routes })
    setLoading(false)
    if (res.ok) {
      setToast({ message: 'Đã gửi tuyến đường cho tài xế', type: 'success' })
    } else {
      setToast({ message: 'Gửi thất bại', type: 'error' })
    }
  }

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Tối ưu tuyến đường (CN6)</h1>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 300px', gap: 24 }}>
              <div className="card">
                <h2>Bản đồ & Điểm thu gom</h2>
                <div ref={mapRef} style={{ width: '100%', height: 500, borderRadius: 8, overflow: 'hidden', border: '1px solid #e0e0e0' }} />
                <div style={{ marginTop: 16, display: 'flex', gap: 8 }}>
                  <button className="btn btn-primary" onClick={handleOptimize} disabled={loading}>
                    {loading ? 'Đang tối ưu...' : 'Tối ưu tuyến đường'}
                  </button>
                  {routes.length > 0 && (
                    <button className="btn btn-primary" onClick={handleSend}>
                      Gửi tuyến đường
                    </button>
                  )}
                </div>
              </div>
              <div className="card">
                <h2>Đội xe</h2>
                <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
                  {fleet.map(v => (
                    <label key={v.id} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: 8, border: '1px solid #e0e0e0', borderRadius: 6, cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={selectedVehicles.includes(v.id)}
                        onChange={(e) => {
                          if (e.target.checked) setSelectedVehicles([...selectedVehicles, v.id])
                          else setSelectedVehicles(selectedVehicles.filter(id => id !== v.id))
                        }}
                      />
                      <div>
                        <div style={{ fontWeight: 600 }}>{v.plate}</div>
                        <div style={{ fontSize: 12, color: '#888' }}>
                          {v.type} · {v.capacity}kg
                        </div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>
            {routes.length > 0 && (
              <div className="card" style={{ marginTop: 24 }}>
                <h2>Tuyến đường đã tối ưu</h2>
                <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
                  {routes.map((r, i) => (
                    <div key={i} style={{ padding: 12, border: '1px solid #e0e0e0', borderRadius: 6 }}>
                      <div style={{ fontWeight: 600 }}>Phương tiện: {r.vehicleId}</div>
                      <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>
                        Khoảng cách: {r.distance}m · Thời gian dự kiến: {r.eta} · Điểm dừng: {r.stops.length}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </main>
      </div>
      <ConfirmDialog
        open={confirmOpen}
        title="Xác nhận điều phối"
        message="Gửi tuyến đường đã tối ưu cho tài xế?"
        onConfirm={confirmSend}
        onCancel={() => setConfirmOpen(false)}
      />
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

