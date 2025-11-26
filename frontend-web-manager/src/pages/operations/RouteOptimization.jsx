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
  const scheduleMarkersRef = useRef([])
  const depotMarkerRef = useRef(null)
  const dumpMarkerRef = useRef(null)
  const routeLinesRef = useRef([])
  const [fleet, setFleet] = useState([])
  const [schedules, setSchedules] = useState([])
  const [depots, setDepots] = useState([])
  const [dumps, setDumps] = useState([])
  const [selectedVehicles, setSelectedVehicles] = useState([])
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0])
  const [selectedDepot, setSelectedDepot] = useState('')
  const [selectedDump, setSelectedDump] = useState('')
  const [routes, setRoutes] = useState([])
  const [optimizationStats, setOptimizationStats] = useState(null)
  const [loading, setLoading] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [toast, setToast] = useState(null)

  // Load depots and dumps only once on mount
  useEffect(() => {
    async function loadMasterData() {
      try {
        const [d, du] = await Promise.all([
          api.getDepots(),
          api.getDumps()
        ])
        
        if (d.ok && Array.isArray(d.data)) {
          setDepots(d.data)
          if (d.data.length > 0) {
            setSelectedDepot(prev => prev || d.data[0].id)
          }
        }
        if (du.ok && Array.isArray(du.data)) {
          setDumps(du.data)
          if (du.data.length > 0) {
            setSelectedDump(prev => prev || du.data[0].id)
          }
        }
      } catch (error) {
        console.error('Error loading master data:', error)
      }
    }
    
    loadMasterData()
    initMap()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []) // Only run once on mount

  // Load fleet and schedules when date changes
  useEffect(() => {
    loadData()
  }, [selectedDate])

  async function loadData() {
    try {
      const [f, s] = await Promise.all([
        api.getFleet(),
        api.getSchedules({ scheduled_date: selectedDate, status: 'scheduled' })
      ])
      
      if (f.ok && Array.isArray(f.data)) setFleet(f.data)
      if (s.ok && Array.isArray(s.data)) {
        const validSchedules = s.data.filter(sch => 
          sch.latitude && sch.longitude && 
          (sch.status === 'scheduled' || sch.status === 'assigned')
        )
        setSchedules(validSchedules)
      }
    } catch (error) {
      console.error('Error loading data:', error)
      setToast({ message: 'Lỗi khi tải dữ liệu', type: 'error' })
    }
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
    
    mapObj.current.on('load', () => {
      updateMapMarkers()
    })
  }

  function updateMapMarkers() {
    if (!mapObj.current || !mapObj.current.loaded()) return

    // Clear existing markers
    scheduleMarkersRef.current.forEach(m => m.remove())
    scheduleMarkersRef.current = []
    if (depotMarkerRef.current) depotMarkerRef.current.remove()
    depotMarkerRef.current = null
    if (dumpMarkerRef.current) dumpMarkerRef.current.remove()
    dumpMarkerRef.current = null

    // Clear route lines
    routeLinesRef.current.forEach(line => {
      if (mapObj.current.getSource(line.sourceId)) {
        mapObj.current.removeLayer(line.layerId)
        mapObj.current.removeSource(line.sourceId)
      }
    })
    routeLinesRef.current = []

    // Add schedule markers
    schedules.forEach((schedule, idx) => {
      if (!schedule.latitude || !schedule.longitude) return
      
      const el = document.createElement('div')
      el.className = 'schedule-marker'
      el.style.cssText = `
        width: 24px;
        height: 24px;
        border-radius: 50%;
        background-color: #2196f3;
        border: 2px solid white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.3);
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 10px;
        font-weight: bold;
        color: white;
      `
      el.textContent = idx + 1
      el.title = schedule.address || `Điểm ${idx + 1}`
      
      const marker = new maplibregl.Marker({ element: el })
        .setLngLat([schedule.longitude, schedule.latitude])
        .addTo(mapObj.current)
      
      scheduleMarkersRef.current.push(marker)
    })

    // Add depot marker
    const selectedDepotData = depots.find(d => d.id === selectedDepot)
    if (selectedDepotData && selectedDepotData.lat && selectedDepotData.lon) {
      const el = document.createElement('div')
      el.className = 'depot-marker'
      el.style.cssText = `
        width: 32px;
        height: 32px;
        border-radius: 4px;
        background-color: #4caf50;
        border: 3px solid white;
        box-shadow: 0 2px 6px rgba(0,0,0,0.4);
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
      `
      el.innerHTML = '🏭'
      el.title = selectedDepotData.name || 'Trạm thu gom'
      
      depotMarkerRef.current = new maplibregl.Marker({ element: el })
        .setLngLat([selectedDepotData.lon, selectedDepotData.lat])
        .addTo(mapObj.current)
    }

    // Add dump marker
    const selectedDumpData = dumps.find(d => d.id === selectedDump)
    if (selectedDumpData && selectedDumpData.lat && selectedDumpData.lon) {
      const el = document.createElement('div')
      el.className = 'dump-marker'
      el.style.cssText = `
        width: 32px;
        height: 32px;
        border-radius: 4px;
        background-color: #f44336;
        border: 3px solid white;
        box-shadow: 0 2px 6px rgba(0,0,0,0.4);
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
      `
      el.innerHTML = '🗑️'
      el.title = selectedDumpData.name || 'Bãi rác'
      
      dumpMarkerRef.current = new maplibregl.Marker({ element: el })
        .setLngLat([selectedDumpData.lon, selectedDumpData.lat])
        .addTo(mapObj.current)
    }

    // Draw route lines
    if (routes.length > 0 && selectedDepotData && selectedDumpData) {
      const colors = ['#2196f3', '#ff9800', '#9c27b0', '#00bcd4', '#4caf50']
      
      routes.forEach((route, routeIdx) => {
        if (!route.stops || route.stops.length === 0) return
        
        const color = colors[routeIdx % colors.length]
        const coordinates = []
        
        // Start from depot
        if (selectedDepotData.lat && selectedDepotData.lon) {
          coordinates.push([selectedDepotData.lon, selectedDepotData.lat])
        }
        
        // Add schedule stops
        route.stops.forEach(stop => {
          const schedule = schedules.find(s => s.id === stop.schedule_id)
          if (schedule && schedule.latitude && schedule.longitude) {
            coordinates.push([schedule.longitude, schedule.latitude])
          }
        })
        
        // End at dump
        if (selectedDumpData.lat && selectedDumpData.lon) {
          coordinates.push([selectedDumpData.lon, selectedDumpData.lat])
        }
        
        if (coordinates.length < 2) return
        
        const sourceId = `route-${routeIdx}`
        const layerId = `route-line-${routeIdx}`
        
        // Add source
        if (mapObj.current.getSource(sourceId)) {
          mapObj.current.removeLayer(layerId)
          mapObj.current.removeSource(sourceId)
        }
        
        mapObj.current.addSource(sourceId, {
          type: 'geojson',
          data: {
            type: 'Feature',
            properties: {},
            geometry: {
              type: 'LineString',
              coordinates: coordinates
            }
          }
        })
        
        // Add layer
        mapObj.current.addLayer({
          id: layerId,
          type: 'line',
          source: sourceId,
          layout: {
            'line-join': 'round',
            'line-cap': 'round'
          },
          paint: {
            'line-color': color,
            'line-width': 4,
            'line-opacity': 0.8
          }
        })
        
        routeLinesRef.current.push({ sourceId, layerId })
      })
      
      // Fit map to show all markers
      const allLngLats = []
      schedules.forEach(s => {
        if (s.latitude && s.longitude) allLngLats.push([s.longitude, s.latitude])
      })
      if (selectedDepotData?.lat && selectedDepotData?.lon) {
        allLngLats.push([selectedDepotData.lon, selectedDepotData.lat])
      }
      if (selectedDumpData?.lat && selectedDumpData?.lon) {
        allLngLats.push([selectedDumpData.lon, selectedDumpData.lat])
      }
      
      if (allLngLats.length > 0) {
        const bounds = new maplibregl.LngLatBounds()
        allLngLats.forEach(coord => bounds.extend(coord))
        
        mapObj.current.fitBounds(bounds, {
          padding: 50,
          maxZoom: 14
        })
      }
    }
  }

  // Update map when schedules, depots, dumps, or routes change
  useEffect(() => {
    if (mapObj.current && mapObj.current.loaded()) {
      updateMapMarkers()
    }
  }, [schedules, selectedDepot, selectedDump, routes, depots, dumps])

  async function handleOptimize() {
    if (selectedVehicles.length === 0) {
      setToast({ message: 'Vui lòng chọn ít nhất một phương tiện', type: 'error' })
      return
    }
    
    if (!selectedDepot || !selectedDump) {
      setToast({ message: 'Vui lòng chọn trạm thu gom và bãi rác', type: 'error' })
      return
    }

    if (schedules.length === 0) {
      setToast({ message: 'Không có lịch thu gom nào cho ngày đã chọn', type: 'error' })
      return
    }

    setLoading(true)
    try {
      const vehicleIds = selectedVehicles
    const payload = {
        scheduled_date: selectedDate,
        depot_id: selectedDepot,
        dump_id: selectedDump,
        vehicles: vehicleIds,
        constraints: {
          max_route_duration_min: 480, // 8 hours
          max_stops_per_route: 20,
          time_window_buffer_min: 30
        }
      }
      
    const res = await api.optimizeVRP(payload)
    setLoading(false)
      
    if (res && res.ok && res.data) {
      const routes = res.data.routes || []
      const stats = res.data.statistics || null
      
      setRoutes(routes)
      setOptimizationStats(stats)
      
      if (routes.length === 0) {
        setToast({ 
          message: 'Không thể tạo tuyến đường. Có thể do không có lịch thu gom phù hợp hoặc ràng buộc không thỏa mãn.', 
          type: 'warning' 
        })
      } else {
        setToast({ 
          message: `Tối ưu thành công: ${routes.length} tuyến đường`, 
          type: 'success' 
        })
      }
    } else {
      console.error('Optimization failed:', res)
      setToast({ message: res?.error || 'Tối ưu thất bại', type: 'error' })
    }
    } catch (error) {
      setLoading(false)
      setToast({ message: 'Lỗi khi tối ưu: ' + error.message, type: 'error' })
    }
  }

  async function handleSaveRoutes() {
    if (routes.length === 0) {
      setToast({ message: 'Không có tuyến đường để lưu', type: 'error' })
      return
    }

    setConfirmOpen(true)
  }

  async function confirmSave() {
    setConfirmOpen(false)
    setLoading(true)
    
    try {
      const payload = {
        routes: routes,
        scheduled_date: selectedDate,
        depot_id: selectedDepot,
        dump_id: selectedDump
      }
      
      const res = await api.saveRoutes(payload)
    setLoading(false)
      
    if (res.ok) {
        setToast({ 
          message: `Đã lưu ${res.data.total_routes || 0} tuyến đường vào hệ thống`, 
          type: 'success' 
        })
        // Reload schedules to see updated status
        await loadData()
    } else {
        setToast({ message: res.error || 'Lưu thất bại', type: 'error' })
      }
    } catch (error) {
      setLoading(false)
      setToast({ message: 'Lỗi khi lưu: ' + error.message, type: 'error' })
    }
  }

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Tối ưu tuyến đường</h1>
            
            {/* Filters */}
            <div className="card" style={{ marginBottom: 24 }}>
              <h2 style={{ fontSize: 18, marginBottom: 12 }}>Bộ lọc</h2>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
                <div>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Ngày thu gom</label>
                  <input
                    type="date"
                    value={selectedDate}
                    onChange={(e) => setSelectedDate(e.target.value)}
                    style={{ width: '100%', padding: '8px', border: '1px solid #ccc', borderRadius: 6 }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Trạm thu gom</label>
                  <select
                    value={selectedDepot}
                    onChange={(e) => setSelectedDepot(e.target.value)}
                    style={{ width: '100%', padding: '8px', border: '1px solid #ccc', borderRadius: 6 }}
                  >
                    <option value="">-- Chọn trạm --</option>
                    {depots.map(d => (
                      <option key={d.id} value={d.id}>{d.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Bãi rác</label>
                  <select
                    value={selectedDump}
                    onChange={(e) => setSelectedDump(e.target.value)}
                    style={{ width: '100%', padding: '8px', border: '1px solid #ccc', borderRadius: 6 }}
                  >
                    <option value="">-- Chọn bãi rác --</option>
                    {dumps.map(d => (
                      <option key={d.id} value={d.id}>{d.name}</option>
                    ))}
                  </select>
                </div>
                <div style={{ display: 'flex', alignItems: 'flex-end' }}>
                  <button 
                    className="btn btn-primary" 
                    onClick={loadData}
                    style={{ width: '100%' }}
                  >
                    Tải lại
                  </button>
                </div>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: 24 }}>
              <div className="card">
                <h2>Bản đồ & Lịch thu gom</h2>
                <div style={{ marginBottom: 12, fontSize: 14, color: '#666' }}>
                  Tìm thấy <strong>{schedules.length}</strong> lịch thu gom cho ngày {new Date(selectedDate).toLocaleDateString('vi-VN')}
                </div>
                <div ref={mapRef} style={{ width: '100%', height: 500, borderRadius: 8, overflow: 'hidden', border: '1px solid #e0e0e0' }} />
                <div style={{ marginTop: 16, display: 'flex', gap: 8 }}>
                  <button 
                    className="btn btn-primary" 
                    onClick={handleOptimize} 
                    disabled={loading || schedules.length === 0}
                  >
                    {loading ? 'Đang tối ưu...' : 'Tối ưu tuyến đường'}
                  </button>
                  {routes.length > 0 && (
                    <button 
                      className="btn btn-primary" 
                      onClick={handleSaveRoutes}
                      disabled={loading}
                    >
                      Lưu tuyến đường
                    </button>
                  )}
                </div>
              </div>
              
              <div>
                <div className="card" style={{ marginBottom: 16 }}>
                <h2>Đội xe</h2>
                  <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 300, overflowY: 'auto' }}>
                    {fleet.length === 0 ? (
                      <div style={{ padding: 16, textAlign: 'center', color: '#999' }}>Chưa có phương tiện</div>
                    ) : (
                      fleet.map(v => (
                        <label 
                          key={v.id} 
                          style={{ 
                            display: 'flex', 
                            alignItems: 'center', 
                            gap: 8, 
                            padding: 8, 
                            border: '1px solid #e0e0e0', 
                            borderRadius: 6, 
                            cursor: 'pointer',
                            backgroundColor: selectedVehicles.includes(v.id) ? '#e3f2fd' : 'white'
                          }}
                        >
                      <input
                        type="checkbox"
                        checked={selectedVehicles.includes(v.id)}
                        onChange={(e) => {
                              if (e.target.checked) {
                                setSelectedVehicles([...selectedVehicles, v.id])
                              } else {
                                setSelectedVehicles(selectedVehicles.filter(id => id !== v.id))
                              }
                            }}
                          />
                          <div style={{ flex: 1 }}>
                            <div style={{ fontWeight: 600 }}>{v.plate || v.id}</div>
                        <div style={{ fontSize: 12, color: '#888' }}>
                              {v.type || 'N/A'} · {v.capacity || v.capacity_kg || 0}kg
                        </div>
                      </div>
                    </label>
                      ))
                    )}
                  </div>
                </div>

                {optimizationStats && (
                  <div className="card">
                    <h2>Thống kê tối ưu</h2>
                    <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#666' }}>Tổng tuyến:</span>
                        <strong>{optimizationStats.total_routes || 0}</strong>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#666' }}>Tổng khoảng cách:</span>
                        <strong>{optimizationStats.total_distance_km?.toFixed(2) || '0.00'} km</strong>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#666' }}>Tổng thời gian:</span>
                        <strong>
                          {optimizationStats.total_duration_min 
                            ? `${Math.round(optimizationStats.total_duration_min / 60)}h ${optimizationStats.total_duration_min % 60}m`
                            : '0h 0m'}
                        </strong>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#666' }}>Tỷ lệ sử dụng:</span>
                        <strong>{((optimizationStats.utilization_rate || 0) * 100).toFixed(1)}%</strong>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#666' }}>Điểm tối ưu:</span>
                        <strong>{((optimizationStats.optimization_score || 0.3) * 100).toFixed(0)}/100</strong>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {routes.length > 0 && (
              <div className="card" style={{ marginTop: 24 }}>
                <h2>Tuyến đường đã tối ưu ({routes.length})</h2>
                <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
                  {routes.map((r, i) => (
                    <div key={i} style={{ padding: 16, border: '1px solid #e0e0e0', borderRadius: 6 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: 8 }}>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: 16 }}>Tuyến {i + 1}</div>
                      <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>
                            Phương tiện: {r.vehicle_id}
                          </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontWeight: 600, color: '#2196f3' }}>
                            {r.total_distance_km} km
                          </div>
                          <div style={{ fontSize: 12, color: '#888' }}>
                            {Math.round(r.total_duration_min / 60)}h {r.total_duration_min % 60}m
                          </div>
                        </div>
                      </div>
                      <div style={{ fontSize: 14, color: '#666', marginTop: 8 }}>
                        Điểm dừng: <strong>{r.stops?.length || 0}</strong> · 
                        Điểm tối ưu: <strong>{(r.optimization_score * 100).toFixed(0)}</strong>
                      </div>
                      {r.stops && r.stops.length > 0 && (
                        <div style={{ marginTop: 12, padding: 12, backgroundColor: '#f5f5f5', borderRadius: 6, fontSize: 12 }}>
                          <div style={{ fontWeight: 600, marginBottom: 8 }}>Thứ tự thu gom:</div>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                            {r.stops.slice(0, 5).map((stop, idx) => (
                              <div key={idx}>
                                {stop.seq}. Điểm {stop.schedule_id?.substring(0, 8)} - {stop.estimated_arrival}
                              </div>
                            ))}
                            {r.stops.length > 5 && (
                              <div style={{ color: '#999', fontStyle: 'italic' }}>
                                ... và {r.stops.length - 5} điểm khác
                              </div>
                            )}
                          </div>
                        </div>
                      )}
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
        title="Xác nhận lưu tuyến đường"
        message={`Bạn có chắc muốn lưu ${routes.length} tuyến đường đã tối ưu vào hệ thống? Các lịch thu gom sẽ được gán vào tuyến đường.`}
        onConfirm={confirmSave}
        onCancel={() => setConfirmOpen(false)}
      />
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}
