/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 */

import React from 'react'

export default function Table({ columns, data, onRowClick, emptyText = 'Không có dữ liệu' }) {
  // Validate inputs
  if (!columns || !Array.isArray(columns) || columns.length === 0) {
    console.error('Table: No columns defined');
    return <div style={{ textAlign: 'center', padding: '40px 0', color: '#f44336' }}>Lỗi: Không có cột nào được định nghĩa</div>
  }

  if (!data || !Array.isArray(data)) {
    console.error('Table: Invalid data prop', data);
    return <div style={{ textAlign: 'center', padding: '40px 0', color: '#f44336' }}>Lỗi: Dữ liệu không hợp lệ</div>
  }

  if (data.length === 0) {
    return <div style={{ textAlign: 'center', padding: '40px 0', color: '#888' }}>{emptyText}</div>
  }

  // Safe render function with error handling
  const safeRender = (renderFn, row, fallback) => {
    try {
      if (renderFn && typeof renderFn === 'function') {
        const result = renderFn(row);
        // Ensure result is valid React element or primitive
        if (result === null || result === undefined) {
          return fallback ?? '-';
        }
        return result;
      }
      return fallback ?? '-';
    } catch (error) {
      console.error('Error rendering table cell:', error, { row, renderFn });
      return <span style={{ color: '#f44336', fontSize: 12 }}>Error</span>
    }
  }

  return (
    <div style={{ overflowX: 'auto', width: '100%' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 14 }}>
        <thead>
          <tr style={{ borderBottom: '1px solid #e0e0e0', backgroundColor: '#fafafa' }}>
            {columns.map(c => (
              <th 
                key={c.key} 
                style={{ 
                  textAlign: 'left', 
                  padding: '12px 8px', 
                  fontWeight: 600, 
                  color: '#555',
                  position: 'sticky',
                  top: 0,
                  backgroundColor: '#fafafa'
                }}
              >
                {c.label || c.key}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, idx) => {
            // Generate stable key
            const rowKey = row.id || row.schedule_id || `row-${idx}`;
            return (
              <tr
                key={rowKey}
                onClick={() => onRowClick?.(row)}
                style={{
                  borderBottom: '1px solid #f0f0f0',
                  cursor: onRowClick ? 'pointer' : 'default',
                  transition: 'background .15s'
                }}
                onMouseEnter={(e) => {
                  if (onRowClick) {
                    e.currentTarget.style.background = '#f9f9f9';
                  }
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                }}
              >
                {columns.map(c => {
                  const cellKey = `${rowKey}-${c.key}`;
                  return (
                    <td key={cellKey} style={{ padding: '10px 8px', color: '#333' }}>
                      {safeRender(c.render, row, row[c.key])}
                    </td>
                  );
                })}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  )
}

