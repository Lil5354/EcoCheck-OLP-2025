/* Realtime Map using MapLibre GL */
import React, { useEffect, useRef } from 'react'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

export default function RealtimeMap() {
  const mapRef = useRef(null)
  const mapObj = useRef(null)
  const markersRef = useRef([])
  const timerRef = useRef(null)

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
      console.log('[RealtimeMap] init with size', w, 'x', h)

      console.log('[RealtimeMap] creating map...')
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
        attributionControl: false
      })

      mapObj.current.on('error', (e) => {
        console.error('[RealtimeMap] map error:', e?.error || e)
      })

      mapObj.current.addControl(new maplibregl.NavigationControl({ showCompass:false }), 'top-right')

      // Ensure proper sizing when first loaded
      mapObj.current.on('load', () => {
        try { mapObj.current?.resize() } catch (err) { void err }
      })

      load() // first data load after map is ready
      timerRef.current = setInterval(load, 10000)
    }

    const load = async () => {
      try {
        const res = await fetch('/api/rt/checkins?n=45')
        const json = await res.json()
        const pts = json.data || []
        // cleanup old markers
        markersRef.current.forEach(m => m.remove())
        markersRef.current = []

        let minLng=999, minLat=999, maxLng=-999, maxLat=-999
        pts.forEach(p => {
          const el = document.createElement('div')
          el.className = `marker ${p.type}`
          const m = new maplibregl.Marker({ element: el }).setLngLat([p.lon, p.lat]).addTo(mapObj.current)
          markersRef.current.push(m)
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

    // kick off map initialization
    init()

    return () => {
      clearInterval(timerRef.current)
      markersRef.current.forEach(m => m.remove())
      mapObj.current?.remove()
    }
  }, [])

  return <div className="map-root" ref={mapRef} style={{ width: '100%', height: 420 }} />
}

