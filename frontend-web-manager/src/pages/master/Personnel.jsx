import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import Toast from '../../components/common/Toast.jsx'
import api from '../../lib/api.js'

export default function Personnel() {
  console.log('🚀 Personnel component mounted/re-rendered!')
  
  const [personnel, setPersonnel] = useState([])
  const [depots, setDepots] = useState([])
  const [loading, setLoading] = useState(true)
  const [modalOpen, setModalOpen] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [toast, setToast] = useState(null)
  const [credentials, setCredentials] = useState(null)

  useEffect(() => {
    console.log('🔄 useEffect triggered - calling loadData()')
    loadData()
  }, [])

  async function loadData() {
    setLoading(true)
    try {
      console.log('🔍 Starting loadData...')
      const [personnelRes, depotsRes] = await Promise.all([
        api.getPersonnel(),
        api.getDepots()
      ])
      
      console.log('📦 LoadData - Personnel response:', personnelRes)
      console.log('📦 LoadData - Depots response:', depotsRes)
      
      if (personnelRes && personnelRes.ok) {
        const personnelData = Array.isArray(personnelRes.data) ? personnelRes.data : []
        console.log('✅ Setting personnel data:', personnelData.length, 'items')
        console.log('📋 Personnel data:', personnelData)
        setPersonnel(personnelData)
      } else {
        console.error('❌ Error loading personnel:', personnelRes)
        setToast({ message: personnelRes?.error || 'Lỗi khi tải danh sách nhân sự', type: 'error' })
        // Set empty array if error
        setPersonnel([])
      }
      
      if (depotsRes && depotsRes.ok) {
        const depotsData = Array.isArray(depotsRes.data) ? depotsRes.data : []
        setDepots(depotsData)
      } else {
        console.error('❌ Error loading depots:', depotsRes)
      }
    } catch (error) {
      console.error('�� Error loading data:', error)
      setToast({ message: 'Lỗi khi tải dữ liệu: ' + error.message, type: 'error' })
      setPersonnel([]) // Set empty array on error
    } finally {
      setLoading(false)
    }
  }

  function handleAdd() {
    console.log('➕ handleAdd called')
    setEditItem({ 
      name: '', 
      email: '', 
      phone: '', 
      password: '',
      role: 'driver', 
      depot_id: depots[0]?.id || '',
      certifications: []
    })
    setCredentials(null)
    setModalOpen(true)
  }

  function handleEdit(item) {
    console.log('✏️ handleEdit called for:', item)
    setEditItem({ ...item })
    setCredentials(null)
    setModalOpen(true)
  }

  async function handleSave() {
    if (!editItem) return

    try {
      console.log('handleSave - editItem:', editItem)
      let result
      if (editItem.id) {
        // Update existing
        console.log('Updating worker:', editItem.id)
        result = await api.updateWorker(editItem.id, editItem)
      } else {
        // Create new worker
        if (!editItem.name || !editItem.email || !editItem.password || !editItem.depot_id) {
          setToast({ message: 'Vui lòng điền đầy đủ thông tin bắt buộc', type: 'error' })
          return
        }
        console.log('Creating new worker:', editItem)
        result = await api.createWorker(editItem)
        console.log('Create worker result:', result)
        
        if (result.ok && result.data?.credentials) {
          setCredentials(result.data.credentials)
        }
      }

      console.log('Save result:', result)
      if (result.ok) {
        setToast({ 
          message: editItem.id ? 'Đã cập nhật nhân sự' : 'Đã tạo tài khoản nhân viên', 
          type: 'success' 
        })
        // Force reload data BEFORE closing modal
        console.log('Reloading data after save...')
        await loadData()
        console.log('Data reloaded, closing modal')
        // Close modal after data is loaded
        setModalOpen(false)
      } else {
        console.error('Save failed:', result.error)
        setToast({ message: result.error || 'Có lỗi xảy ra', type: 'error' })
      }
    } catch (error) {
      console.error('Error saving personnel:', error)
      setToast({ message: 'Lỗi khi lưu dữ liệu', type: 'error' })
    }
  }

  async function handleDelete(id) {
    if (!confirm('Bạn có chắc muốn vô hiệu hóa nhân viên này?')) return

    try {
      const result = await api.deleteWorker(id)
      if (result.ok) {
        setToast({ message: 'Đã vô hiệu hóa nhân viên', type: 'success' })
        await loadData()
      } else {
        setToast({ message: result.error || 'Có lỗi xảy ra', type: 'error' })
      }
    } catch (error) {
      console.error('Error deleting personnel:', error)
      setToast({ message: 'Lỗi khi xóa dữ liệu', type: 'error' })
    }
  }

  const columns = [
    { key: 'name', label: 'Họ tên' },
    { 
      key: 'email', 
      label: 'Email',
      render: (r) => r.email || '-'
    },
    { 
      key: 'phone', 
      label: 'SĐT',
      render: (r) => r.phone || '-'
    },
    { 
      key: 'role', 
      label: 'Vai trò',
      render: (r) => {
        const roleMap = {
          driver: 'Tài xế',
          collector: 'Nhân viên thu gom',
          manager: 'Quản lý',
          dispatcher: 'Điều phối viên'
        }
        return roleMap[r.role] || r.role
      }
    },
    { 
      key: 'depotName', 
      label: 'Trạm',
      render: (r) => r.depotName || '-'
    },
    { 
      key: 'status', 
      label: 'Trạng thái',
      render: (r) => {
        const statusMap = {
          active: 'Hoạt động',
          inactive: 'Ngừng hoạt động',
          on_leave: 'Nghỉ phép'
        }
        return statusMap[r.status] || r.status
      }
    },
    {
      key: 'action',
      label: 'Hành động',
      render: (r) => (
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-sm" onClick={() => handleEdit(r)}>
            Sửa
          </button>
          <button 
            className="btn btn-sm btn-danger" 
            onClick={() => handleDelete(r.id)}
            disabled={r.status === 'inactive'}
          >
            Vô hiệu hóa
          </button>
        </div>
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
              <h1 style={{ fontSize: 24, fontWeight: 600 }}>Quản lý nhân sự</h1>
              <button className="btn btn-primary" onClick={handleAdd}>
                + Tạo tài khoản nhân viên
              </button>
            </div>
            <div className="card">
              {loading ? (
                <div style={{ padding: 40, textAlign: 'center' }}>Đang tải...</div>
              ) : (
                <Table columns={columns} data={personnel} emptyText="Chưa có nhân sự" />
              )}
            </div>
          </div>
        </main>
      </div>
      
      <FormModal 
        open={modalOpen} 
        title={editItem?.id ? "Sửa nhân sự" : "Tạo tài khoản nhân viên"} 
        onClose={() => {
          setModalOpen(false)
          setCredentials(null)
        }} 
        onSubmit={handleSave}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {credentials && (
            <div style={{ 
              padding: 12, 
              backgroundColor: '#e8f5e9', 
              borderRadius: 8, 
              border: '1px solid #4caf50',
              marginBottom: 8
            }}>
              <strong style={{ color: '#2e7d32' }}>✓ Tài khoản đã được tạo thành công!</strong>
              <div style={{ marginTop: 8, fontSize: 14, color: '#1b5e20' }}>
                <div><strong>Email:</strong> {credentials.email}</div>
                {credentials.phone && <div><strong>SĐT:</strong> {credentials.phone}</div>}
                <div><strong>Mật khẩu:</strong> {credentials.password}</div>
                <div style={{ marginTop: 8, fontSize: 12, fontStyle: 'italic' }}>
                  Vui lòng ghi lại thông tin này để cung cấp cho nhân viên
                </div>
              </div>
            </div>
          )}

          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
              Họ tên <span style={{ color: 'red' }}>*</span>
            </label>
            <input
              type="text"
              value={editItem?.name || ''}
              onChange={(e) => setEditItem({ ...editItem, name: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
              placeholder="Nhập họ tên"
              required
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
              Email <span style={{ color: 'red' }}>*</span>
            </label>
            <input
              type="email"
              value={editItem?.email || ''}
              onChange={(e) => setEditItem({ ...editItem, email: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
              placeholder="worker@ecocheck.com"
              required
              disabled={!!editItem?.id}
            />
            {!editItem?.id && (
              <div style={{ fontSize: 12, color: '#666', marginTop: 4 }}>
                Email này sẽ được dùng để đăng nhập vào ứng dụng mobile
              </div>
            )}
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
              Số điện thoại
            </label>
            <input
              type="tel"
              value={editItem?.phone || ''}
              onChange={(e) => setEditItem({ ...editItem, phone: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
              placeholder="0901234567"
            />
          </div>

          {!editItem?.id && (
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                Mật khẩu <span style={{ color: 'red' }}>*</span>
              </label>
              <input
                type="password"
                value={editItem?.password || ''}
                onChange={(e) => setEditItem({ ...editItem, password: e.target.value })}
                style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
                placeholder="Tối thiểu 6 ký tự"
                required
                minLength={6}
              />
            </div>
          )}

          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
              Vai trò <span style={{ color: 'red' }}>*</span>
            </label>
            <select
              value={editItem?.role || 'driver'}
              onChange={(e) => setEditItem({ ...editItem, role: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            >
              <option value="driver">Tài xế</option>
              <option value="collector">Nhân viên thu gom</option>
            </select>
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
              Trạm thu gom <span style={{ color: 'red' }}>*</span>
            </label>
            <select
              value={editItem?.depot_id || ''}
              onChange={(e) => setEditItem({ ...editItem, depot_id: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
              required
            >
              <option value="">-- Chọn trạm --</option>
              {depots.map(depot => (
                <option key={depot.id} value={depot.id}>{depot.name}</option>
              ))}
            </select>
          </div>
        </div>
      </FormModal>
      
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}
