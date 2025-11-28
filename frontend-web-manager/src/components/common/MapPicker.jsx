import React, { useRef, useEffect, useState, useCallback } from 'react'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

// OpenStreetMap Nominatim API for geocoding (mã nguồn mở, miễn phí)
const NOMINATIM_BASE_URL = 'https://nominatim.openstreetmap.org'

export default function MapPicker({ center = [106.7, 10.78], zoom = 12, onPick, address: initialAddress = '', onAddressChange }) {
  const mapRef = useRef(null)
  const mapObj = useRef(null)
  const markerRef = useRef(null)
  const [coords, setCoords] = useState(center)
  const [address, setAddress] = useState(initialAddress)
  
  // Update address when prop changes
  useEffect(() => {
    if (initialAddress && initialAddress !== address) {
      setAddress(initialAddress)
    }
  }, [initialAddress])
  const [suggestions, setSuggestions] = useState([])
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [isGeocoding, setIsGeocoding] = useState(false)
  const searchTimeoutRef = useRef(null)
  const suggestionsRef = useRef(null)

  // Geocoding: Địa chỉ → Tọa độ (sử dụng OpenStreetMap Nominatim)
  const geocodeAddress = useCallback(async (query) => {
    if (!query || query.trim().length < 3) {
      setSuggestions([])
      return
    }

    try {
      setIsGeocoding(true)
      const url = `${NOMINATIM_BASE_URL}/search?format=json&q=${encodeURIComponent(query)}&limit=5&countrycodes=vn&accept-language=vi`
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'EcoCheck-WebManager/1.0'
        }
      })
      
      if (!response.ok) {
        console.warn('[MapPicker] Geocoding failed:', response.status)
        return
      }

      const data = await response.json()
      setSuggestions(data.map(item => ({
        display_name: item.display_name,
        lat: parseFloat(item.lat),
        lon: parseFloat(item.lon),
        place_id: item.place_id
      })))
      setShowSuggestions(true)
    } catch (error) {
      console.error('[MapPicker] Geocoding error:', error)
      setSuggestions([])
    } finally {
      setIsGeocoding(false)
    }
  }, [])

  // Reverse Geocoding: Tọa độ → Địa chỉ
  const reverseGeocode = useCallback(async (lng, lat, skipIfAddressExists = false) => {
    // Skip if address is already set and user might have typed it manually
    if (skipIfAddressExists && address && address.trim().length > 0) {
      return
    }

    try {
      const url = `${NOMINATIM_BASE_URL}/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1&accept-language=vi`
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'EcoCheck-WebManager/1.0'
        }
      })
      
      if (!response.ok) {
        console.warn('[MapPicker] Reverse geocoding failed:', response.status)
        return
      }

      const data = await response.json()
      if (data.display_name) {
        const newAddress = data.display_name
        setAddress(newAddress)
        onAddressChange?.(newAddress)
      }
    } catch (error) {
      console.error('[MapPicker] Reverse geocoding error:', error)
    }
  }, [onAddressChange, address])

  // Handle address input change with debounce
  const handleAddressChange = useCallback((e) => {
    const value = e.target.value
    setAddress(value)
    onAddressChange?.(value)
    
    // Clear previous timeout
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current)
    }

    // Debounce geocoding search
    if (value.trim().length >= 3) {
      searchTimeoutRef.current = setTimeout(() => {
        geocodeAddress(value)
      }, 500)
    } else {
      setSuggestions([])
      setShowSuggestions(false)
    }
  }, [geocodeAddress, onAddressChange])

  // Handle suggestion selection
  const handleSelectSuggestion = useCallback((suggestion) => {
    const newCoords = [suggestion.lon, suggestion.lat] // [longitude, latitude]
    console.log('[MapPicker] Selected suggestion:', {
      address: suggestion.display_name,
      coords: newCoords,
      lon: suggestion.lon,
      lat: suggestion.lat
    })
    
    setAddress(suggestion.display_name)
    setCoords(newCoords)
    setSuggestions([])
    setShowSuggestions(false)
    
    // Update map - ensure map is loaded first
    if (mapObj.current && markerRef.current) {
      const updateMap = () => {
        console.log('[MapPicker] Updating map to:', newCoords)
        mapObj.current.flyTo({ 
          center: newCoords, 
          zoom: 15,
          duration: 1000
        })
        markerRef.current.setLngLat(newCoords)
      }
      
      if (mapObj.current.loaded()) {
        // Map is ready, update immediately
        updateMap()
      } else {
        // Wait for map to load
        mapObj.current.once('load', updateMap)
      }
    }
    
    // Notify parent
    onPick?.(newCoords)
    onAddressChange?.(suggestion.display_name)
  }, [onPick, onAddressChange])

  // Update coordinates when center prop changes (for edit mode)
  useEffect(() => {
    if (!mapObj.current || !markerRef.current || !center || center.length !== 2) {
      return
    }

    const [lng, lat] = center // [longitude, latitude]
    
    // Only update if coordinates actually changed significantly
    const hasChanged = !coords || coords.length !== 2 || 
      Math.abs(lng - coords[0]) > 0.00001 || 
      Math.abs(lat - coords[1]) > 0.00001

    if (hasChanged) {
      console.log('[MapPicker] Center prop changed, updating map:', { 
        old: coords, 
        new: center,
        lng,
        lat
      })
      
      setCoords(center)
      
      const updateMap = () => {
        if (markerRef.current && mapObj.current) {
          markerRef.current.setLngLat(center)
          mapObj.current.flyTo({ 
            center, 
            zoom: 15, 
            duration: 800 
          })
        }
      }

      if (mapObj.current.loaded()) {
        updateMap()
      } else {
        mapObj.current.once('load', updateMap)
      }
    }
  }, [center])

  // Initialize map
  useEffect(() => {
    if (mapObj.current) return

    const initMap = () => {
      if (!mapRef.current) {
        setTimeout(initMap, 100)
        return
      }

      const w = mapRef.current.clientWidth
      const h = mapRef.current.clientHeight
      if (w === 0 || h === 0) {
        setTimeout(initMap, 100)
        return
      }

      try {
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

        mapObj.current.addControl(new maplibregl.NavigationControl(), 'top-right')

        // Create draggable marker
        markerRef.current = new maplibregl.Marker({ draggable: true })
          .setLngLat(center)
          .addTo(mapObj.current)

        // Handle marker drag
        markerRef.current.on('dragend', async () => {
          const lngLat = markerRef.current.getLngLat()
          const newCoords = [lngLat.lng, lngLat.lat] // [longitude, latitude]
          setCoords(newCoords)
          onPick?.(newCoords)
          // Reverse geocode to get address (skip if address already exists)
          await reverseGeocode(lngLat.lng, lngLat.lat, true)
        })

        // Handle map click
        mapObj.current.on('click', async (e) => {
          const { lng, lat } = e.lngLat
          const newCoords = [lng, lat] // [longitude, latitude]
          markerRef.current.setLngLat(newCoords)
          setCoords(newCoords)
          onPick?.(newCoords)
          // Reverse geocode to get address (skip if address already exists)
          await reverseGeocode(lng, lat, true)
        })

        // Load initial address if coordinates are provided and address is empty
        mapObj.current.once('load', async () => {
          if (coords && coords[0] && coords[1] && (!address || address.trim().length === 0)) {
            await reverseGeocode(coords[0], coords[1], false)
          }
        })
      } catch (error) {
        console.error('[MapPicker] Map initialization error:', error)
      }
    }

    initMap()

    return () => {
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current)
      }
      if (markerRef.current) {
        try { markerRef.current.remove() } catch (e) { void e }
      }
      if (mapObj.current) {
        try { mapObj.current.remove() } catch (e) { void e }
        mapObj.current = null
      }
    }
  }, [])

  // Handle click outside suggestions
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (suggestionsRef.current && !suggestionsRef.current.contains(event.target)) {
        setShowSuggestions(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  return (
    <div>
      <div style={{ position: 'relative', marginBottom: 8 }}>
        <input
          type="text"
          value={address}
          onChange={handleAddressChange}
          placeholder="Nhập địa chỉ để tìm kiếm..."
          style={{
            width: '100%',
            padding: '8px 12px',
            border: '1px solid #ccc',
            borderRadius: 6,
            fontSize: 14
          }}
        />
        {isGeocoding && (
          <div style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', fontSize: 12, color: '#888' }}>
            Đang tìm...
          </div>
        )}
        {showSuggestions && suggestions.length > 0 && (
          <div
            ref={suggestionsRef}
            style={{
              position: 'absolute',
              top: '100%',
              left: 0,
              right: 0,
              marginTop: 4,
              backgroundColor: 'white',
              border: '1px solid #ccc',
              borderRadius: 6,
              boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
              maxHeight: 200,
              overflowY: 'auto',
              zIndex: 1000
            }}
          >
            {suggestions.map((suggestion, idx) => (
              <div
                key={suggestion.place_id || idx}
                onClick={() => handleSelectSuggestion(suggestion)}
                style={{
                  padding: '10px 12px',
                  cursor: 'pointer',
                  borderBottom: idx < suggestions.length - 1 ? '1px solid #eee' : 'none',
                  fontSize: 13,
                  color: '#333'
                }}
                onMouseEnter={(e) => e.target.style.backgroundColor = '#f5f5f5'}
                onMouseLeave={(e) => e.target.style.backgroundColor = 'white'}
              >
                {suggestion.display_name}
              </div>
            ))}
          </div>
        )}
      </div>
      <div 
        ref={mapRef} 
        style={{ 
          width: '100%', 
          height: 300, 
          borderRadius: 8, 
          overflow: 'hidden', 
          border: '1px solid #e0e0e0',
          backgroundColor: '#eef2f7'
        }} 
      />
      <div style={{ marginTop: 8, fontSize: 12, color: '#888' }}>
        <div style={{ marginBottom: 4 }}>
          <strong>Tọa độ:</strong> {coords[1]?.toFixed(5) || '0.00000'} (Vĩ độ), {coords[0]?.toFixed(5) || '0.00000'} (Kinh độ)
        </div>
        <span style={{ fontSize: 11, color: '#aaa' }}>
          💡 Nhấp vào bản đồ hoặc kéo marker để chọn vị trí. Nhập địa chỉ để tìm kiếm tự động.
        </span>
      </div>
    </div>
  )
}

