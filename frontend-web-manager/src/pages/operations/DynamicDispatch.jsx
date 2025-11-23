import React, { useState, useEffect } from 'react'
import SidebarPro from '../../navigation/SidebarPro.jsx'
import Table from '../../components/common/Table.jsx'
import api from '../../lib/api.js'
import Toast from '../../components/common/Toast.jsx'

export default function DynamicDispatch() {
  const [alerts, setAlerts] = useState([])
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [suggestedVehicles, setSuggestedVehicles] = useState([])
  const [currentAlert, setCurrentAlert] = useState(null)

  useEffect(() => {
    loadAlerts()
    const id = setInterval(loadAlerts, 5000)
    return () => clearInterval(id)
  }, [])

  async function loadAlerts() {
    const res = await api.getAlerts();
    if (res.ok && Array.isArray(res.data.data)) {
      setAlerts(res.data.data);
    }
  }

  async function handleOpenDispatchModal(alert) {
    setLoading(true);
    setCurrentAlert(alert);
    const res = await api.dispatchAlert(alert.alert_id);
    setLoading(false);
    if (res.ok && Array.isArray(res.data.data)) {
      setSuggestedVehicles(res.data.data);
      setIsModalOpen(true);
    } else {
      setToast({ message: 'Không tìm thấy xe phù hợp.', type: 'error' });
    }
  }

  const columns = [
    { key: 'created_at', label: 'Thời gian', render: (r) => new Date(r.created_at).toLocaleString('vi-VN') },
    { key: 'point_name', label: 'Điểm', render: (r) => r.point_name || `ID: ${r.point_id}` },
    { key: 'license_plate', label: 'Phương tiện gốc', render: (r) => r.license_plate || `ID: ${r.vehicle_id}` },
    { key: 'alert_type', label: 'Loại sự cố', render: (r) => r.alert_type === 'missed_point' ? 'Bỏ sót điểm' : 'Check-in muộn' },
    { key: 'severity', label: 'Mức độ', render: (r) => <span style={{ color: r.severity === 'critical' ? '#ef4444' : '#f59e0b' }}>{r.severity === 'critical' ? 'Nghiêm trọng' : 'Cảnh báo'}</span> },
    { key: 'status', label: 'Trạng thái' },
    {
      key: 'action',
      label: 'Hành động',
      render: (r) =>
        r.status === 'open' ? (
          <button className="btn btn-sm btn-primary" onClick={() => handleOpenDispatchModal(r)} disabled={loading}>
            {loading && currentAlert?.alert_id === r.alert_id ? 'Đang tìm...' : 'Tạo tuyến mới'}
          </button>
        ) : null
    }
  ]

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Điều phối động (CN7)</h1>
            <div className="card">
              <h2>Cảnh báo thời gian thực</h2>
              <Table columns={columns} data={alerts} emptyText="Không có cảnh báo" />
            </div>
          </div>
        </main>
      </div>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      <DispatchModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        vehicles={suggestedVehicles}
        alert={currentAlert}
        onAssign={async (vehicleId) => {
          setLoading(true);
          const res = await api.assignVehicleToAlert(currentAlert.alert_id, vehicleId);
          setLoading(false);

          if (res.ok) {
            setToast({
              message: `Đã giao việc cho xe ${vehicleId} để xử lý sự cố. Tuyến mới: ${res.data.data.route_id}`,
              type: 'success'
            });
            setIsModalOpen(false);
            loadAlerts(); // Refresh alerts to reflect status change
          } else {
            setToast({
              message: `Lỗi khi giao việc: ${res.error || 'Không xác định'}`,
              type: 'error'
            });
          }
        }}
      />
    </div>
  )

// Modal Component for Dispatching
function DispatchModal({ isOpen, onClose, vehicles, alert, onAssign }) {
  const [assigning, setAssigning] = React.useState(false);

  if (!isOpen) return null;

  const handleAssign = async (vehicleId) => {
    setAssigning(true);
    await onAssign(vehicleId);
    setAssigning(false);
  };

  return (
    <div className="modal-overlay">
      <div className="modal">
        <div className="modal-header">
          <h3>Điều phối lại cho sự cố tại điểm {alert?.point_name || `ID: ${alert?.point_id}`}</h3>
          <button onClick={onClose} className="close-button" disabled={assigning}>&times;</button>
        </div>
        <div className="modal-body">
          <p>Chọn một phương tiện gần nhất để xử lý:</p>
          <div className="vehicle-suggestions">
            {vehicles.length > 0 ? (
              vehicles.map(v => (
                <div key={v.id} className="vehicle-suggestion-item">
                  <span><strong>Xe:</strong> {v.id} ({v.license_plate || 'N/A'})</span>
                  <span><strong>Khoảng cách:</strong> {Math.round(v.distance)}m</span>
                  <button
                    className="btn btn-sm btn-success"
                    onClick={() => handleAssign(v.id)}
                    disabled={assigning}
                  >
                    {assigning ? 'Đang giao...' : 'Giao việc'}
                  </button>
                </div>
              ))
            ) : (
              <p>Không có xe nào phù hợp.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

}

