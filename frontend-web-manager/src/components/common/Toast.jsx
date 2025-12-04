/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 */

import React, { useEffect } from 'react'

export default function Toast({ message, type = 'info', duration = 3000, onClose }) {
  useEffect(() => {
    if (duration) {
      const t = setTimeout(onClose, duration)
      return () => clearTimeout(t)
    }
  }, [duration, onClose])

  const bg = type === 'success' ? '#2ed8b6' : type === 'error' ? '#ef4444' : '#448aff'
  return (
    <div
      style={{
        position: 'fixed',
        bottom: 24,
        right: 24,
        background: bg,
        color: '#fff',
        padding: '12px 20px',
        borderRadius: 8,
        boxShadow: '0 4px 12px rgba(0,0,0,.2)',
        zIndex: 9999,
        fontSize: 14,
        fontWeight: 500,
        maxWidth: 320
      }}
    >
      {message}
    </div>
  )
}

