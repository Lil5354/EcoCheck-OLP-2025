/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 */

import React from 'react'

export default function KPI({ label, value, unit = '', color = 'var(--primary)' }) {
  return (
    <div style={{ textAlign: 'left' }}>
      <div style={{ fontSize: 12, color: '#888', marginBottom: 4 }}>{label}</div>
      <div style={{ fontSize: 24, fontWeight: 600, color }}>
        {value}
        {unit && <span style={{ fontSize: 14, marginLeft: 4 }}>{unit}</span>}
      </div>
    </div>
  )
}

