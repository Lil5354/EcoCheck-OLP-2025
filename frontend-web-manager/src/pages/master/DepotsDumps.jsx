import React, { useState } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import MapPicker from '../../components/common/MapPicker.jsx'
import Toast from '../../components/common/Toast.jsx'

export default function DepotsDumps() {
  const [depots, setDepots] = useState([
    { id: 'D1', name: 'Main Depot', lon: 106.7, lat: 10.78, type: 'depot' }
  ])
  const [dumps, setDumps] = useState([
    { id: 'DU1', name: 'Transfer Station 1', lon: 106.72, lat: 10.81, type: 'dump' }
  ])
  const [modalOpen, setModalOpen] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [editType, setEditType] = useState('depot')
  const [toast, setToast] = useState(null)

  function handleAdd(type) {
    setEditType(type)
    setEditItem({ id: '', name: '', lon: 106.7, lat: 10.78, type })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditType(item.type)
    setEditItem(item)
    setModalOpen(true)
  }

  function handleSave() {
    setModalOpen(false)
    setToast({ message: `Đã lưu ${editType === 'depot' ? 'trạm' : 'bãi rác'}`, type: 'success' })
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

