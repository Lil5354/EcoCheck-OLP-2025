import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import MapPicker from '../../components/common/MapPicker.jsx'
import Toast from '../../components/common/Toast.jsx'
import api from '../../lib/api.js'

export default function DepotsDumps() {
  const [depots, setDepots] = useState([])
  const [dumps, setDumps] = useState([])
  const [modalOpen, setModalOpen] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [editType, setEditType] = useState('depot')
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    try {
      const [d, du] = await Promise.all([
        api.getDepots(),
        api.getDumps()
      ])
      
      if (d.ok && Array.isArray(d.data)) {
        setDepots(d.data.map(item => ({ ...item, type: 'depot' })))
      }
      if (du.ok && Array.isArray(du.data)) {
        setDumps(du.data.map(item => ({ ...item, type: 'dump' })))
      }
    } catch (error) {
      console.error('Error loading data:', error)
      setToast({ message: 'Lỗi khi tải dữ liệu', type: 'error' })
    }
  }

  function handleAdd(type) {
    setEditType(type)
    setEditItem({ id: '', name: '', lon: 106.7, lat: 10.78, type })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditType(item.type)
    setEditItem({ ...item })
    setModalOpen(true)
  }

  async function handleSave() {
    try {
      if (!editItem?.name || editItem?.lon === undefined || editItem?.lat === undefined) {
        setToast({ message: 'Vui lòng điền đầy đủ thông tin', type: 'error' })
        return
      }

      const data = {
        name: editItem.name,
        lon: editItem.lon,
        lat: editItem.lat,
        address: editItem.address || null
      }

      let res
      if (editItem.id && editItem.id !== '') {
        // Update
        if (editType === 'depot') {
          res = await api.updateDepot(editItem.id, data)
        } else {
          res = await api.updateDump(editItem.id, data)
        }
      } else {
        // Create
        if (editType === 'depot') {
          res = await api.createDepot(data)
        } else {
          res = await api.createDump(data)
        }
      }

      if (res && res.ok) {
        setModalOpen(false)
        setToast({ message: `Đã lưu ${editType === 'depot' ? 'trạm' : 'bãi rác'}`, type: 'success' })
        await loadData()
      } else {
        setToast({ message: res?.error || `Lỗi khi lưu ${editType === 'depot' ? 'trạm' : 'bãi rác'}`, type: 'error' })
      }
    } catch (error) {
      console.error('Error saving:', error)
      setToast({ message: 'Lỗi khi lưu: ' + error.message, type: 'error' })
    }
  }

  const columns = [
    { key: 'name', label: 'Tên' },
    { key: 'lon', label: 'Kinh độ', render: (r) => r.lon.toFixed(5) },
    { key: 'lat', label: 'Vĩ độ', render: (r) => r.lat.toFixed(5) },
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
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Trạm & Bãi rác (CN14)</h1>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
              <div className="card">
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                  <h2>Trạm</h2>
                  <button className="btn btn-sm btn-primary" onClick={() => handleAdd('depot')}>
                    Thêm trạm
                  </button>
                </div>
                <Table columns={columns} data={depots} emptyText="Không có trạm" />
              </div>
              <div className="card">
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                  <h2>Bãi rác / Trạm trung chuyển</h2>
                  <button className="btn btn-sm btn-primary" onClick={() => handleAdd('dump')}>
                    Thêm bãi rác
                  </button>
                </div>
                <Table columns={columns} data={dumps} emptyText="Không có bãi rác" />
              </div>
            </div>
          </div>
        </main>
      </div>
      <FormModal open={modalOpen} title={editType === 'depot' ? 'Trạm' : 'Bãi rác'} onClose={() => setModalOpen(false)} onSubmit={handleSave}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Tên</label>
            <input
              type="text"
              value={editItem?.name || ''}
              onChange={(e) => setEditItem({ ...editItem, name: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Địa chỉ</label>
            <input
              type="text"
              value={editItem?.address || ''}
              onChange={(e) => setEditItem({ ...editItem, address: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Vị trí</label>
            <MapPicker
              center={[editItem?.lon || 106.7, editItem?.lat || 10.78]}
              onPick={(coords) => setEditItem({ ...editItem, lon: coords[0], lat: coords[1] })}
            />
          </div>
        </div>
      </FormModal>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

