import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import FormModal from '../../components/common/FormModal.jsx'
import Toast from '../../components/common/Toast.jsx'
import api from '../../lib/api.js'

export default function Exceptions() {
  const [exceptions, setExceptions] = useState([])
  const [modalOpen, setModalOpen] = useState(false)
  const [selected, setSelected] = useState(null)
  const [action, setAction] = useState('approve')
  const [reason, setReason] = useState('')
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadExceptions()
  }, [])

  async function loadExceptions() {
    const res = await api.getExceptions()
    if (res.ok) setExceptions(res.data)
  }

  function handleAction(item, act) {
    setSelected(item)
    setAction(act)
    setReason('')
    setModalOpen(true)
  }

  async function handleSubmit() {
    setModalOpen(false)
    const res = action === 'approve' ? await api.approveException(selected.id, { plan: reason }) : await api.rejectException(selected.id, { reason })
    if (res.ok) {
      setToast({ message: `Đã ${action === 'approve' ? 'phê duyệt' : 'từ chối'} ngoại lệ`, type: 'success' })
      loadExceptions()
    } else {
      setToast({ message: 'Hành động thất bại', type: 'error' })
    }
  }

  const columns = [
    { key: 'time', label: 'Thời gian' },
    { key: 'location', label: 'Vị trí' },
    { key: 'type', label: 'Loại' },
    { key: 'status', label: 'Trạng thái' },
    {
      key: 'action',
      label: 'Hành động',
      render: (r) =>
        r.status === 'pending' ? (
          <div style={{ display: 'flex', gap: 4 }}>
            <button className="btn btn-sm btn-primary" onClick={() => handleAction(r, 'approve')}>
              Phê duyệt
            </button>
            <button className="btn btn-sm" onClick={() => handleAction(r, 'reject')}>
              Từ chối
            </button>
          </div>
        ) : null
    }
  ]

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Xử lý ngoại lệ (CN15)</h1>
            <div className="card">
              <h2>Báo cáo ngoại lệ</h2>
              <Table columns={columns} data={exceptions} emptyText="Không có ngoại lệ" />
            </div>
          </div>
        </main>
      </div>
      <FormModal
        open={modalOpen}
        title={action === 'approve' ? 'Phê duyệt ngoại lệ' : 'Từ chối ngoại lệ'}
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmit}
      >
        <div>
          <label style={{ display: 'block', marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
            {action === 'approve' ? 'Kế hoạch / Giải pháp' : 'Lý do'}
          </label>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={4}
            style={{ width: '100%', padding: '8px 12px', border: '1px solid #ccc', borderRadius: 6, resize: 'vertical' }}
          />
        </div>
      </FormModal>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  )
}

