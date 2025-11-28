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
  const [schedules, setSchedules] = useState([])
  const [depots, setDepots] = useState([])
  const [dumps, setDumps] = useState([])
  const [selectedVehicles, setSelectedVehicles] = useState([])
  const [routes, setRoutes] = useState([])
  const [loading, setLoading] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [toast, setToast] = useState(null)
  const [activeRouteId, setActiveRouteId] = useState(null)
  const routeSourceRef = useRef(null)
  const routeLayerRef = useRef(null)
  const stopMarkersRef = useRef([])
  
  // Filters
  const [collectionDate, setCollectionDate] = useState(new Date().toISOString().split('T')[0])
  const [selectedDepot, setSelectedDepot] = useState('')
  const [selectedDump, setSelectedDump] = useState('')

  useEffect(() => {
    loadData()
    initMap()
    return () => {
      // Cleanup on unmount
      clearRouteDisplay()
    }
  }, [collectionDate, selectedDepot, selectedDump])
  
  // Clear route display when routes change (new optimization)
  useEffect(() => {
    if (routes.length > 0 && activeRouteId) {
      // If routes changed, clear active display
      const currentRoute = routes.find(r => r.vehicleId === activeRouteId)
      if (!currentRoute) {
        clearRouteDisplay()
      }
    }
  }, [routes])

  async function loadData() {
    const [f, s, dep, dum] = await Promise.all([
      api.getFleet(),
      api.getSchedules({ scheduled_date: collectionDate, status: 'scheduled' }),
      api.getDepots(),
      api.getDumps()
    ])
    if (f.ok && Array.isArray(f.data)) setFleet(f.data)
    if (s.ok && Array.isArray(s.data)) setSchedules(s.data)
    if (dep.ok && Array.isArray(dep.data)) setDepots(dep.data)
    if (dum.ok && Array.isArray(dum.data)) setDumps(dum.data)
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
    
    // Wait for map to load before adding route sources
    const setupRouteLayer = () => {
      if (!mapObj.current || !mapObj.current.loaded()) return
      
      // Add route source
      if (!mapObj.current.getSource('route')) {
        mapObj.current.addSource('route', {
          type: 'geojson',
          data: {
            type: 'FeatureCollection',
            features: []
          }
        })
        routeSourceRef.current = mapObj.current.getSource('route')
      }
      
      // Add route layer
      if (!mapObj.current.getLayer('route-line')) {
        mapObj.current.addLayer({
          id: 'route-line',
          type: 'line',
          source: 'route',
          layout: {
            'line-join': 'round',
            'line-cap': 'round'
          },
          paint: {
            'line-color': '#3b82f6',
            'line-width': 4,
            'line-opacity': 0.8
          }
        })
        routeLayerRef.current = 'route-line'
      }
    }
    
    if (mapObj.current.loaded()) {
      setupRouteLayer()
    } else {
      mapObj.current.on('load', setupRouteLayer)
    }
  }
  
  function clearRouteDisplay() {
    // Clear route line
    if (mapObj.current) {
      const source = routeSourceRef.current || mapObj.current.getSource('route')
      if (source) {
        source.setData({
          type: 'FeatureCollection',
          features: []
        })
      }
    }
    
    // Clear stop markers
    if (stopMarkersRef.current && stopMarkersRef.current.length > 0) {
      stopMarkersRef.current.forEach(marker => {
        if (marker && marker.remove) marker.remove()
      })
      stopMarkersRef.current = []
    }
    
    setActiveRouteId(null)
  }
  
  function displayRouteOnMap(route) {
    if (!mapObj.current || !mapObj.current.loaded()) {
      console.warn('Map not ready')
      return
    }
    
    // Ensure route source and layer exist
    if (!mapObj.current.getSource('route')) {
      mapObj.current.addSource('route', {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: []
        }
      })
      routeSourceRef.current = mapObj.current.getSource('route')
    }
    
    if (!mapObj.current.getLayer('route-line')) {
      mapObj.current.addLayer({
        id: 'route-line',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#3b82f6',
          'line-width': 4,
          'line-opacity': 0.8
        }
      })
      routeLayerRef.current = 'route-line'
    }
    
    // Clear previous route
    clearRouteDisplay()
    
    // Set active route
    setActiveRouteId(route.vehicleId)
    
    // Display route path from geojson
    if (route.geojson && route.geojson.features && route.geojson.features.length > 0) {
      const source = routeSourceRef.current || mapObj.current.getSource('route')
      if (source) {
        source.setData(route.geojson)
      }
      
      // Fit map to route bounds
      const coordinates = route.geojson.features[0]?.geometry?.coordinates || []
      if (coordinates.length > 0) {
        const bounds = new maplibregl.LngLatBounds()
        coordinates.forEach(coord => {
          bounds.extend(coord)
        })
        
        mapObj.current.fitBounds(bounds, {
          padding: { top: 50, bottom: 50, left: 50, right: 50 },
          maxZoom: 15
        })
      }
    }
    
    // Add marker for depot (start point)
    if (route.depot && route.depot.lon && route.depot.lat) {
      const depotEl = document.createElement('div')
      depotEl.className = 'route-depot-marker'
      depotEl.style.width = '32px'
      depotEl.style.height = '32px'
      depotEl.style.borderRadius = '50%'
      depotEl.style.backgroundColor = '#10b981'
      depotEl.style.border = '3px solid white'
      depotEl.style.boxShadow = '0 2px 8px rgba(0,0,0,0.4)'
      depotEl.style.display = 'flex'
      depotEl.style.alignItems = 'center'
      depotEl.style.justifyContent = 'center'
      depotEl.style.color = 'white'
      depotEl.style.fontSize = '12px'
      depotEl.style.fontWeight = 'bold'
      depotEl.textContent = 'S'
      depotEl.title = 'Điểm bắt đầu (Depot)'
      
      const depotMarker = new maplibregl.Marker(depotEl)
        .setLngLat([route.depot.lon, route.depot.lat])
        .addTo(mapObj.current)
      
      stopMarkersRef.current.push(depotMarker)
    }
    
    // Add markers for stops (numbered)
    if (route.stops && Array.isArray(route.stops)) {
      route.stops.forEach((stop, idx) => {
        if (stop.lon && stop.lat) {
          const el = document.createElement('div')
          el.className = 'route-stop-marker'
          el.style.width = '28px'
          el.style.height = '28px'
          el.style.borderRadius = '50%'
          el.style.backgroundColor = '#3b82f6'
          el.style.border = '2px solid white'
          el.style.boxShadow = '0 2px 6px rgba(0,0,0,0.3)'
          el.style.display = 'flex'
          el.style.alignItems = 'center'
          el.style.justifyContent = 'center'
          el.style.color = 'white'
          el.style.fontSize = '11px'
          el.style.fontWeight = 'bold'
          el.textContent = idx + 1
          el.title = `Điểm dừng ${idx + 1}`
          
          const marker = new maplibregl.Marker(el)
            .setLngLat([stop.lon, stop.lat])
            .addTo(mapObj.current)
          
          stopMarkersRef.current.push(marker)
        }
      })
    }
    
    // Add marker for dump (end point)
    if (route.dump && route.dump.lon && route.dump.lat) {
      const dumpEl = document.createElement('div')
      dumpEl.className = 'route-dump-marker'
      dumpEl.style.width = '32px'
      dumpEl.style.height = '32px'
      dumpEl.style.borderRadius = '50%'
      dumpEl.style.backgroundColor = '#ef4444'
      dumpEl.style.border = '3px solid white'
      dumpEl.style.boxShadow = '0 2px 8px rgba(0,0,0,0.4)'
      dumpEl.style.display = 'flex'
      dumpEl.style.alignItems = 'center'
      dumpEl.style.justifyContent = 'center'
      dumpEl.style.color = 'white'
      dumpEl.style.fontSize = '12px'
      dumpEl.style.fontWeight = 'bold'
      dumpEl.textContent = 'E'
      dumpEl.title = 'Điểm kết thúc (Dump)'
      
      const dumpMarker = new maplibregl.Marker(dumpEl)
        .setLngLat([route.dump.lon, route.dump.lat])
        .addTo(mapObj.current)
      
      stopMarkersRef.current.push(dumpMarker)
    }
  }
  
  function handleRouteDoubleClick(route) {
    displayRouteOnMap(route)
  }

  async function handleOptimize() {
    if (selectedVehicles.length === 0) {
      setToast({ message: 'Vui lòng chọn ít nhất một phương tiện', type: 'error' })
      return
    }
    if (schedules.length === 0) {
      setToast({ message: 'Không có lịch thu gom để tối ưu', type: 'error' })
      return
    }
    setLoading(true)
    // Clear previous route display when optimizing new routes
    clearRouteDisplay()
    
    const vehicles = fleet.filter(v => selectedVehicles.includes(v.id))
    const depot = depots.find(d => d.id === selectedDepot) || depots[0]
    const dump = dumps.find(d => d.id === selectedDump) || dumps[0]
    
    // Convert schedules to points format
    const points = schedules.map(s => ({
      id: s.schedule_id || s.id,
      lat: s.latitude || s.lat,
      lon: s.longitude || s.lon,
      demand: s.estimated_weight || 0,
      type: s.waste_type || 'household'
    }))
    
    const payload = {
      timeWindow: { start: '19:00', end: '05:00' },
      vehicles,
      depot: depot ? { lon: depot.lon, lat: depot.lat } : { lon: 106.7, lat: 10.78 },
      dump: dump ? { lon: dump.lon, lat: dump.lat } : { lon: 106.72, lat: 10.81 },
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
            
            {/* Filters */}
            <div className="card" style={{ marginBottom: 16 }}>
              <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}>
                <div style={{ flex: '1 1 200px' }}>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Ngày thu gom</label>
                  <input
                    type="date"
                    value={collectionDate}
                    onChange={(e) => setCollectionDate(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                  />
                </div>
                <div style={{ flex: '1 1 200px' }}>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Trạm thu gom</label>
                  <select
                    value={selectedDepot}
                    onChange={(e) => setSelectedDepot(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                  >
                    <option value="">-- Chọn trạm --</option>
                    {depots.map(d => (
                      <option key={d.id} value={d.id}>{d.name}</option>
                    ))}
                  </select>
                </div>
                <div style={{ flex: '1 1 200px' }}>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Bãi rác</label>
                  <select
                    value={selectedDump}
                    onChange={(e) => setSelectedDump(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                  >
                    <option value="">-- Chọn bãi rác --</option>
                    {dumps.map(d => (
                      <option key={d.id} value={d.id}>{d.name}</option>
                    ))}
                  </select>
                </div>
                <div style={{ flex: '0 0 auto', alignSelf: 'flex-end' }}>
                  <button className="btn btn-primary" onClick={loadData} style={{ marginTop: 24 }}>
                    Tải lại
                  </button>
                </div>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 300px', gap: 24 }}>
              <div className="card">
                <h2>Bản đồ & Lịch thu gom</h2>
                <div style={{ marginBottom: 12, color: '#666', fontSize: 14 }}>
                  Tìm thấy {schedules.length} lịch thu gom cho ngày {new Date(collectionDate).toLocaleDateString('vi-VN')}
                </div>
                <div ref={mapRef} style={{ width: '100%', height: 500, borderRadius: 8, overflow: 'hidden', border: '1px solid #e0e0e0' }} />
                <div style={{ marginTop: 16, display: 'flex', justifyContent: 'center' }}>
                  <button className="btn btn-primary" onClick={handleOptimize} disabled={loading}>
                    {loading ? 'Đang tối ưu...' : 'Tối ưu tuyến đường'}
                  </button>
                </div>
              </div>
              <div className="card">
                <h2>Đội xe</h2>
                <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 500, overflowY: 'auto' }}>
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
                      <div style={{ flex: 1 }}>
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
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                  <h2 style={{ margin: 0 }}>Tuyến đường đã tối ưu</h2>
                  {activeRouteId && (
                    <button 
                      className="btn btn-secondary" 
                      onClick={clearRouteDisplay}
                      style={{ fontSize: 12, padding: '4px 12px' }}
                    >
                      Xóa đường đi
                    </button>
                  )}
                </div>
                <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
                  {routes.map((r, i) => (
                    <div 
                      key={i} 
                      onDoubleClick={() => handleRouteDoubleClick(r)}
                      style={{ 
                        padding: 12, 
                        border: `2px solid ${activeRouteId === r.vehicleId ? '#3b82f6' : '#e0e0e0'}`, 
                        borderRadius: 6,
                        cursor: 'pointer',
                        backgroundColor: activeRouteId === r.vehicleId ? '#eff6ff' : 'white',
                        transition: 'all 0.2s'
                      }}
                      title="Nhấn đúp để xem đường đi trên bản đồ"
                    >
                      <div style={{ fontWeight: 600, color: activeRouteId === r.vehicleId ? '#3b82f6' : 'inherit' }}>
                        Phương tiện: {r.vehicleId}
                      </div>
                      <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>
                        Khoảng cách: {r.distance}m · Thời gian dự kiến: {r.eta} · Điểm dừng: {r.stops?.length || 0}
                      </div>
                      {activeRouteId === r.vehicleId && (
                        <div style={{ fontSize: 11, color: '#3b82f6', marginTop: 4, fontStyle: 'italic' }}>
                          ✓ Đang hiển thị trên bản đồ
                        </div>
                      )}
                    </div>
                  ))}
                </div>
                {activeRouteId && (
                  <div style={{ marginTop: 12, padding: 8, backgroundColor: '#f0f9ff', borderRadius: 6, fontSize: 12, color: '#666' }}>
                    💡 Nhấn đúp vào phương tiện khác để xem tuyến đường của phương tiện đó
                  </div>
                )}
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

