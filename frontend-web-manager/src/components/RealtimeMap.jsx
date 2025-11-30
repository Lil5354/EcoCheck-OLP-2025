/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Realtime Map Component using MapLibre GL
 */

import React, { useEffect, useRef } from 'react'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import { Legend } from './Charts.jsx'

export default function RealtimeMap() {
  const mapRef = useRef(null)
  const mapObj = useRef(null)
  const pointMarkersRef = useRef([])
  const vehicleMarkersRef = useRef([])
  const pointsTimerRef = useRef(null)
  const vehiclesTimerRef = useRef(null)

  const initTimeoutRef = useRef(null)

  useEffect(() => {
    if (mapObj.current) return

    // Classify check-in point into color-coded status
    const classify = (p) => {
      const level = typeof p.level === 'number' ? p.level : parseFloat(p.level) || 0
      
      // Ghost points (không rác) - Grey
      if (p.ghost === true || p.type === 'ghost' || level === 0) return 'grey'
      
      // Bulky waste or incidents - Red
      if (p.type === 'bulky' || p.incident) return 'red'
      
      // High waste level (>= 0.7) - Orange/Yellow
      if (level >= 0.7) return 'orange'
      
      // Low/Medium waste - Green
      return 'green'
    }

    const loadPoints = async () => {
      if (!mapObj.current || !mapObj.current.loaded()) {
        console.warn('[RealtimeMap] Map not ready, skipping loadPoints')
        return
      }
      try {
        // Use /api/rt/points instead of /api/rt/checkins for better data
        const res = await fetch('/api/rt/points')
        if (!res.ok) {
          console.warn('[RealtimeMap] Failed to load points:', res.status)
          return
        }
        const json = await res.json()
        const pts = json.added || json.data || []
        console.log('[RealtimeMap] Loaded', pts.length, 'points')
        
        // cleanup old point markers
        pointMarkersRef.current.forEach(m => m.remove())
        pointMarkersRef.current = []

        if (pts.length === 0) {
          console.warn('[RealtimeMap] No points to display')
          return
        }

        let minLng=999, minLat=999, maxLng=-999, maxLat=-999
        let addedCount = 0
        pts.forEach(p => {
          if (!p.lon || !p.lat) {
            console.warn('[RealtimeMap] Skipping point with missing coordinates:', p)
            return
          }
          try {
            const el = document.createElement('div')
            const status = classify(p)
            el.className = `marker ${status}`
            const m = new maplibregl.Marker({ element: el }).setLngLat([p.lon, p.lat]).addTo(mapObj.current)
            pointMarkersRef.current.push(m)
            minLng = Math.min(minLng, p.lon); maxLng = Math.max(maxLng, p.lon)
            minLat = Math.min(minLat, p.lat); maxLat = Math.max(maxLat, p.lat)
            addedCount++
          } catch (err) {
            console.error('[RealtimeMap] Error adding marker:', err, p)
          }
        })
        console.log('[RealtimeMap] Added', addedCount, 'markers to map')
        if (addedCount > 0 && minLng !== 999) {
          mapObj.current.fitBounds([[minLng, minLat], [maxLng, maxLat]], { padding: 30, duration: 800 })
        }
      } catch (e) {
        console.error('[RealtimeMap] Error loading points:', e)
      }
    }

    const loadVehicles = async () => {
      if (!mapObj.current || !mapObj.current.loaded()) {
        return
      }
      try {
        const res = await fetch('/api/rt/vehicles')
        if (!res.ok) {
          console.warn('[RealtimeMap] Failed to load vehicles:', res.status)
          return
        }
        const json = await res.json()
        const vehicles = json.data || []
        console.log('[RealtimeMap] Loaded', vehicles.length, 'vehicles')
        
        // cleanup old vehicle markers
        vehicleMarkersRef.current.forEach(m => m.remove())
        vehicleMarkersRef.current = []
        
        vehicles.forEach(v => {
          if (!v.lon || !v.lat) {
            console.warn('[RealtimeMap] Skipping vehicle with missing coordinates:', v)
            return
          }
          try {
            const el = document.createElement('div')
            el.className = 'marker vehicle'
            const m = new maplibregl.Marker({ element: el }).setLngLat([v.lon, v.lat]).addTo(mapObj.current)
            vehicleMarkersRef.current.push(m)
          } catch (err) {
            console.error('[RealtimeMap] Error adding vehicle marker:', err, v)
          }
        })
      } catch (e) {
        console.error('[RealtimeMap] Error loading vehicles:', e)
      }
    }

    const init = () => {
      if (!mapRef.current) {
        console.warn('[RealtimeMap] Map container not found')
        return
      }
      
      const w = mapRef.current.clientWidth
      const h = mapRef.current.clientHeight
      
      if (w === 0 || h === 0) {
        // container not sized yet, retry shortly
        console.log('[RealtimeMap] Container not sized, retrying...', { w, h })
        initTimeoutRef.current = setTimeout(init, 200)
        return
      }

      try {
        console.log('[RealtimeMap] Initializing map with size:', { w, h })
        mapObj.current = new maplibregl.Map({
          container: mapRef.current,
          style: {
            version: 8,
            sources: {
              osm: {
                type: 'raster',
                tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
                tileSize: 256,
                attribution: '&copy; OpenStreetMap contributors',
                maxzoom: 19
              }
            },
            layers: [
              { id: 'background', type: 'background', paint: { 'background-color': '#eef2f7' } },
              { id: 'osm', type: 'raster', source: 'osm', minzoom: 0, maxzoom: 22 }
            ]
          },
          center: [106.700, 10.780],
          zoom: 11.2,
          attributionControl: true
        })

        mapObj.current.on('error', (e) => {
          console.error('[RealtimeMap] map error:', e?.error || e)
        })

        mapObj.current.addControl(new maplibregl.NavigationControl({ showCompass:false }), 'top-right')

        // Load data after map is fully loaded
        mapObj.current.on('load', () => {
          console.log('[RealtimeMap] Map loaded, resizing and loading data...')
          try { 
            mapObj.current?.resize() 
          } catch (err) { 
            console.warn('[RealtimeMap] Resize error:', err)
          }
          
          // Load data after a short delay to ensure map is ready
          setTimeout(() => {
            loadPoints()
            loadVehicles()
            pointsTimerRef.current = setInterval(loadPoints, 10000)
            vehiclesTimerRef.current = setInterval(loadVehicles, 1000)
          }, 500)
        })
      } catch (err) {
        console.error('[RealtimeMap] Error initializing map:', err)
      }
    }

    // Start initialization with a small delay to ensure DOM is ready
    initTimeoutRef.current = setTimeout(init, 100)

    return () => {
      if (initTimeoutRef.current) {
        clearTimeout(initTimeoutRef.current)
      }
      if (pointsTimerRef.current) {
        clearInterval(pointsTimerRef.current)
      }
      if (vehiclesTimerRef.current) {
        clearInterval(vehiclesTimerRef.current)
      }
      pointMarkersRef.current.forEach(m => {
        try { m.remove() } catch (e) { void e }
      })
      vehicleMarkersRef.current.forEach(m => {
        try { m.remove() } catch (e) { void e }
      })
      if (mapObj.current) {
        try {
          mapObj.current.remove()
        } catch (e) {
          console.warn('[RealtimeMap] Error removing map:', e)
        }
        mapObj.current = null
      }
    }
  }, [])

  const mapLegendItems = [
    { label: 'Không rác (Điểm ma)', color: '#9aa0a6' },
    { label: 'Rác ít/vừa', color: 'var(--success)' },
    { label: 'Rác nhiều', color: 'var(--warning)' },
    { label: 'Rác cồng kềnh/Sự cố', color: 'var(--danger)' }
  ]

  return (
    <div className="map-container">
      <div 
        className="map-root" 
        ref={mapRef} 
        style={{ 
          width: '100%', 
          height: '420px',
          minHeight: '420px',
          position: 'relative',
          backgroundColor: '#eef2f7'
        }} 
      />
      <Legend items={mapLegendItems} />
    </div>
  )
}
