/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager - Chart Components
 * Lightweight SVG charts for Dashboard
 */

import React, { useId, useState, useEffect } from 'react'

export function AreaChart({
  width=520,
  height=140,
  data=[] ,
  color='#06b6d4',
  gradient=true,
  stroke=2,
  showLabels=true,
  labelEvery=2,
  labelFormatter=(value) => {
    const num = typeof value === 'number' ? value : parseFloat(value) || 0
    return num.toLocaleString('vi-VN', { maximumFractionDigits: 0 }) + 't'
  }
}){
  const id = useId()
  // Hooks must be called unconditionally and before any early returns
  const [windowWidth, setWindowWidth] = useState(typeof window !== 'undefined' ? window.innerWidth : 1024)
  useEffect(() => {
    const handleResize = () => setWindowWidth(window.innerWidth)
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])
  const shouldShowLabels = showLabels && windowWidth >= 480

  if (!data || data.length === 0) {
    return (
      <div style={{ height, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#888', fontSize: 12 }}>
        Đang tải dữ liệu...
      </div>
    )
  }

  const w = width, h = height, pad=16
  const xs = data.map((d,i)=>i)
  const ys = data.map(d=>d.value ?? d)
  
  // Improved min/max calculation for better visualization with few data points
  const rawMin = Math.min(...ys)
  const rawMax = Math.max(...ys)
  
  // For single data point, create a visual representation with area chart
  if (data.length === 1) {
    const singleValue = Number(ys[0]) || 0
    const minValue = Math.max(0, singleValue * 0.3)
    const maxValue = singleValue * 1.2
    const range = maxValue - minValue || 1
    // Position at 70% from top (30% from bottom) for better visibility
    const yPos = h - pad - ((singleValue - minValue) / range) * (h-2*pad) * 0.7
    const xPos = pad + (w-2*pad) * 0.5
    
    // Create area path for single point - wider area for better visibility
    const areaWidth = Math.min(60, (w-2*pad) * 0.3)
    const areaPath = `M${pad},${h-pad} L${xPos-areaWidth},${h-pad} L${xPos-areaWidth},${yPos} L${xPos+areaWidth},${yPos} L${xPos+areaWidth},${h-pad} L${w-pad},${h-pad} Z`
    const linePath = `M${xPos-areaWidth},${yPos} L${xPos+areaWidth},${yPos}`
    
    return (
      <svg width="100%" height={h} viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" style={{ display: 'block' }}>
        {gradient && (
          <defs>
            <linearGradient id={id} x1="0" x2="0" y1="0" y2="1">
              <stop offset="0%" stopColor={color} stopOpacity="0.35"/>
              <stop offset="100%" stopColor={color} stopOpacity="0"/>
            </linearGradient>
          </defs>
        )}
        {gradient && <path d={areaPath} fill={`url(#${id})`} vectorEffect="non-scaling-stroke" />}
        <path d={linePath} fill="none" stroke={color} strokeWidth={stroke+2} strokeLinecap="round" vectorEffect="non-scaling-stroke"/>
        <circle cx={xPos} cy={yPos} r={stroke+3} fill={color} stroke="#fff" strokeWidth="2" vectorEffect="non-scaling-stroke"/>
        <text
          x={xPos}
          y={yPos - 15}
          textAnchor="middle"
          fontSize="12"
          fill={color}
          fontWeight="600"
        >
          {labelFormatter(singleValue)}
        </text>
        <text x={pad+4} y={h-pad-4} fontSize="9" fill="#999" textAnchor="start">
          {labelFormatter(minValue)}
        </text>
        <text x={w-pad-4} y={pad+12} fontSize="9" fill="#999" textAnchor="end">
          {labelFormatter(maxValue)}
        </text>
      </svg>
    )
  }
  
  // For multiple data points, use normal calculation
  const range = rawMax - rawMin
  const padding = range > 0 ? (range * 0.1) : (rawMax > 0 ? rawMax * 0.2 : 10)
  const min = Math.max(0, rawMin - padding)
  const max = rawMax + padding
  const nx = xs.map(x => pad + x*( (w-2*pad) / (xs.length-1 || 1) ))
  const ny = ys.map(y => h - pad - ( (y-min)/(max-min || 1) ) * (h-2*pad))
  const path = nx.map((x,i)=>`${i?'L':'M'}${x},${ny[i]}`).join(' ')
  const area = `M${pad},${h-pad} `+nx.map((x,i)=>`L${x},${ny[i]}`).join(' ')+` L${w-pad},${h-pad} Z`

  return (
    <svg width="100%" height={h} viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
      {gradient && (
        <defs>
          <linearGradient id={id} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.35"/>
            <stop offset="100%" stopColor={color} stopOpacity="0"/>
          </linearGradient>
        </defs>
      )}
      {gradient && <path d={area} fill={`url(#${id})`} vectorEffect="non-scaling-stroke" />}
      <path d={path} fill="none" stroke={color} strokeWidth={stroke} strokeLinejoin="round" strokeLinecap="round" vectorEffect="non-scaling-stroke"/>
      {nx.map((x, i) => (
        <circle key={i} cx={x} cy={ny[i]} r={stroke + 1} fill={color} stroke="#fff" strokeWidth="1" vectorEffect="non-scaling-stroke" />
      ))}
      {/* Data Labels */}
      {shouldShowLabels && nx.map((x, i) => {
        // Show label every N points to avoid clutter
        if (i % labelEvery !== 0) return null
        const labelText = labelFormatter(ys[i], i)
        return (
          <text
            key={`label-${i}`}
            x={x}
            y={ny[i] - 8}
            textAnchor="middle"
            fontSize="10"
            fill={color}
            fontWeight="500"
            className="chart-label"
          >
            {labelText}
          </text>
        )
      })}
    </svg>
  )
}

export function DonutChart({
  size=140,
  segments={},
  colors=['#22c55e','#06b6d4','#f59e0b','#ef4444'],
  showLabels=true,
  labelPosition='outside',
  minAngleForLabel=0.15, // radians (~8.6 degrees)
  numberFormatter=(value) => value.toLocaleString('vi-VN', { maximumFractionDigits: 1 }) + 't'
}){
  const entries = Object.entries(segments).filter(([k, v]) => v != null && (typeof v === 'number' ? v > 0 : parseFloat(v) > 0))
  const total = entries.reduce((s,[,v])=>s+(typeof v === 'number' ? v : parseFloat(v) || 0),0)
  
  // If no data, show empty state
  if (total === 0 || entries.length === 0) {
    return (
      <div style={{ width: size, height: size, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#888', fontSize: 12 }}>
        <div style={{ textAlign: 'center' }}>
          <div>Tổng 0t</div>
        </div>
      </div>
    )
  }
  
  const r = size/2 - 10
  const labelRadius = labelPosition === 'outside' ? r + 20 : r - 15
  let acc = 0

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <g transform={`translate(${size/2} ${size/2})`}>
        {entries.map(([k,v],i)=>{
          const a1 = (acc/total)*Math.PI*2 - Math.PI/2
          acc += v
          const a2 = (acc/total)*Math.PI*2 - Math.PI/2
          const x1 = Math.cos(a1)*r, y1 = Math.sin(a1)*r
          const x2 = Math.cos(a2)*r, y2 = Math.sin(a2)*r
          const large = (a2-a1) > Math.PI ? 1 : 0
          const d = `M ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2}`

          // Calculate mid-angle for label positioning
          const midAngle = (a1 + a2) / 2
          const angleSpan = a2 - a1
          const shouldShowLabel = showLabels && angleSpan >= minAngleForLabel

          const labelX = Math.cos(midAngle) * labelRadius
          const labelY = Math.sin(midAngle) * labelRadius
          const percentage = ((v / total) * 100).toFixed(1)
          const valueText = numberFormatter(v)

          return (
            <React.Fragment key={k}>
              <path d={d} stroke={colors[i%colors.length]} strokeWidth={10} fill="none"/>
              {shouldShowLabel && labelPosition === 'outside' && (
                <>
                  {/* Leader line */}
                  <line
                    x1={Math.cos(midAngle) * (r + 2)}
                    y1={Math.sin(midAngle) * (r + 2)}
                    x2={labelX - Math.cos(midAngle) * 5}
                    y2={labelY - Math.sin(midAngle) * 5}
                    stroke={colors[i%colors.length]}
                    strokeWidth="1"
                    opacity="0.5"
                  />
                  {/* Label text */}
                  <text
                    x={labelX}
                    y={labelY - 4}
                    textAnchor="middle"
                    fontSize="10"
                    fill={colors[i%colors.length]}
                    fontWeight="600"
                    className="chart-label"
                  >
                    {percentage}%
                  </text>
                  <text
                    x={labelX}
                    y={labelY + 8}
                    textAnchor="middle"
                    fontSize="9"
                    fill="var(--muted)"
                    className="chart-label"
                  >
                    {valueText}
                  </text>
                </>
              )}
              {shouldShowLabel && labelPosition === 'inside' && (
                <text
                  x={Math.cos(midAngle) * (r - 15)}
                  y={Math.sin(midAngle) * (r - 15)}
                  textAnchor="middle"
                  fontSize="10"
                  fill="#fff"
                  fontWeight="600"
                  className="chart-label"
                >
                  {percentage}%
                </text>
              )}
            </React.Fragment>
          )
        })}
        <circle r={r-12} fill="transparent" stroke="rgba(255,255,255,.08)" strokeWidth="1"/>

        {/* Center total */}
        {showLabels && (
          <>
            <text
              x="0"
              y="-6"
              textAnchor="middle"
              fontSize="11"
              fill="var(--muted)"
              fontWeight="400"
            >
              Tổng
            </text>
            <text
              x="0"
              y="8"
              textAnchor="middle"
              fontSize="16"
              fill="var(--text)"
              fontWeight="600"
            >
              {numberFormatter(total)}
            </text>
          </>
        )}
      </g>
    </svg>
  )
}

export function Legend({ items }){
  return (
    <div className="legend">
      {items.map((it,i)=> (
        <div key={i} className="legend-item">
          <span className="legend-color" style={{background:it.color}} />
          <span className="legend-label">{it.label}</span>
        </div>
      ))}
    </div>
  )
}

