import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import MapPicker from '../../components/common/MapPicker.jsx'
import Toast from '../../components/common/Toast.jsx'
import api from '../../lib/api.js'

export default function DepotsDumps() {
  const [depots, setDepots] = useState([])
  const [modalOpen, setModalOpen] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [toast, setToast] = useState(null)
  const [selectedDistrict, setSelectedDistrict] = useState('')
  const [depotDistricts, setDepotDistricts] = useState([])

  useEffect(() => {
    loadData()
  }, [])

  useEffect(() => {
    if (depots.length > 0) {
      // Extract unique districts
      const districts = [...new Set(depots.map(d => d.district).filter(Boolean))]
      setDepotDistricts(districts.sort())
    }
  }, [depots])

  async function loadData() {
    try {
      const depotsRes = await api.getDepots()
      if (depotsRes.ok && Array.isArray(depotsRes.data)) {
        setDepots(depotsRes.data)
      } else {
        setToast({ message: 'Không thể tải danh sách trạm', type: 'error' })
      }
    } catch (error) {
      console.error('Load depots error:', error)
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
    }
  }

  // Helper function to extract district from address
  function extractDistrictFromAddress(address) {
    if (!address) return null
    const match = address.match(/Quận\s*(\d+)|Q\.?\s*(\d+)/i)
    if (match) return `Quận ${match[1] || match[2]}`
    const districts = [
      'Quận 1', 'Quận 2', 'Quận 3', 'Quận 4', 'Quận 5',
      'Quận 6', 'Quận 7', 'Quận 8', 'Quận 9', 'Quận 10',
      'Quận 11', 'Quận 12', 'Bình Thạnh', 'Tân Bình', 'Tân Phú',
      'Phú Nhuận', 'Gò Vấp', 'Bình Tân', 'Thủ Đức'
    ]
    for (const dist of districts) {
      if (address.includes(dist)) return dist
    }
    return null
  }

  // Filter depots by district
  const filteredDepots = selectedDistrict
    ? depots.filter(d => {
        const depotDistrict = d.district || extractDistrictFromAddress(d.address || '')
        return depotDistrict === selectedDistrict
      })
    : depots

  function handleAdd() {
    setEditItem({ id: '', name: '', lon: 106.7, lat: 10.78, address: '' })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditItem(item)
    setModalOpen(true)
  }

  async function handleSave() {
    try {
      // Validate required fields
      if (!editItem?.name || !editItem.name.trim()) {
        setToast({ message: 'Vui lòng nhập tên trạm', type: 'error' })
        return
      }

      // Validate coordinates
      const lon = parseFloat(editItem.lon)
      const lat = parseFloat(editItem.lat)
      
      if (isNaN(lon) || isNaN(lat)) {
        setToast({ message: 'Vui lòng chọn vị trí trên bản đồ', type: 'error' })
        return
      }

      if (lon < -180 || lon > 180 || lat < -90 || lat > 90) {
        setToast({ message: 'Tọa độ không hợp lệ', type: 'error' })
        return
      }

      const payload = {
        name: editItem.name.trim(),
        lon: lon,
        lat: lat,
        address: editItem.address || null,
      }

      if (editItem.id) {
        // Update existing
        const res = await api.updateDepot(editItem.id, payload)
        if (res.ok) {
          setModalOpen(false)
          setToast({ message: 'Đã cập nhật trạm', type: 'success' })
          loadData()
        } else {
          setToast({ message: res.error || 'Cập nhật thất bại', type: 'error' })
        }
      } else {
        // Create new
        const res = await api.createDepot(payload)
        if (res.ok) {
          setModalOpen(false)
          setToast({ message: 'Đã tạo trạm', type: 'success' })
          loadData()
        } else {
          setToast({ message: res.error || 'Tạo thất bại', type: 'error' })
        }
      }
    } catch (error) {
      console.error('Save depot error:', error)
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
    }
  }

  const columns = [
    { key: 'name', label: 'Tên trạm' },
    { 
      key: 'address', 
      label: 'Địa chỉ',
      render: (r) => r.address || 'N/A'
    },
    { 
      key: 'district', 
      label: 'Quận trực thuộc',
      render: (r) => {
        const district = r.district || extractDistrictFromAddress(r.address || '')
        return district || 'N/A'
      }
    },
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
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Quản lý Trạm thu gom (CN14)</h1>
            
            {/* Filter by district */}
            <div className="card" style={{ marginBottom: 16 }}>
              <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}>
                <div style={{ flex: '1 1 200px' }}>
                  <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Lọc theo quận</label>
                  <select
                    value={selectedDistrict}
                    onChange={(e) => setSelectedDistrict(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                  >
                    <option value="">Tất cả quận</option>
                    {depotDistricts.map(dist => (
                      <option key={dist} value={dist}>{dist}</option>
                    ))}
                  </select>
                </div>
                <div style={{ flex: '0 0 auto', alignSelf: 'flex-end' }}>
                  <button className="btn btn-secondary" onClick={loadData} style={{ marginTop: 24 }}>
                    Tải lại
                  </button>
                </div>
              </div>
              {selectedDistrict && (
                <div style={{ marginTop: 12, padding: 12, backgroundColor: '#e3f2fd', borderRadius: 6, fontSize: 14, color: '#1976d2' }}>
                  📍 <strong>{selectedDistrict}</strong>: Tìm thấy {filteredDepots.length} trạm
                </div>
              )}
            </div>

            <div className="card">
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                <h2>Danh sách trạm thu gom</h2>
                <button className="btn btn-sm btn-primary" onClick={handleAdd}>
                  Thêm trạm
                </button>
              </div>
              <Table columns={columns} data={filteredDepots} emptyText="Không có trạm" />
            </div>
          </div>
        </main>
      </div>
      <FormModal open={modalOpen} title="Trạm thu gom" onClose={() => setModalOpen(false)} onSubmit={handleSave}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Tên trạm</label>
            <input
              type="text"
              value={editItem?.name || ''}
              onChange={(e) => setEditItem({ ...editItem, name: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
              placeholder="Nhập tên trạm"
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Vị trí</label>
            {modalOpen && editItem && (
              <MapPicker
                key={`${editItem.id || 'new'}-${editItem.lon}-${editItem.lat}`}
                center={[
                  typeof editItem.lon === 'number' ? editItem.lon : parseFloat(editItem.lon) || 106.7,
                  typeof editItem.lat === 'number' ? editItem.lat : parseFloat(editItem.lat) || 10.78
                ]}
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
