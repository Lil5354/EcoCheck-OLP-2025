/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * POI (Points of Interest) Search Page
 * Find nearby POIs using OpenStreetMap data
 */

import React, { useState, useEffect, useRef } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import api from '../../lib/api.js'
import Toast from '../../components/common/Toast.jsx'

export default function POI() {
  const mapRef = useRef(null)
  const mapObj = useRef(null)
  const markersRef = useRef([])
  
  const [pois, setPois] = useState([])
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)
  const [location, setLocation] = useState({ lat: 10.78, lon: 106.70 }) // HCMC default
  const [customLocation, setCustomLocation] = useState({ lat: '', lon: '' })
  const [poiType, setPoiType] = useState('gas_station')
  const [radius, setRadius] = useState(500)
  const [selectedPoi, setSelectedPoi] = useState(null)

  // POI types available
  const poiTypes = [
    { value: 'gas_station', label: '⛽ Trạm xăng', icon: '⛽' },
    { value: 'restaurant', label: '🍽️ Nhà hàng', icon: '🍽️' },
    { value: 'parking', label: '🅿️ Bãi đỗ xe', icon: '🅿️' },
    { value: 'hospital', label: '🏥 Bệnh viện', icon: '🏥' },
    { value: 'school', label: '🏫 Trường học', icon: '🏫' },
    { value: 'pharmacy', label: '💊 Nhà thuốc', icon: '💊' },
    { value: 'bank', label: '🏦 Ngân hàng', icon: '🏦' },
    { value: 'atm', label: '🏧 ATM', icon: '🏧' },
    { value: 'cafe', label: '☕ Quán cà phê', icon: '☕' },
    { value: 'fuel', label: '⛽ Trạm nhiên liệu', icon: '⛽' },
  ]

  useEffect(() => {
    initMap()
    return () => {
      // Cleanup markers on unmount
      clearMarkers()
    }
  }, [])

  useEffect(() => {
    if (mapObj.current) {
      loadPOIs()
    }
  }, [location, poiType, radius])

  function initMap() {
    if (mapRef.current && !mapObj.current) {
      mapObj.current = new maplibregl.Map({
        container: mapRef.current,
        style: {
          version: 8,
          sources: {
            'osm-tiles': {
              type: 'raster',
              tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
              tileSize: 256,
              attribution: '© OpenStreetMap contributors'
            }
          },
          layers: [
            {
              id: 'osm-layer',
              type: 'raster',
              source: 'osm-tiles'
            }
          ]
        },
        center: [location.lon, location.lat],
        zoom: 13
      })

      // Add click handler to map
      mapObj.current.on('click', (e) => {
        const { lng, lat } = e.lngLat
        setLocation({ lat, lon: lng })
        setCustomLocation({ lat: lat.toFixed(6), lon: lng.toFixed(6) })
      })

      // Add marker for search location
      new maplibregl.Marker({ color: '#3b82f6' })
        .setLngLat([location.lon, location.lat])
        .setPopup(new maplibregl.Popup().setHTML('<div><strong>Vị trí tìm kiếm</strong></div>'))
        .addTo(mapObj.current)
    }
  }

  async function loadPOIs() {
    setLoading(true)
    try {
      const res = await api.getNearbyPOI(location.lat, location.lon, radius, poiType)
      if (res.ok) {
        setPois(res.data || [])
        displayPOIsOnMap(res.data || [])
      } else {
        setToast({ message: res.error || 'Không thể tải dữ liệu POI', type: 'error' })
        setPois([])
        clearMarkers()
      }
    } catch (error) {
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
      setPois([])
      clearMarkers()
    } finally {
      setLoading(false)
    }
  }

  function displayPOIsOnMap(poisData) {
    clearMarkers()

    if (!mapObj.current) return

    poisData.forEach((poi, index) => {
      const el = document.createElement('div')
      el.className = 'poi-marker'
      el.style.width = '30px'
      el.style.height = '30px'
      el.style.borderRadius = '50%'
      el.style.backgroundColor = '#ef4444'
      el.style.border = '2px solid white'
      el.style.cursor = 'pointer'
      el.style.display = 'flex'
      el.style.alignItems = 'center'
      el.style.justifyContent = 'center'
      el.style.fontSize = '14px'
      el.innerHTML = getPoiIcon(poi.type)

      const marker = new maplibregl.Marker(el)
        .setLngLat([poi.lon, poi.lat])
        .setPopup(
          new maplibregl.Popup({ offset: 25 })
            .setHTML(`
              <div style="padding: 8px;">
                <strong>${poi.name}</strong><br/>
                <small>${poi.type}</small><br/>
                <small>Khoảng cách: ${poi.distance}m</small>
              </div>
            `)
        )
        .addTo(mapObj.current)

      markersRef.current.push(marker)

      // Center map on first POI if any
      if (index === 0 && poisData.length > 0) {
        mapObj.current.flyTo({
          center: [poi.lon, poi.lat],
          zoom: 14
        })
      }
    })
  }

  function getPoiIcon(type) {
    const typeMap = poiTypes.find(t => t.value === type)
    return typeMap ? typeMap.icon : '📍'
  }

  function clearMarkers() {
    markersRef.current.forEach(marker => marker.remove())
    markersRef.current = []
  }

  function handleCustomLocation() {
    const lat = parseFloat(customLocation.lat)
    const lon = parseFloat(customLocation.lon)
    if (!isNaN(lat) && !isNaN(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      setLocation({ lat, lon })
      if (mapObj.current) {
        mapObj.current.flyTo({
          center: [lon, lat],
          zoom: 14
        })
      }
    } else {
      setToast({ message: 'Tọa độ không hợp lệ', type: 'error' })
    }
  }

  function handleUseCurrentLocation() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude
          const lon = position.coords.longitude
          setLocation({ lat, lon })
          setCustomLocation({ lat: lat.toFixed(6), lon: lon.toFixed(6) })
          if (mapObj.current) {
            mapObj.current.flyTo({
              center: [lon, lat],
              zoom: 14
            })
          }
        },
        (error) => {
          setToast({ message: 'Không thể lấy vị trí hiện tại: ' + error.message, type: 'error' })
        }
      )
    } else {
      setToast({ message: 'Trình duyệt không hỗ trợ Geolocation API', type: 'error' })
    }
  }

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>
              Điểm quan tâm (Points of Interest)
            </h1>

            {/* Search Controls */}
            <div className="card" style={{ marginBottom: 16 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr auto', gap: 12, alignItems: 'end' }}>
                {/* Location Input */}
                <div>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                    Vĩ độ (Latitude)
                  </label>
                  <input
                    type="number"
                    step="0.000001"
                    value={customLocation.lat}
                    onChange={(e) => setCustomLocation({ ...customLocation, lat: e.target.value })}
                    placeholder="10.78"
                    style={{ width: '100%', padding: 8, border: '1px solid #ddd', borderRadius: 4 }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                    Kinh độ (Longitude)
                  </label>
                  <input
                    type="number"
                    step="0.000001"
                    value={customLocation.lon}
                    onChange={(e) => setCustomLocation({ ...customLocation, lon: e.target.value })}
                    placeholder="106.70"
                    style={{ width: '100%', padding: 8, border: '1px solid #ddd', borderRadius: 4 }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                    Bán kính (mét)
                  </label>
                  <input
                    type="number"
                    min="100"
                    max="5000"
                    step="100"
                    value={radius}
                    onChange={(e) => setRadius(parseInt(e.target.value) || 500)}
                    style={{ width: '100%', padding: 8, border: '1px solid #ddd', borderRadius: 4 }}
                  />
                </div>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button
                    onClick={handleCustomLocation}
                    style={{
                      padding: '8px 16px',
                      backgroundColor: '#3b82f6',
                      color: 'white',
                      border: 'none',
                      borderRadius: 4,
                      cursor: 'pointer',
                      fontSize: 14
                    }}
                  >
                    Tìm kiếm
                  </button>
                  <button
                    onClick={handleUseCurrentLocation}
                    style={{
                      padding: '8px 16px',
                      backgroundColor: '#10b981',
                      color: 'white',
                      border: 'none',
                      borderRadius: 4,
                      cursor: 'pointer',
                      fontSize: 14
                    }}
                  >
                    📍 Vị trí hiện tại
                  </button>
                </div>
              </div>

              {/* POI Type Selector */}
              <div style={{ marginTop: 16 }}>
                <label style={{ display: 'block', marginBottom: 8, fontSize: 14, fontWeight: 500 }}>
                  Loại POI
                </label>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {poiTypes.map(type => (
                    <button
                      key={type.value}
                      onClick={() => setPoiType(type.value)}
                      style={{
                        padding: '8px 16px',
                        backgroundColor: poiType === type.value ? '#3b82f6' : '#f3f4f6',
                        color: poiType === type.value ? 'white' : '#374151',
                        border: '1px solid #ddd',
                        borderRadius: 4,
                        cursor: 'pointer',
                        fontSize: 14,
                        fontWeight: poiType === type.value ? 600 : 400
                      }}
                    >
                      {type.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Map and Results */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 400px', gap: 16 }}>
              {/* Map */}
              <div className="card" style={{ padding: 0, height: '600px', position: 'relative' }}>
                <div
                  ref={mapRef}
                  style={{ width: '100%', height: '100%', borderRadius: 8 }}
                />
                {loading && (
                  <div style={{
                    position: 'absolute',
                    top: 16,
                    left: 16,
                    backgroundColor: 'white',
                    padding: '8px 16px',
                    borderRadius: 4,
                    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                    fontSize: 14
                  }}>
                    Đang tải...
                  </div>
                )}
              </div>

              {/* Results List */}
              <div className="card">
                <h3 style={{ fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
                  Kết quả ({pois.length})
                </h3>
                {pois.length === 0 && !loading && (
                  <div style={{ textAlign: 'center', padding: 40, color: '#6b7280' }}>
                    Không tìm thấy POI nào trong bán kính {radius}m
                  </div>
                )}
                <div style={{ maxHeight: '550px', overflowY: 'auto' }}>
                  {pois.map((poi, index) => (
                    <div
                      key={poi.id || index}
                      onClick={() => {
                        setSelectedPoi(poi)
                        if (mapObj.current) {
                          mapObj.current.flyTo({
                            center: [poi.lon, poi.lat],
                            zoom: 16
                          })
                        }
                      }}
                      style={{
                        padding: 12,
                        marginBottom: 8,
                        border: '1px solid #e5e7eb',
                        borderRadius: 8,
                        cursor: 'pointer',
                        backgroundColor: selectedPoi?.id === poi.id ? '#eff6ff' : 'white',
                        transition: 'all 0.2s'
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.backgroundColor = '#f3f4f6'
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.backgroundColor = selectedPoi?.id === poi.id ? '#eff6ff' : 'white'
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'start', gap: 12 }}>
                        <div style={{ fontSize: 24 }}>{getPoiIcon(poi.type)}</div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontWeight: 600, marginBottom: 4, fontSize: 14 }}>
                            {poi.name}
                          </div>
                          <div style={{ fontSize: 12, color: '#6b7280', marginBottom: 4 }}>
                            {poi.type}
                          </div>
                          <div style={{ fontSize: 12, color: '#6b7280' }}>
                            📍 {poi.distance}m
                          </div>
                          {poi.address && (
                            <div style={{ fontSize: 12, color: '#6b7280', marginTop: 4 }}>
                              {poi.address}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Selected POI Details */}
            {selectedPoi && (
              <div className="card" style={{ marginTop: 16 }}>
                <h3 style={{ fontSize: 18, fontWeight: 600, marginBottom: 12 }}>
                  Chi tiết POI
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div>
                    <strong>Tên:</strong> {selectedPoi.name}
                  </div>
                  <div>
                    <strong>Loại:</strong> {selectedPoi.type}
                  </div>
                  <div>
                    <strong>Khoảng cách:</strong> {selectedPoi.distance}m
                  </div>
                  <div>
                    <strong>Tọa độ:</strong> {selectedPoi.lat.toFixed(6)}, {selectedPoi.lon.toFixed(6)}
                  </div>
                  {selectedPoi.address && (
                    <div style={{ gridColumn: '1 / -1' }}>
                      <strong>Địa chỉ:</strong> {selectedPoi.address}
                    </div>
                  )}
                  {selectedPoi.tags && Object.keys(selectedPoi.tags).length > 0 && (
                    <div style={{ gridColumn: '1 / -1' }}>
                      <strong>Thông tin thêm:</strong>
                      <div style={{ marginTop: 8, fontSize: 12, color: '#6b7280' }}>
                        {Object.entries(selectedPoi.tags).slice(0, 5).map(([key, value]) => (
                          <div key={key}>
                            {key}: {value}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </main>
      </div>
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  )
}


