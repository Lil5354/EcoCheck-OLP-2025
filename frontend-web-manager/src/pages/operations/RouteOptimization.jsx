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
  const poiMarkersRef = useRef([]) // POI markers ref
  const [showPOIs, setShowPOIs] = useState(false) // POI visibility - default false
  
  // Employee assignment
  const [personnel, setPersonnel] = useState([])
  const [assignModalOpen, setAssignModalOpen] = useState(false)
  const [selectedRoute, setSelectedRoute] = useState(null)
  const [selectedEmployeeId, setSelectedEmployeeId] = useState('')
  
  // Filters
  const [collectionDate, setCollectionDate] = useState(new Date().toISOString().split('T')[0])
  const [selectedDistrict, setSelectedDistrict] = useState('')
  const [districts, setDistricts] = useState([])
  const [selectedDepot, setSelectedDepot] = useState('')
  const [selectedDump, setSelectedDump] = useState('')

  useEffect(() => {
    loadData()
    initMap()
    return () => {
      // Cleanup on unmount
      clearRouteDisplay()
    }
  }, [collectionDate, selectedDistrict])

  // Load districts when date changes
  useEffect(() => {
    if (collectionDate) {
      loadDistricts()
    }
  }, [collectionDate])

  // Auto-filter when district changes
  useEffect(() => {
    if (selectedDistrict) {
      autoFilterByDistrict()
    } else {
      // Reset filters when no district selected
      setSelectedDepot('')
      setSelectedDump('')
      setSelectedVehicles([])
    }
  }, [selectedDistrict])

  // Update POI visibility when showPOIs changes
  useEffect(() => {
    if (!mapObj.current || !mapObj.current.loaded()) return
    
    if (!showPOIs) {
      clearPOIMarkers()
    } else if (activeRouteId && showPOIs) {
      // Load POIs when enabled
      setTimeout(() => {
        loadPOIsForCurrentRoute()
      }, 300)
    }
  }, [showPOIs, activeRouteId])
  
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

  async function loadDistricts() {
    const res = await api.getDistricts(collectionDate)
    console.log('[RouteOptimization] Load districts response:', res)
    if (res.ok && Array.isArray(res.data)) {
      console.log('[RouteOptimization] Districts loaded:', res.data)
      setDistricts(res.data)
      // Auto-select first district if available
      if (res.data.length > 0 && !selectedDistrict) {
        setSelectedDistrict(res.data[0].district)
      }
    } else {
      console.warn('[RouteOptimization] Failed to load districts:', res)
    }
  }

  // Helper function to extract district from address
  function extractDistrictFromAddress(address) {
    if (!address) return null
    const match = address.match(/Quận\s*(\d+)|Q\.?\s*(\d+)/i)
    if (match) return `Quận ${match[1] || match[2]}`
    const districts = [
      'Quận 1', 'Quận 2', 'Quận 3', 'Quận 4', 'Quận 5',
      'Quận 6', 'Quận 7', 'Quận 8', 'Quận 9', 'Quận 10',
      'Quận 11', 'Quận 12', 'Bình Thạnh', 'Tân Bình', 'Tân Phú',
      'Phú Nhuận', 'Gò Vấp', 'Bình Tân', 'Thủ Đức'
    ]
    for (const dist of districts) {
      if (address.includes(dist)) return dist
    }
    return null
  }

  async function autoFilterByDistrict() {
    if (!selectedDistrict) return

    // Load data with district filter from backend
    const [f, s, dep, dum, p] = await Promise.all([
      api.getFleet({ district: selectedDistrict }),
      api.getSchedules({ 
        scheduled_date: collectionDate, 
        status: 'scheduled',
        district: selectedDistrict
      }),
      api.getDepots({ district: selectedDistrict }),
      api.getDumps(), // Dumps không filter theo quận
      api.getPersonnel({ 
        status: 'active',
        district: selectedDistrict
      })
    ])

    // Set filtered data directly from backend
    if (s.ok && Array.isArray(s.data)) {
      setSchedules(s.data)
    } else {
      setSchedules([])
    }

    if (dep.ok && Array.isArray(dep.data)) {
      setDepots(dep.data)
      // Auto-select first depot in district
      if (dep.data.length > 0) {
        setSelectedDepot(dep.data[0].id)
      }
    } else {
      setDepots([])
    }

    if (f.ok && Array.isArray(f.data)) {
      setFleet(f.data)
    } else {
      setFleet([])
    }

    // Keep all dumps (will auto-select best one)
    if (dum.ok && Array.isArray(dum.data)) {
      setDumps(dum.data)
    } else {
      setDumps([])
    }

    // Filter only drivers and collectors
    if (p.ok && Array.isArray(p.data)) {
      const filtered = p.data.filter(emp => 
        emp.role === 'driver' || emp.role === 'collector'
      )
      setPersonnel(filtered)
    } else {
      setPersonnel([])
    }
  }

  async function loadData() {
    const [f, s, dep, dum, p] = await Promise.all([
      api.getFleet(),
      api.getSchedules({ scheduled_date: collectionDate, status: 'scheduled' }),
      api.getDepots(),
      api.getDumps(),
      api.getPersonnel({ status: 'active' })
    ])
    if (f.ok && Array.isArray(f.data)) setFleet(f.data)
    if (s.ok && Array.isArray(s.data)) setSchedules(s.data)
    if (dep.ok && Array.isArray(dep.data)) setDepots(dep.data)
    if (dum.ok && Array.isArray(dum.data)) setDumps(dum.data)
    if (p.ok && Array.isArray(p.data)) {
      // Filter only drivers and collectors
      const filtered = p.data.filter(emp => emp.role === 'driver' || emp.role === 'collector')
      setPersonnel(filtered)
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
    
    // Clear all markers (stops, depot, dump)
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
    // Backend already ensures route includes START and END, so just display it
    console.log('[RouteOptimization] Route geojson:', route.geojson)
    
    // Validate route geometry before displaying
    const hasValidGeometry = route.geojson && 
                             route.geojson.features && 
                             route.geojson.features.length > 0 &&
                             route.geojson.features[0]?.geometry &&
                             route.geojson.features[0].geometry.coordinates &&
                             Array.isArray(route.geojson.features[0].geometry.coordinates) &&
                             route.geojson.features[0].geometry.coordinates.length >= 2
    
    if (hasValidGeometry) {
      const source = routeSourceRef.current || mapObj.current.getSource('route')
      if (source) {
        source.setData(route.geojson)
        const coordCount = route.geojson.features[0].geometry.coordinates.length
        console.log(`[RouteOptimization] Route displayed on map with ${coordCount} coordinates (START and END included by backend)`)
      } else {
        console.error('[RouteOptimization] Route source not found')
      }
      
      // Fit map to route bounds - include all waypoints (depot, stops, dump)
      const coordinates = route.geojson.features[0].geometry.coordinates
      const bounds = new maplibregl.LngLatBounds()
      
      // Add route coordinates
      if (coordinates.length > 0) {
        coordinates.forEach(coord => {
          if (Array.isArray(coord) && coord.length >= 2) {
            bounds.extend(coord)
          }
        })
      }
      
      // Also include all waypoints to ensure they're visible
      if (route.depot && route.depot.lon && route.depot.lat) {
        bounds.extend([parseFloat(route.depot.lon), parseFloat(route.depot.lat)])
      }
      if (route.stops && Array.isArray(route.stops)) {
        route.stops.forEach(stop => {
          if (stop.lon && stop.lat) {
            bounds.extend([parseFloat(stop.lon), parseFloat(stop.lat)])
          }
        })
      }
      if (route.dump && route.dump.lon && route.dump.lat) {
        bounds.extend([parseFloat(route.dump.lon), parseFloat(route.dump.lat)])
      }
      
      if (!bounds.isEmpty()) {
        mapObj.current.fitBounds(bounds, {
          padding: { top: 50, bottom: 50, left: 50, right: 50 },
          maxZoom: 15
        })
      }
    } else {
      console.warn('[RouteOptimization] No valid route geometry to display', {
        hasGeojson: !!route.geojson,
        hasFeatures: !!(route.geojson?.features),
        featuresCount: route.geojson?.features?.length || 0,
        hasGeometry: !!(route.geojson?.features?.[0]?.geometry),
        hasCoordinates: !!(route.geojson?.features?.[0]?.geometry?.coordinates),
        coordinatesCount: route.geojson?.features?.[0]?.geometry?.coordinates?.length || 0
      })
    }
    
    // Add marker for depot (start point) - Improved styling with clear START label
    console.log('[RouteOptimization] Display route - depot:', route.depot, 'dump:', route.dump)
    console.log('[RouteOptimization] Using NEW marker style - START (green square) and END (red circle)')
    if (route.depot && route.depot.lon && route.depot.lat) {
      const depotEl = document.createElement('div')
      depotEl.className = 'route-depot-marker'
      // Set all styles with !important to override any CSS
      depotEl.setAttribute('style', `
        width: 50px !important;
        height: 50px !important;
        border-radius: 12px !important;
        background-color: #059669 !important;
        border: 5px solid #ffffff !important;
        box-shadow: 0 4px 16px rgba(5, 150, 105, 0.6), 0 0 0 3px rgba(5, 150, 105, 0.2) !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        color: white !important;
        font-size: 11px !important;
        font-weight: 900 !important;
        font-family: system-ui, -apple-system, sans-serif !important;
        letter-spacing: 0.5px !important;
        line-height: 1.1 !important;
        text-align: center !important;
        padding: 2px !important;
        box-sizing: border-box !important;
        position: relative !important;
        z-index: 1000 !important;
      `)
      depotEl.textContent = 'START'
      depotEl.title = `Điểm bắt đầu: ${route.depot.name || 'Depot'}`
      
      // Force style after element is created
      setTimeout(() => {
        depotEl.style.width = '50px'
        depotEl.style.height = '50px'
        depotEl.style.backgroundColor = '#059669'
        depotEl.style.borderRadius = '12px'
        console.log('[RouteOptimization] START marker style applied:', {
          width: depotEl.style.width,
          height: depotEl.style.height,
          bgColor: depotEl.style.backgroundColor,
          borderRadius: depotEl.style.borderRadius
        })
      }, 10)
      
      const depotMarker = new maplibregl.Marker({ element: depotEl })
        .setLngLat([parseFloat(route.depot.lon), parseFloat(route.depot.lat)])
        .addTo(mapObj.current)
      
      stopMarkersRef.current.push(depotMarker)
      console.log('[RouteOptimization] Added depot marker at:', route.depot.lon, route.depot.lat)
    } else {
      console.warn('[RouteOptimization] Depot missing or invalid:', route.depot)
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
    
    // Add marker for dump (end point) - Improved styling with clear END label
    if (route.dump && route.dump.lon && route.dump.lat) {
      const dumpEl = document.createElement('div')
      dumpEl.className = 'route-dump-marker'
      // Set all styles with !important to override any CSS
      dumpEl.setAttribute('style', `
        width: 50px !important;
        height: 50px !important;
        border-radius: 50% !important;
        background-color: #dc2626 !important;
        border: 5px solid #ffffff !important;
        box-shadow: 0 4px 16px rgba(220, 38, 38, 0.6), 0 0 0 3px rgba(220, 38, 38, 0.2) !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        color: white !important;
        font-size: 11px !important;
        font-weight: 900 !important;
        font-family: system-ui, -apple-system, sans-serif !important;
        letter-spacing: 0.5px !important;
        line-height: 1.1 !important;
        text-align: center !important;
        padding: 2px !important;
        box-sizing: border-box !important;
        position: relative !important;
        z-index: 1000 !important;
      `)
      dumpEl.textContent = 'END'
      dumpEl.title = `Điểm kết thúc: ${route.dump.name || 'Dump'}`
      
      // Force style after element is created
      setTimeout(() => {
        dumpEl.style.width = '50px'
        dumpEl.style.height = '50px'
        dumpEl.style.backgroundColor = '#dc2626'
        dumpEl.style.borderRadius = '50%'
        console.log('[RouteOptimization] END marker style applied:', {
          width: dumpEl.style.width,
          height: dumpEl.style.height,
          bgColor: dumpEl.style.backgroundColor,
          borderRadius: dumpEl.style.borderRadius
        })
      }, 10)
      
      const dumpMarker = new maplibregl.Marker({ element: dumpEl })
        .setLngLat([parseFloat(route.dump.lon), parseFloat(route.dump.lat)])
        .addTo(mapObj.current)
      
      stopMarkersRef.current.push(dumpMarker)
      console.log('[RouteOptimization] Added dump marker at:', route.dump.lon, route.dump.lat)
    } else {
      console.warn('[RouteOptimization] Dump missing or invalid:', route.dump)
    }
    
  }

  // Clear POI markers
  function clearPOIMarkers() {
    if (poiMarkersRef.current && poiMarkersRef.current.length > 0) {
      poiMarkersRef.current.forEach(marker => {
        if (marker && marker.remove) {
          try {
            marker.remove()
          } catch (error) {
            console.warn('[RouteOptimization] Error removing POI marker:', error)
          }
        }
      })
      poiMarkersRef.current = []
    }
  }

  // Load POIs for current route - Simple approach: use map center and visible bounds
  async function loadPOIsForCurrentRoute() {
    if (!mapObj.current || !mapObj.current.loaded()) {
      console.warn('[RouteOptimization] Map not ready')
      return
    }

    clearPOIMarkers()

    try {
      // Get map bounds to find POIs in visible area
      const bounds = mapObj.current.getBounds()
      const center = mapObj.current.getCenter()
      
      // Calculate radius based on map bounds (approximate)
      const ne = bounds.getNorthEast()
      const sw = bounds.getSouthWest()
      const latDiff = ne.lat - sw.lat
      const lonDiff = ne.lng - sw.lng
      const radius = Math.max(1000, Math.max(latDiff, lonDiff) * 111000) // Convert to meters, min 1km
      const searchRadius = Math.min(radius, 3000) // Max 3km

      console.log(`[RouteOptimization] Loading POIs for map center: [${center.lat}, ${center.lng}], radius: ${Math.round(searchRadius)}m`)

      // Fetch POIs near map center
      const [gasRes, parkingRes] = await Promise.all([
        api.getNearbyPOI(center.lat, center.lng, searchRadius, 'gas_station'),
        api.getNearbyPOI(center.lat, center.lng, searchRadius, 'parking')
      ])

      const allPois = []
      
      if (gasRes?.ok && Array.isArray(gasRes.data)) {
        allPois.push(...gasRes.data.slice(0, 20).map(p => ({ ...p, type: 'gas_station' })))
      }
      
      if (parkingRes?.ok && Array.isArray(parkingRes.data)) {
        allPois.push(...parkingRes.data.slice(0, 15).map(p => ({ ...p, type: 'parking' })))
      }

      console.log(`[RouteOptimization] Found ${allPois.length} POIs (gas: ${gasRes?.data?.length || 0}, parking: ${parkingRes?.data?.length || 0})`)

      // Display POIs on map
      if (allPois.length > 0) {
        displayPOIsOnMap(allPois)
      } else {
        setToast({ message: 'Không tìm thấy POI trong khu vực này', type: 'info' })
      }
    } catch (error) {
      console.error('[RouteOptimization] Error loading POIs:', error)
      setToast({ message: 'Lỗi khi tải POI: ' + error.message, type: 'error' })
    }
  }

  // Display POIs on map
  function displayPOIsOnMap(poisData) {
    if (!mapObj.current || !mapObj.current.loaded()) {
      console.warn('[RouteOptimization] Map not ready')
      return
    }

    if (!poisData || poisData.length === 0) {
      return
    }

    poisData.forEach((poi) => {
      if (!poi?.lat || !poi?.lon) return

      try {
        const el = document.createElement('div')
        el.style.cssText = `
          width: 28px !important;
          height: 28px !important;
          border-radius: 50% !important;
          background-color: ${poi.type === 'gas_station' ? '#f59e0b' : '#6366f1'} !important;
          border: 2px solid white !important;
          box-shadow: 0 2px 6px rgba(0,0,0,0.4) !important;
          cursor: pointer !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
          font-size: 14px !important;
          z-index: 1000 !important;
        `
        el.textContent = poi.type === 'gas_station' ? '⛽' : '🅿️'

        const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
          .setLngLat([parseFloat(poi.lon), parseFloat(poi.lat)])
          .setPopup(
            new maplibregl.Popup({ offset: 25, closeButton: true })
              .setHTML(`
                <div style="padding: 6px; min-width: 120px;">
                  <strong>${poi.name || (poi.type === 'gas_station' ? 'Trạm xăng' : 'Bãi đỗ xe')}</strong><br/>
                  <small style="color: #666;">${poi.type === 'gas_station' ? '⛽' : '🅿️'} ${poi.distance ? Math.round(poi.distance) + 'm' : ''}</small>
                </div>
              `)
          )
          .addTo(mapObj.current)

        poiMarkersRef.current.push(marker)
      } catch (error) {
        console.error('[RouteOptimization] Error creating POI marker:', error)
      }
    })

    console.log(`[RouteOptimization] ✅ Displayed ${poisData.length} POIs`)
  }

  function handleRouteDoubleClick(route) {
    displayRouteOnMap(route)
  }

  function handleAssignEmployee(route) {
    setSelectedRoute(route)
    setSelectedEmployeeId(route.driver_id || route.assigned_employee_id || '')
    setAssignModalOpen(true)
  }

  async function handleSaveAssignment() {
    if (!selectedRoute || !selectedEmployeeId) {
      setToast({ message: 'Vui lòng chọn nhân viên', type: 'error' })
      return
    }

    setLoading(true)
    try {
      // First save route if not saved yet (get route_id from save-routes)
      let routeId = selectedRoute.route_id
      if (!routeId) {
        // Save route first
        const saveRes = await api.saveRoutes({ routes: [selectedRoute] })
        if (saveRes.ok && saveRes.data.routes && saveRes.data.routes.length > 0) {
          routeId = saveRes.data.routes[0].route_id
        } else {
          setToast({ message: 'Không thể lưu hành trình', type: 'error' })
          setLoading(false)
          return
        }
      }

      // Assign employee to route
      const res = await api.assignRoute(routeId, selectedEmployeeId)
      setLoading(false)
      
      if (res.ok) {
        setToast({ message: 'Đã gán nhân viên thành công', type: 'success' })
        setAssignModalOpen(false)
        setSelectedRoute(null)
        setSelectedEmployeeId('')
        
        // Update route in list
        setRoutes(prevRoutes => 
          prevRoutes.map(r => 
            r.vehicleId === selectedRoute.vehicleId 
              ? { ...r, driver_id: selectedEmployeeId, route_id: routeId, assigned: true }
              : r
          )
        )
      } else {
        setToast({ message: res.error || 'Gán nhân viên thất bại', type: 'error' })
      }
    } catch (error) {
      setLoading(false)
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
    }
  }

  async function handleOptimize() {
    if (!selectedDistrict) {
      setToast({ message: 'Vui lòng chọn quận', type: 'error' })
      return
    }
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
    // Don't require dump - backend will auto-select best one
    const dump = dumps.find(d => d.id === selectedDump) || null
    
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
      depot: depot ? { id: depot.id, name: depot.name, lon: depot.lon, lat: depot.lat } : { lon: 106.7, lat: 10.78 },
      dump: dump ? { id: dump.id, name: dump.name, lon: dump.lon, lat: dump.lat } : null,
      dumps: dumps, // Send all dumps for auto-selection
      points
    }
    const res = await api.optimizeVRP(payload)
    setLoading(false)
    if (res.ok) {
      const optimizedRoutes = res.data.routes || []
      
      console.log('[RouteOptimization] Optimized routes received:', optimizedRoutes.length)
      setRoutes(optimizedRoutes)
      setToast({ message: `Tối ưu tuyến đường ${selectedDistrict} thành công`, type: 'success' })
      
      // Auto-display first route on map with POIs
      if (optimizedRoutes.length > 0 && mapObj.current && mapObj.current.loaded()) {
        setTimeout(() => {
          displayRouteOnMap(optimizedRoutes[0])
        }, 500) // Small delay to ensure map is ready
      }
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
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Tối ưu tuyến đường</h1>
            
            {/* Filters */}
            <div className="card" style={{ marginBottom: 16 }}>
              <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}>
                <div style={{ flex: '1 1 200px' }}>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>📅 Ngày thu gom</label>
                  <input
                    type="date"
                    value={collectionDate}
                    onChange={(e) => setCollectionDate(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                  />
                </div>
                <div style={{ flex: '1 1 200px' }}>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>🗺️ Chọn quận</label>
                  <select
                    value={selectedDistrict}
                    onChange={(e) => setSelectedDistrict(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                  >
                    <option value="">-- Chọn quận --</option>
                    {districts.map(d => (
                      <option key={d.district} value={d.district}>
                        {d.district} ({d.point_count || d.schedule_count || 0} điểm)
                      </option>
                    ))}
                  </select>
                </div>
                {selectedDistrict && (
                  <>
                    <div style={{ flex: '1 1 200px' }}>
                      <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>📍 Trạm thu gom (tự động)</label>
                      <select
                        value={selectedDepot}
                        onChange={(e) => setSelectedDepot(e.target.value)}
                        style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6, backgroundColor: '#f5f5f5' }}
                        disabled={depots.length <= 1}
                      >
                        {depots.map(d => (
                          <option key={d.id} value={d.id}>{d.name}</option>
                        ))}
                      </select>
                    </div>
                    <div style={{ flex: '1 1 200px' }}>
                      <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>🗑️ Bãi rác (tự động)</label>
                      <select
                        value={selectedDump || ''}
                        onChange={(e) => setSelectedDump(e.target.value)}
                        style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6, backgroundColor: '#f5f5f5' }}
                      >
                        <option value="">Tự động chọn gần nhất</option>
                        {dumps.map(d => (
                          <option key={d.id} value={d.id}>{d.name}</option>
                        ))}
                      </select>
                    </div>
                  </>
                )}
                <div style={{ flex: '0 0 auto', alignSelf: 'flex-end', display: 'flex', gap: 8 }}>
                  <button 
                    className={`btn ${showPOIs ? 'btn-primary' : 'btn-secondary'}`}
                    onClick={async () => {
                      if (!showPOIs) {
                        setShowPOIs(true)
                        await loadPOIsForCurrentRoute()
                      } else {
                        setShowPOIs(false)
                        clearPOIMarkers()
                      }
                    }}
                    style={{ marginTop: 24 }}
                    title="Bật/tắt hiển thị POI (trạm xăng ⛽, bãi đỗ xe 🅿️) trên bản đồ"
                  >
                    {showPOIs ? '📍 Ẩn POI' : '📍 Hiện POI'}
                  </button>
                  <button className="btn btn-secondary" onClick={loadData} style={{ marginTop: 24 }}>
                    Tải lại
                  </button>
                </div>
              </div>
              {selectedDistrict && (
                <div style={{ marginTop: 12, padding: 12, backgroundColor: '#e3f2fd', borderRadius: 6, fontSize: 14, color: '#1976d2' }}>
                  📍 <strong>{selectedDistrict}</strong>: Tìm thấy {schedules.length} điểm thu gom · {depots.length} trạm · {fleet.length} phương tiện
                </div>
              )}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 300px', gap: 24 }}>
              <div className="card">
                <h2>Bản đồ & Lịch thu gom</h2>
                <div style={{ marginBottom: 12, color: '#666', fontSize: 14 }}>
                  {selectedDistrict ? (
                    <>Tìm thấy {schedules.length} điểm thu gom tại <strong>{selectedDistrict}</strong> cho ngày {new Date(collectionDate).toLocaleDateString('vi-VN')}</>
                  ) : (
                    <>Tìm thấy {schedules.length} lịch thu gom cho ngày {new Date(collectionDate).toLocaleDateString('vi-VN')}</>
                  )}
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
                  <h2 style={{ margin: 0 }}>
                    {selectedDistrict ? `Danh sách tuyến đường ${selectedDistrict}` : 'Tuyến đường đã tối ưu'}
                  </h2>
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
                  {routes.map((r, i) => {
                    const depotName = r.depot?.name || depots.find(d => d.id === r.depot_id || d.id === selectedDepot)?.name || 'Depot'
                    const dumpName = r.dump?.name || dumps.find(d => d.id === r.dump_id || d.id === selectedDump)?.name || 'Dump'
                    const assignedEmployee = personnel.find(p => p.id === r.driver_id)
                    
                    return (
                      <div 
                        key={i} 
                        style={{ 
                          padding: 12, 
                          border: `2px solid ${activeRouteId === r.vehicleId ? '#3b82f6' : r.assigned ? '#10b981' : '#e0e0e0'}`, 
                          borderRadius: 6,
                          backgroundColor: activeRouteId === r.vehicleId ? '#eff6ff' : r.assigned ? '#f0fdf4' : 'white',
                          transition: 'all 0.2s'
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: 8 }}>
                          <div style={{ flex: 1 }}>
                            <div style={{ fontWeight: 600, color: activeRouteId === r.vehicleId ? '#3b82f6' : 'inherit', marginBottom: 4 }}>
                              Hành trình {String.fromCharCode(65 + i)} · {r.vehiclePlate || r.vehicleId}
                            </div>
                            <div style={{ fontSize: 12, color: '#666', marginBottom: 2 }}>
                              <strong>Điểm xuất phát:</strong> {depotName}
                            </div>
                            <div style={{ fontSize: 12, color: '#666', marginBottom: 2 }}>
                              <strong>Điểm đến:</strong> {dumpName}
                            </div>
                            <div style={{ fontSize: 12, color: '#666', marginBottom: 4 }}>
                              <strong>Số lượng bộ/tuyến:</strong> {r.stops?.length || 0} điểm thu gom
                            </div>
                            <div style={{ fontSize: 11, color: '#888', marginTop: 4 }}>
                              Khoảng cách: {r.distance && r.distance > 0 ? (r.distance / 1000).toFixed(2) : '0.00'}km · Thời gian: {r.eta || '00:00'} · Điểm dừng: {r.stops?.length || 0}
                            </div>
                            {r.assigned && assignedEmployee && (
                              <div style={{ fontSize: 11, color: '#10b981', marginTop: 4, fontWeight: 500 }}>
                                ✓ Đã gán: {assignedEmployee.name}
                              </div>
                            )}
                            {activeRouteId === r.vehicleId && (
                              <div style={{ fontSize: 11, color: '#3b82f6', marginTop: 4, fontStyle: 'italic' }}>
                                📍 Đang hiển thị trên bản đồ
                              </div>
                            )}
                      </div>
                    </div>
                        <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                          <button
                            className="btn btn-secondary"
                            onClick={() => handleRouteDoubleClick(r)}
                            style={{ flex: 1, fontSize: 12, padding: '6px 12px' }}
                          >
                            Xem bản đồ
                          </button>
                          <button
                            className="btn btn-primary"
                            onClick={() => handleAssignEmployee(r)}
                            disabled={loading}
                            style={{ flex: 1, fontSize: 12, padding: '6px 12px' }}
                          >
                            {r.assigned ? 'Đổi nhân viên' : 'Gán nhân viên'}
                          </button>
                </div>
                      </div>
                    )
                  })}
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
      
      {/* Assign Employee Modal */}
      {assignModalOpen && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div style={{
            backgroundColor: 'white',
            padding: 24,
            borderRadius: 8,
            width: '90%',
            maxWidth: 500,
            boxShadow: '0 4px 20px rgba(0,0,0,0.3)'
          }}>
            <h3 style={{ marginTop: 0, marginBottom: 16 }}>Gán nhân viên cho hành trình</h3>
            {selectedRoute && (
              <div style={{ marginBottom: 16, padding: 12, backgroundColor: '#f5f5f5', borderRadius: 6 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>
                  {selectedRoute.vehiclePlate || selectedRoute.vehicleId}
                </div>
                <div style={{ fontSize: 12, color: '#666' }}>
                  {selectedRoute.stops?.length || 0} điểm thu gom · {(selectedRoute.distance / 1000).toFixed(2)}km
                </div>
              </div>
            )}
            <label style={{ display: 'block', marginBottom: 8, fontSize: 14, fontWeight: 500 }}>
              Chọn nhân viên
            </label>
            <select
              value={selectedEmployeeId}
              onChange={(e) => setSelectedEmployeeId(e.target.value)}
              style={{
                width: '100%',
                padding: '10px 12px',
                border: '1px solid #ccc',
                borderRadius: 6,
                fontSize: 14,
                marginBottom: 16
              }}
            >
              <option value="">-- Chọn nhân viên --</option>
              {personnel.map(emp => (
                <option key={emp.id} value={emp.id}>
                  {emp.name} ({emp.role === 'driver' ? 'Tài xế' : 'Công nhân'}) - {emp.phone || 'N/A'}
                </option>
              ))}
            </select>
            <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
              <button
                className="btn btn-secondary"
                onClick={() => {
                  setAssignModalOpen(false)
                  setSelectedRoute(null)
                  setSelectedEmployeeId('')
                }}
                disabled={loading}
              >
                Hủy
              </button>
              <button
                className="btn btn-primary"
                onClick={handleSaveAssignment}
                disabled={loading || !selectedEmployeeId}
              >
                {loading ? 'Đang xử lý...' : 'Gán nhân viên'}
              </button>
            </div>
          </div>
        </div>
      )}
      
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

