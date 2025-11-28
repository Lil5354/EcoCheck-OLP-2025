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
    const [depotsRes, dumpsRes] = await Promise.all([api.getDepots(), api.getDumps()])
    if (depotsRes.ok && Array.isArray(depotsRes.data)) {
      setDepots(depotsRes.data.map(d => ({ ...d, type: 'depot' })))
    }
    if (dumpsRes.ok && Array.isArray(dumpsRes.data)) {
      setDumps(dumpsRes.data.map(d => ({ ...d, type: 'dump' })))
    }
  }

  function handleAdd(type) {
    setEditType(type)
    setEditItem({ id: '', name: '', lon: 106.7, lat: 10.78, type, address: '' })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditType(item.type)
    setEditItem(item)
    setModalOpen(true)
  }

  async function handleSave() {
    try {
      if (editItem.id) {
        // Update existing
        const res = editType === 'depot' 
          ? await api.updateDepot(editItem.id, {
              name: editItem.name,
              lon: editItem.lon,
              lat: editItem.lat,
              address: editItem.address,
            })
          : await api.updateDump(editItem.id, {
              name: editItem.name,
              lon: editItem.lon,
              lat: editItem.lat,
              address: editItem.address,
            })
        if (res.ok) {
          setModalOpen(false)
          setToast({ message: `Đã cập nhật ${editType === 'depot' ? 'trạm' : 'bãi rác'}`, type: 'success' })
          loadData()
        } else {
          setToast({ message: res.error || 'Cập nhật thất bại', type: 'error' })
        }
      } else {
        // Create new
        const res = editType === 'depot'
          ? await api.createDepot({
              name: editItem.name,
              lon: editItem.lon,
              lat: editItem.lat,
              address: editItem.address,
            })
          : await api.createDump({
              name: editItem.name,
              lon: editItem.lon,
              lat: editItem.lat,
              address: editItem.address,
            })
        if (res.ok) {
          setModalOpen(false)
          setToast({ message: `Đã tạo ${editType === 'depot' ? 'trạm' : 'bãi rác'}`, type: 'success' })
          loadData()
        } else {
          setToast({ message: res.error || 'Tạo thất bại', type: 'error' })
        }
      }
    } catch (error) {
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
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
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Vị trí</label>
            {modalOpen && editItem && (
              <MapPicker
                key={`${editItem.id || 'new'}-${editItem.lon}-${editItem.lat}`}
                center={[editItem.lon || 106.7, editItem.lat || 10.78]}
                address={editItem.address || ''}
                onPick={(coords) => setEditItem({ ...editItem, lon: coords[0], lat: coords[1] })}
                onAddressChange={(address) => setEditItem({ ...editItem, address })}
              />
            )}
          </div>
        </div>
      </FormModal>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

