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
    if (res && res.ok && Array.isArray(res.data)) {
      setFleet(res.data)
    } else if (Array.isArray(res)) {
      // Handle legacy format (direct array)
      setFleet(res)
    }
  }

  function handleAdd() {
    setEditItem({ id: '', plate: '', type: 'compactor', capacity: 3000, types: ['household'], status: 'ready' })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditItem(item)
    setModalOpen(true)
  }

  async function handleSave() {
    try {
      if (!editItem?.plate || !editItem?.type || !editItem?.capacity) {
        setToast({ message: 'Vui lòng điền đầy đủ thông tin', type: 'error' })
        return
      }

      const vehicleData = {
        plate: editItem.plate,
        type: editItem.type,
        capacity: editItem.capacity,
        types: editItem.types || [],
        status: editItem.status || 'available',
        depot_id: editItem.depot_id || null
      }

      let res
      if (editItem.id && editItem.id !== '') {
        // Update
        res = await api.updateVehicle(editItem.id, vehicleData)
      } else {
        // Create
        res = await api.createVehicle(vehicleData)
      }

      if (res && res.ok) {
        setModalOpen(false)
        setToast({ message: 'Đã lưu phương tiện', type: 'success' })
        await loadFleet()
      } else {
        setToast({ message: res?.error || 'Lỗi khi lưu phương tiện', type: 'error' })
      }
    } catch (error) {
      console.error('Error saving vehicle:', error)
      setToast({ message: 'Lỗi khi lưu: ' + error.message, type: 'error' })
    }
  }

  const columns = [
    { key: 'plate', label: 'Biển số' },
    { key: 'type', label: 'Loại' },
    { key: 'capacity', label: 'Sức chứa (kg)' },
    { key: 'status', label: 'Trạng thái' },
    {
      key: 'action',
      label: 'Hành động',
      render: (r) => (
        <button className="btn btn-sm" onClick={() => handleEdit(r)}>
          Sửa
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
              <h1 style={{ fontSize: 24, fontWeight: 600 }}>Quản lý đội xe (CN14)</h1>
              <button className="btn btn-primary" onClick={handleAdd}>
                Thêm phương tiện
              </button>
            </div>
            <div className="card">
              <Table columns={columns} data={fleet} emptyText="Không có phương tiện" />
            </div>
          </div>
        </main>
      </div>
      <FormModal open={modalOpen} title="Phương tiện" onClose={() => setModalOpen(false)} onSubmit={handleSave}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Biển số</label>
            <input
              type="text"
              value={editItem?.plate || ''}
              onChange={(e) => setEditItem({ ...editItem, plate: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Loại</label>
            <select
              value={editItem?.type || 'compactor'}
              onChange={(e) => setEditItem({ ...editItem, type: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            >
              <option value="compactor">Xe ép rác</option>
              <option value="mini-truck">Xe tải nhỏ</option>
              <option value="electric-trike">Xe ba bánh điện</option>
            </select>
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Sức chứa (kg)</label>
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

