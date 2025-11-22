import React, { useRef, useEffect, useState } from 'react'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

export default function MapPicker({ center = [106.7, 10.78], zoom = 12, onPick }) {
  const mapRef = useRef(null)
  const mapObj = useRef(null)
  const markerRef = useRef(null)
  const [coords, setCoords] = useState(center)

  useEffect(() => {
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
      center,
      zoom,
      attributionControl: false
    })

    markerRef.current = new maplibregl.Marker({ draggable: true })
      .setLngLat(center)
      .addTo(mapObj.current)

    markerRef.current.on('dragend', () => {
      const lngLat = markerRef.current.getLngLat()
      setCoords([lngLat.lng, lngLat.lat])
      onPick?.([lngLat.lng, lngLat.lat])
    })

    mapObj.current.on('click', (e) => {
      const { lng, lat } = e.lngLat
      markerRef.current.setLngLat([lng, lat])
      setCoords([lng, lat])
      onPick?.([lng, lat])
    })

    return () => {
      markerRef.current?.remove()
      mapObj.current?.remove()
    }
  }, [])

  return (
    <div>
      <div ref={mapRef} style={{ width: '100%', height: 300, borderRadius: 8, overflow: 'hidden', border: '1px solid #e0e0e0' }} />
      <div style={{ marginTop: 8, fontSize: 12, color: '#888' }}>
        Selected: {coords[1].toFixed(5)}, {coords[0].toFixed(5)}
      </div>
    </div>
  )
}

