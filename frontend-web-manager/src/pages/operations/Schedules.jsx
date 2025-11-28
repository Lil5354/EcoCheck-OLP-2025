import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import Toast from '../../components/common/Toast.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import api from '../../lib/api.js'

export default function Schedules() {
  const [schedules, setSchedules] = useState([])
  const [loading, setLoading] = useState(true)
  const [toast, setToast] = useState(null)
  const [filterStatus, setFilterStatus] = useState('')
  const [personnel, setPersonnel] = useState([])
  const [assignModalOpen, setAssignModalOpen] = useState(false)
  const [selectedSchedule, setSelectedSchedule] = useState(null)
  const [selectedEmployeeId, setSelectedEmployeeId] = useState('')

  useEffect(() => {
    loadSchedules()
    loadPersonnel()
  }, [filterStatus])

  async function loadPersonnel() {
    try {
      const result = await api.getPersonnel({ status: 'active' })
      if (result.ok) {
        const allPersonnel = Array.isArray(result.data) ? result.data : []
        const filtered = allPersonnel.filter(
          p => p.role === 'driver' || p.role === 'collector'
        )
        setPersonnel(filtered)
      }
    } catch (error) {
      console.error('Error loading personnel:', error)
    }
  }

  function handleAssignEmployee(schedule) {
    setSelectedSchedule(schedule)
    setSelectedEmployeeId(schedule.employee_id || '')
    setAssignModalOpen(true)
  }

  async function handleSaveAssignment() {
    if (!selectedSchedule || !selectedEmployeeId) {
      setToast({ message: 'Vui lòng chọn nhân viên', type: 'error' })
      return
    }
    
    try {
      const result = await api.updateSchedule(selectedSchedule.schedule_id || selectedSchedule.id, {
        employee_id: selectedEmployeeId,
        status: 'assigned'
      })
      
      if (result.ok) {
        setToast({ message: 'Đã gán nhân viên thành công', type: 'success' })
        setAssignModalOpen(false)
        setSelectedSchedule(null)
        setSelectedEmployeeId('')
        await loadSchedules()
      } else {
        setToast({ message: result.error || 'Có lỗi xảy ra', type: 'error' })
      }
    } catch (error) {
      setToast({ message: 'Lỗi khi gán nhân viên: ' + error.message, type: 'error' })
    }
  }

  async function loadSchedules() {
    setLoading(true)
    try {
      const params = {}
      if (filterStatus) {
        params.status = filterStatus
      }
      
      const result = await api.getSchedules(params)
      
      if (result.ok) {
        const schedulesData = Array.isArray(result.data) ? result.data : []
        setSchedules(schedulesData)
      } else {
        setToast({ message: result.error || 'Lỗi khi tải danh sách lịch thu gom', type: 'error' })
        setSchedules([])
      }
    } catch (error) {
      setToast({ message: 'Lỗi khi tải dữ liệu: ' + error.message, type: 'error' })
      setSchedules([])
    } finally {
      setLoading(false)
    }
  }

  const columns = [
    { 
      key: 'citizen_name', 
      label: 'Người đăng ký',
      render: (r) => (
        <div>
          <div style={{ fontWeight: 500 }}>{r.citizen_name || r.reporter_name || 'N/A'}</div>
          <div style={{ fontSize: 12, color: '#666' }}>{r.citizen_phone || r.reporter_phone || '-'}</div>
        </div>
      )
    },
    { 
      key: 'scheduled_date', 
      label: 'Ngày thu gom',
      render: (r) => {
        if (!r.scheduled_date) return '-'
        const date = new Date(r.scheduled_date)
        return date.toLocaleDateString('vi-VN', { 
          weekday: 'short', 
          year: 'numeric', 
          month: '2-digit', 
          day: '2-digit' 
        })
      }
    },
    { 
      key: 'time_slot', 
      label: 'Khung giờ',
      render: (r) => r.time_slot || '-'
    },
    { 
      key: 'address', 
      label: 'Địa chỉ',
      render: (r) => {
        if (r.address) {
          const dateStr = r.scheduled_date 
            ? new Date(r.scheduled_date).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' })
            : ''
          return (
            <div>
              <div>{r.address}</div>
              {dateStr && <div style={{ fontSize: 12, color: '#666', marginTop: 2 }}>Ngày {dateStr}</div>}
            </div>
          )
        }
        return r.latitude && r.longitude ? `${r.latitude.toFixed(5)}, ${r.longitude.toFixed(5)}` : '-'
      }
    },
    { 
      key: 'waste_type', 
      label: 'Loại rác',
      render: (r) => {
        const typeMap = {
          household: 'Rác sinh hoạt',
          recyclable: 'Rác tái chế',
          bulky: 'Rác cồng kềnh',
          hazardous: 'Rác độc hại',
          organic: 'Rác hữu cơ'
        }
        const displayType = typeMap[r.waste_type] || r.waste_type
        if (r.waste_type === 'bulky') {
          return <div>{displayType} - Bulky waste</div>
        } else if (r.waste_type === 'recyclable') {
          return <div>{displayType} - Recyclable waste</div>
        }
        return displayType
      }
    },
    { 
      key: 'estimated_weight', 
      label: 'Khối lượng (kg)',
      render: (r) => r.estimated_weight ? `${parseFloat(r.estimated_weight).toFixed(2)} kg` : '-'
    },
    { 
      key: 'status', 
      label: 'Trạng thái',
      render: (r) => {
        const statusMap = {
          pending: { label: 'Chờ xử lý', color: '#ff9800' },
          scheduled: { label: 'Đã lên lịch', color: '#2196f3' },
          assigned: { label: 'Đã gán nhân viên', color: '#9c27b0' },
          in_progress: { label: 'Đang thực hiện', color: '#00bcd4' },
          completed: { label: 'Hoàn thành', color: '#4caf50' },
          cancelled: { label: 'Đã hủy', color: '#f44336' },
          missed: { label: 'Bỏ lỡ', color: '#9e9e9e' }
        }
        const status = statusMap[r.status] || { label: r.status, color: '#666' }
        return (
          <span style={{ 
            padding: '4px 8px', 
            borderRadius: 12, 
            backgroundColor: status.color + '20',
            color: status.color,
            fontSize: 12,
            fontWeight: 500
          }}>
            {status.label}
          </span>
        )
      }
    },
    { 
      key: 'employee_name', 
      label: 'Nhân viên',
      render: (r) => (
        <div>
          {r.employee_name ? (
            <div>
              <div>{r.employee_name}</div>
              {r.employee_role && (
                <div style={{ fontSize: 12, color: '#666' }}>
                  {r.employee_role === 'driver' ? 'Tài xế' : r.employee_role === 'collector' ? 'Nhân viên thu gom' : r.employee_role}
                </div>
              )}
            </div>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
              <span style={{ color: '#999', fontStyle: 'italic' }}>Chưa gán</span>
              {(r.status === 'pending' || r.status === 'scheduled') && (
                <button 
                  className="btn btn-sm"
                  onClick={(e) => {
                    e.stopPropagation()
                    handleAssignEmployee(r)
                  }}
                  style={{ 
                    padding: '4px 8px', 
                    fontSize: 12,
                    backgroundColor: '#2196f3',
                    color: 'white',
                    border: 'none',
                    borderRadius: 4,
                    cursor: 'pointer',
                    whiteSpace: 'nowrap'
                  }}
                >
                  Gán nhân viên
                </button>
              )}
            </div>
          )}
        </div>
      )
    },
    {
      key: 'created_at',
      label: 'Ngày tạo',
      render: (r) => {
        if (!r.created_at) return '-'
        const date = new Date(r.created_at)
        return date.toLocaleString('vi-VN', { 
          year: 'numeric', 
          month: '2-digit', 
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit'
        })
      }
    }
  ]

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
              <h1 style={{ fontSize: 24, fontWeight: 600 }}>Lịch thu gom từ người dân</h1>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value)}
                  style={{ 
                    padding: '8px 12px', 
                    border: '1px solid #ccc', 
                    borderRadius: 6,
                    fontSize: 14
                  }}
                >
                  <option value="">Tất cả trạng thái</option>
                  <option value="pending">Chờ xử lý</option>
                  <option value="scheduled">Đã lên lịch</option>
                  <option value="assigned">Đã gán nhân viên</option>
                  <option value="in_progress">Đang thực hiện</option>
                  <option value="completed">Hoàn thành</option>
                  <option value="cancelled">Đã hủy</option>
                </select>
                <button className="btn" onClick={loadSchedules}>
                  🔄 Làm mới
                </button>
              </div>
            </div>
            <div className="card">
              {loading ? (
                <div style={{ padding: 40, textAlign: 'center' }}>Đang tải...</div>
              ) : (
                <Table 
                  columns={columns} 
                  data={schedules} 
                  emptyText="Chưa có lịch thu gom nào"
                />
              )}
            </div>
          </div>
        </main>
      </div>
      
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      {assignModalOpen && selectedSchedule && (
        <FormModal
          title="Gán nhân viên cho lịch thu gom"
          open={assignModalOpen}
          onClose={() => {
            setAssignModalOpen(false)
            setSelectedSchedule(null)
            setSelectedEmployeeId('')
          }}
          onSubmit={handleSaveAssignment}
          submitLabel="Gán nhân viên"
        >
          <div style={{ padding: '16px 0' }}>
            <label style={{ display: 'block', marginBottom: 8, fontWeight: 500 }}>
              Chọn nhân viên:
            </label>
            <select
              value={selectedEmployeeId}
              onChange={(e) => setSelectedEmployeeId(e.target.value)}
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ccc',
                borderRadius: 6,
                fontSize: 14
              }}
            >
              <option value="">-- Chọn nhân viên --</option>
              {personnel.map(p => (
                <option key={p.id} value={p.id}>
                  {p.name} - {p.role === 'driver' ? 'Tài xế' : p.role === 'collector' ? 'Nhân viên thu gom' : p.role}
                  {p.depot_name && ` (${p.depot_name})`}
                </option>
              ))}
            </select>
            {selectedSchedule && (
              <div style={{ marginTop: 16, padding: 12, backgroundColor: '#f5f5f5', borderRadius: 6 }}>
                <div style={{ fontSize: 12, color: '#666', marginBottom: 4 }}>Thông tin lịch thu gom:</div>
                <div style={{ fontSize: 14 }}>
                  <strong>{selectedSchedule.citizen_name || selectedSchedule.reporter_name}</strong><br/>
                  {selectedSchedule.address}<br/>
                  {selectedSchedule.scheduled_date ? new Date(selectedSchedule.scheduled_date).toLocaleDateString('vi-VN') : '-'} - {selectedSchedule.time_slot || '-'}
                </div>
              </div>
            )}
          </div>
        </FormModal>
      )}
    </div>
  )
}

