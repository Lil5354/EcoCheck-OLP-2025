import React from 'react'

export default function FormModal({ open, title, children, onClose, onSubmit, submitLabel = 'Save', cancelLabel = 'Cancel' }) {
  if (!open) return null
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,.4)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: '#fff',
          borderRadius: 8,
          padding: 24,
          width: 'min(500px, 90vw)',
          boxShadow: '0 4px 12px rgba(0,0,0,.2)'
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <h3 style={{ margin: '0 0 16px', fontSize: 18, fontWeight: 600 }}>{title}</h3>
        <div style={{ marginBottom: 16 }}>{children}</div>
        <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
          <button className="btn" onClick={onClose}>
            {cancelLabel}
          </button>
          <button className="btn btn-primary" onClick={onSubmit}>
            {submitLabel}
          </button>
        </div>
      </div>
    </div>
  )
}

