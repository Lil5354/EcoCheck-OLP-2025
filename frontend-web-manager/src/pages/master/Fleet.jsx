import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import Toast from '../../components/common/Toast.jsx'
import api from '../../lib/api.js'

export default function Fleet() {
  const [fleet, setFleet] = useState([])
  const [modalOpen, setModalOpen] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadFleet()
  }, [])

  async function loadFleet() {
    const res = await api.getFleet()
    if (res.ok) setFleet(res.data)
  }

  function handleAdd() {
    setEditItem({ id: '', plate: '', type: 'compactor', capacity: 3000, types: ['household'], status: 'ready' })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditItem(item)
    setModalOpen(true)
  }

  function handleSave() {
    // mock save
    setModalOpen(false)
    setToast({ message: 'Vehicle saved', type: 'success' })
    loadFleet()
  }

  const columns = [
    { key: 'plate', label: 'Plate' },
    { key: 'type', label: 'Type' },
    { key: 'capacity', label: 'Capacity (kg)' },
    { key: 'status', label: 'Status' },
    {
      key: 'action',
      label: 'Action',
      render: (r) => (
        <button className="btn btn-sm" onClick={() => handleEdit(r)}>
          Edit
        </button>
      )
    }
  ]

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
              <h1 style={{ fontSize: 24, fontWeight: 600 }}>Fleet Management (CN14)</h1>
              <button className="btn btn-primary" onClick={handleAdd}>
                Add Vehicle
              </button>
            </div>
            <div className="card">
              <Table columns={columns} data={fleet} emptyText="No vehicles" />
            </div>
          </div>
        </main>
      </div>
      <FormModal open={modalOpen} title="Vehicle" onClose={() => setModalOpen(false)} onSubmit={handleSave}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Plate</label>
            <input
              type="text"
              value={editItem?.plate || ''}
              onChange={(e) => setEditItem({ ...editItem, plate: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Type</label>
            <select
              value={editItem?.type || 'compactor'}
              onChange={(e) => setEditItem({ ...editItem, type: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            >
              <option value="compactor">Compactor</option>
              <option value="mini-truck">Mini Truck</option>
              <option value="electric-trike">Electric Trike</option>
            </select>
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Capacity (kg)</label>
            <input
              type="number"
              value={editItem?.capacity || 0}
              onChange={(e) => setEditItem({ ...editItem, capacity: Number(e.target.value) })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
        </div>
      </FormModal>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

