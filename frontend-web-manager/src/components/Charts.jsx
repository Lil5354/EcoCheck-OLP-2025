/* Lightweight SVG charts for Dashboard */
import React from 'react'

export function AreaChart({ width=520, height=140, data=[] , color='#06b6d4', gradient=true, stroke=2 }){
  if (!data || data.length === 0) return <div className="skeleton" style={{height}}/>
  const w = width, h = height, pad=16
  const xs = data.map((d,i)=>i)
  const ys = data.map(d=>d.value ?? d)
  const min = Math.min(...ys)
  const max = Math.max(...ys)
  const nx = xs.map(x => pad + x*( (w-2*pad) / (xs.length-1 || 1) ))
  const ny = ys.map(y => h - pad - ( (y-min)/(max-min || 1) ) * (h-2*pad))
  const path = nx.map((x,i)=>`${i?'L':'M'}${x},${ny[i]}`).join(' ')
  const area = `M${pad},${h-pad} `+nx.map((x,i)=>`L${x},${ny[i]}`).join(' ')+` L${w-pad},${h-pad} Z`
  const id = 'g'+Math.random().toString(36).slice(2,7)
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
      {gradient && (
        <defs>
          <linearGradient id={id} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.35"/>
            <stop offset="100%" stopColor={color} stopOpacity="0"/>
          </linearGradient>
        </defs>
      )}
      {gradient && <path d={area} fill={`url(#${id})`} />}
      <path d={path} fill="none" stroke={color} strokeWidth={stroke} strokeLinejoin="round" strokeLinecap="round"/>
    </svg>
  )
}

export function DonutChart({ size=140, segments={}, colors=['#22c55e','#06b6d4','#f59e0b','#ef4444'] }){
  const entries = Object.entries(segments)
  const total = entries.reduce((s,[,v])=>s+v,0)
  const r = size/2 - 10
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
          return <path key={k} d={d} stroke={colors[i%colors.length]} strokeWidth={10} fill="none"/>
        })}
        <circle r={r-12} fill="transparent" stroke="rgba(255,255,255,.08)" strokeWidth="1"/>
      </g>
    </svg>
  )
}

export function Legend({ items }){
  return (
    <div style={{display:'flex', gap:12, flexWrap:'wrap'}}>
      {items.map((it,i)=> (
        <div key={i} style={{display:'flex', alignItems:'center', gap:8}}>
          <span style={{width:10,height:10,borderRadius:2,background:it.color,display:'inline-block'}} />
          <span className="muted">{it.label}</span>
        </div>
      ))}
    </div>
  )
}

