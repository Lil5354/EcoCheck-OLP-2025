/* Realtime Map using MapLibre GL */
import React, { useEffect, useRef } from 'react'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

export default function RealtimeMap() {
  const mapRef = useRef(null)
  const mapObj = useRef(null)
  const pointMarkersRef = useRef([])
  const vehicleMarkersRef = useRef([])
  const pointsTimerRef = useRef(null)
  const vehiclesTimerRef = useRef(null)

  useEffect(() => {
    if (mapObj.current) return

    const init = () => {
      if (!mapRef.current) return
      const w = mapRef.current.clientWidth
      const h = mapRef.current.clientHeight
      if (w === 0 || h === 0) {
        // container not sized yet, retry shortly
        return setTimeout(init, 150)
      }

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
        // swallow map errors for demo
        console.error('[RealtimeMap] map error:', e?.error || e)
      })

      mapObj.current.addControl(new maplibregl.NavigationControl({ showCompass:false }), 'top-right')

      // Ensure proper sizing when first loaded
      mapObj.current.on('load', () => {
        try { mapObj.current?.resize() } catch (err) { void err }
      })

      // first data load after map is ready
      loadPoints()
      loadVehicles()
      pointsTimerRef.current = setInterval(loadPoints, 10000)
      vehiclesTimerRef.current = setInterval(loadVehicles, 1000)
    }

    // Classify check-in point into color-coded status
    const classify = (p) => {
      const level = p.level
      if (p.type === 'bulky' || p.incident) return 'red'
      if (level === 'high' || (typeof level === 'number' && level >= 0.8)) return 'yellow'
      if (p.type === 'ghost' || level === 'none' || level === 0) return 'grey'
      return 'green' // low/medium
    }

    const loadPoints = async () => {
      try {
        const res = await fetch('/api/rt/checkins?n=60')
        const json = await res.json()
        const pts = json.data || []
        // cleanup old point markers
        pointMarkersRef.current.forEach(m => m.remove())
        pointMarkersRef.current = []

        let minLng=999, minLat=999, maxLng=-999, maxLat=-999
        pts.forEach(p => {
          const el = document.createElement('div')
          const status = classify(p)
          el.className = `marker ${status}`
          const m = new maplibregl.Marker({ element: el }).setLngLat([p.lon, p.lat]).addTo(mapObj.current)
          pointMarkersRef.current.push(m)
          minLng = Math.min(minLng, p.lon); maxLng = Math.max(maxLng, p.lon)
          minLat = Math.min(minLat, p.lat); maxLat = Math.max(maxLat, p.lat)
        })
        if (pts.length > 0) {
          mapObj.current.fitBounds([[minLng, minLat], [maxLng, maxLat]], { padding: 30, duration: 800 })
        }
      } catch (e) {
        // ignore for demo
      }
    }

    const loadVehicles = async () => {
      try {
        const res = await fetch('/api/rt/vehicles')
        const json = await res.json()
        const vehicles = json.data || []
        // cleanup old vehicle markers
        vehicleMarkersRef.current.forEach(m => m.remove())
        vehicleMarkersRef.current = []
        vehicles.forEach(v => {
          const el = document.createElement('div')
          el.className = 'marker vehicle'
          const m = new maplibregl.Marker({ element: el }).setLngLat([v.lon, v.lat]).addTo(mapObj.current)
          vehicleMarkersRef.current.push(m)
        })
      } catch (e) {
        // ignore for demo
      }
    }

    // kick off map initialization
    init()

    return () => {
      clearInterval(pointsTimerRef.current)
      clearInterval(vehiclesTimerRef.current)
      pointMarkersRef.current.forEach(m => m.remove())
      vehicleMarkersRef.current.forEach(m => m.remove())
      mapObj.current?.remove()
    }
  }, [])

  return <div className="map-root" ref={mapRef} style={{ width: '100%', height: 420 }} />
}
