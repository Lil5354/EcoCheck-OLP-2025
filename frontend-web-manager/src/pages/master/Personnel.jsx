import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import Toast from '../../components/common/Toast.jsx'
import api from '../../lib/api.js'

export default function Personnel() {
  const [personnel, setPersonnel] = useState([])
  const [modalOpen, setModalOpen] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadPersonnel()
  }, [])

  async function loadPersonnel() {
    const res = await api.getPersonnel()
    if (res.ok && Array.isArray(res.data)) setPersonnel(res.data)
  }

  function handleAdd() {
    setEditItem({ id: '', name: '', role: 'driver', phone: '', email: '', status: 'active' })
    setModalOpen(true)
  }

  function handleEdit(item) {
    setEditItem(item)
    setModalOpen(true)
  }

  async function handleSave() {
    try {
      if (editItem.id) {
        // Update existing
        const res = await api.updateWorker(editItem.id, {
          name: editItem.name,
          role: editItem.role,
          phone: editItem.phone,
          email: editItem.email,
          status: editItem.status,
        })
        if (res.ok) {
          setModalOpen(false)
          setToast({ message: 'Đã cập nhật nhân sự', type: 'success' })
          loadPersonnel()
        } else {
          setToast({ message: res.error || 'Cập nhật thất bại', type: 'error' })
        }
      } else {
        // Create new
        const res = await api.createWorker({
          name: editItem.name,
          role: editItem.role,
          phone: editItem.phone,
          email: editItem.email,
          status: editItem.status,
        })
        if (res.ok) {
          setModalOpen(false)
          setToast({ message: 'Đã tạo nhân sự', type: 'success' })
          loadPersonnel()
        } else {
          setToast({ message: res.error || 'Tạo thất bại', type: 'error' })
        }
      }
    } catch (error) {
      setToast({ message: 'Lỗi: ' + error.message, type: 'error' })
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
          dispatcher: 'Điều phối viên',
          supervisor: 'Giám sát'
        }
        return roleMap[r.role] || r.role
      }
    },
    { 
      key: 'depot_name', 
      label: 'Trạm',
      render: (r) => r.depot_name || '-'
    },
    { 
      key: 'status', 
      label: 'Trạng thái',
      render: (r) => {
        const statusMap = {
          active: 'Hoạt động',
          inactive: 'Không hoạt động',
          on_leave: 'Nghỉ phép'
        }
        return statusMap[r.status] || r.status
      }
    },
    {
      key: 'action',
      label: 'Hành động',
      render: (r) => (
        <div style={{ display: 'flex', gap: 4 }}>
          <button className="btn btn-sm" onClick={() => handleEdit(r)}>
            Sửa
          </button>
          {r.status === 'active' && (
            <button 
              className="btn btn-sm" 
              onClick={async () => {
                const res = await api.deleteWorker(r.id)
                if (res.ok) {
                  setToast({ message: 'Đã vô hiệu hóa nhân sự', type: 'success' })
                  loadPersonnel()
                } else {
                  setToast({ message: res.error || 'Vô hiệu hóa thất bại', type: 'error' })
                }
              }}
              style={{ backgroundColor: '#f44336', color: 'white' }}
            >
              Vô hiệu hóa
            </button>
          )}
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
              <Table columns={columns} data={personnel} emptyText="Không có nhân sự" />
            </div>
          </div>
        </main>
      </div>
      <FormModal open={modalOpen} title="Nhân sự" onClose={() => setModalOpen(false)} onSubmit={handleSave}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Họ tên</label>
            <input
              type="text"
              value={editItem?.name || ''}
              onChange={(e) => setEditItem({ ...editItem, name: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Vai trò</label>
            <select
              value={editItem?.role || 'driver'}
              onChange={(e) => setEditItem({ ...editItem, role: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            >
              <option value="driver">Tài xế</option>
              <option value="collector">Nhân viên thu gom</option>
              <option value="manager">Quản lý</option>
              <option value="dispatcher">Điều phối viên</option>
              <option value="supervisor">Giám sát</option>
            </select>
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Số điện thoại</label>
            <input
              type="text"
              value={editItem?.phone || ''}
              onChange={(e) => setEditItem({ ...editItem, phone: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Email</label>
            <input
              type="email"
              value={editItem?.email || ''}
              onChange={(e) => setEditItem({ ...editItem, email: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>Trạng thái</label>
            <select
              value={editItem?.status || 'active'}
              onChange={(e) => setEditItem({ ...editItem, status: e.target.value })}
              style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6 }}
            >
              <option value="active">Hoạt động</option>
              <option value="inactive">Không hoạt động</option>
              <option value="on_leave">Nghỉ phép</option>
            </select>
          </div>
        </div>
      </FormModal>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

