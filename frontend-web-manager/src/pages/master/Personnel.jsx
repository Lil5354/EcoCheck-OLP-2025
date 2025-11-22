import React, { useState } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import Toast from '../../components/common/Toast.jsx'

export default function Personnel() {
  const [personnel, setPersonnel] = useState([
    { id: 'U1', name: 'Nguyen Van A', role: 'driver', status: 'active' },
    { id: 'U2', name: 'Tran Thi B', role: 'collector', status: 'active' },
    { id: 'U3', name: 'Le Van C', role: 'manager', status: 'active' }
  ])
  const [modalOpen, setModalOpen] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [toast, setToast] = useState(null)

  function handleAdd() {
    setEditItem({ id: '', name: '', role: 'driver', status: 'active' })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditItem(item)
    setModalOpen(true)
  }

  function handleSave() {
    setModalOpen(false)
    setToast({ message: 'Personnel saved', type: 'success' })
  }

  const columns = [
    { key: 'name', label: 'Name' },
    { key: 'role', label: 'Role' },
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
              <h1 style={{ fontSize: 24, fontWeight: 600 }}>Personnel (CN14)</h1>
              <button className="btn btn-primary" onClick={handleAdd}>
                Add Personnel
              </button>
            </div>
            <div className="card">
              <Table columns={columns} data={personnel} emptyText="No personnel" />
            </div>
          </div>
        </main>
      </div>
      <FormModal open={modalOpen} title="Personnel" onClose={() => setModalOpen(false)} onSubmit={handleSave}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Name</label>
            <input
              type="text"
              value={editItem?.name || ''}
              onChange={(e) => setEditItem({ ...editItem, name: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Role</label>
            <select
              value={editItem?.role || 'driver'}
              onChange={(e) => setEditItem({ ...editItem, role: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            >
              <option value="driver">Driver</option>
              <option value="collector">Collector</option>
              <option value="manager">Manager</option>
              <option value="dispatcher">Dispatcher</option>
            </select>
          </div>
        </div>
      </FormModal>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

