/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager - Dynamic Dispatch Page
 */

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
    if (res.ok && Array.isArray(res.data)) {
      setAlerts(res.data);
    } else {
      console.warn('Failed to load alerts:', res);
      setAlerts([]);
    }
  }

  async function handleOpenDispatchModal(alert) {
    setLoading(true);
    setCurrentAlert(alert);
    const res = await api.dispatchAlert(alert.alert_id);
    setLoading(false);
    if (res.ok && Array.isArray(res.data)) {
      setSuggestedVehicles(res.data);
      setIsModalOpen(true);
    } else {
      setToast({ message: 'Không tìm thấy xe phù hợp.', type: 'error' });
    }
  }

  const columns = [
    { 
      key: 'created_at', 
      label: 'Thời gian', 
      render: (r) => {
        if (!r.created_at) return '-'
        const date = new Date(r.created_at)
        return date.toLocaleString('vi-VN', { 
          day: '2-digit', 
          month: '2-digit', 
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        })
      }
    },
    { 
      key: 'point_name', 
      label: 'Điểm', 
      render: (r) => {
        // Try to get address from point_name or details
        const address = r.point_name || r.details?.address || r.location_address || `ID: ${r.point_id}`
        return address
      }
    },
    { 
      key: 'license_plate', 
      label: 'Phương tiện gốc', 
      render: (r) => r.license_plate || r.vehicle_plate || `ID: ${r.vehicle_id || '-'}` 
    },
    { 
      key: 'alert_type', 
      label: 'Loại sự cố', 
      render: (r) => {
        const typeMap = {
          missed_point: 'Bỏ sót điểm',
          late_checkin: 'Check-in muộn'
        }
        return typeMap[r.alert_type] || r.alert_type
      }
    },
    { 
      key: 'severity', 
      label: 'Mức độ', 
      render: (r) => {
        const isCritical = r.severity === 'critical'
        return (
          <span style={{ 
            color: isCritical ? '#ef4444' : '#f59e0b',
            fontWeight: 500
          }}>
            {isCritical ? 'Nghiêm trọng' : 'Cảnh báo'}
          </span>
        )
      }
    },
    { 
      key: 'status', 
      label: 'Trạng thái',
      render: (r) => {
        const statusMap = {
          open: 'open',
          acknowledged: 'Đã xác nhận',
          resolved: 'Đã xử lý',
          closed: 'Đã đóng'
        }
        return statusMap[r.status] || r.status
      }
    },
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
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Điều phối động</h1>
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
            const routeId = res.data?.data?.route_id || res.data?.route_id || 'N/A';
            setToast({
              message: `Đã giao việc cho xe ${vehicleId} để xử lý sự cố. Tuyến mới: ${routeId}`,
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
    <div 
      className="modal-overlay"
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(0, 0, 0, 0.75)',
        backdropFilter: 'blur(4px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999,
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget && !assigning) {
          onClose();
        }
      }}
    >
      <div 
        className="modal"
        style={{
          background: '#ffffff',
          padding: '28px',
          borderRadius: '12px',
          width: '90%',
          maxWidth: '600px',
          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.1)',
          border: '2px solid #3b82f6',
          animation: 'fadeIn 0.2s ease-out',
        }}
      >
        <div className="modal-header" style={{ borderBottom: '2px solid #e5e7eb', paddingBottom: '16px', marginBottom: '20px' }}>
          <h3 style={{ margin: 0, fontSize: '20px', fontWeight: 600, color: '#1f2937' }}>
            Điều phối lại cho sự cố tại điểm {alert?.point_name || `ID: ${alert?.point_id}`}
          </h3>
          <button 
            onClick={onClose} 
            className="close-button" 
            disabled={assigning}
            style={{
              background: 'none',
              border: 'none',
              fontSize: '28px',
              cursor: assigning ? 'not-allowed' : 'pointer',
              color: '#6b7280',
              padding: '0',
              width: '32px',
              height: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              borderRadius: '4px',
              transition: 'all 0.2s',
            }}
            onMouseEnter={(e) => {
              if (!assigning) e.target.style.background = '#f3f4f6';
            }}
            onMouseLeave={(e) => {
              e.target.style.background = 'none';
            }}
          >
            &times;
          </button>
        </div>
        <div className="modal-body">
          <p style={{ fontSize: '16px', color: '#4b5563', marginBottom: '20px', fontWeight: 500 }}>
            Chọn một phương tiện gần nhất để xử lý:
          </p>
          <div className="vehicle-suggestions">
            {vehicles.length > 0 ? (
              vehicles.map(v => (
                <div 
                  key={v.id} 
                  className="vehicle-suggestion-item"
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '16px',
                    background: '#f9fafb',
                    borderRadius: '8px',
                    border: '1px solid #e5e7eb',
                    transition: 'all 0.2s',
                    marginBottom: '12px',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = '#f3f4f6';
                    e.currentTarget.style.borderColor = '#3b82f6';
                    e.currentTarget.style.boxShadow = '0 2px 8px rgba(59, 130, 246, 0.15)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = '#f9fafb';
                    e.currentTarget.style.borderColor = '#e5e7eb';
                    e.currentTarget.style.boxShadow = 'none';
                  }}
                >
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', flex: 1 }}>
                    <span style={{ fontSize: '15px', fontWeight: 600, color: '#1f2937' }}>
                      <strong>Xe:</strong> {v.id} {v.license_plate ? `(${v.license_plate})` : ''}
                    </span>
                    <span style={{ fontSize: '14px', color: '#6b7280' }}>
                      <strong>Khoảng cách:</strong> {Math.round(v.distance)}m
                    </span>
                  </div>
                  <button
                    className="btn btn-sm btn-success"
                    onClick={() => handleAssign(v.id)}
                    disabled={assigning}
                    style={{
                      padding: '10px 20px',
                      fontSize: '14px',
                      fontWeight: 600,
                      borderRadius: '6px',
                      border: 'none',
                      cursor: assigning ? 'not-allowed' : 'pointer',
                      background: assigning ? '#9ca3af' : '#22c55e',
                      color: 'white',
                      transition: 'all 0.2s',
                      minWidth: '120px',
                    }}
                    onMouseEnter={(e) => {
                      if (!assigning) {
                        e.target.style.background = '#16a34a';
                        e.target.style.transform = 'translateY(-1px)';
                        e.target.style.boxShadow = '0 4px 12px rgba(34, 197, 94, 0.4)';
                      }
                    }}
                    onMouseLeave={(e) => {
                      e.target.style.background = assigning ? '#9ca3af' : '#22c55e';
                      e.target.style.transform = 'translateY(0)';
                      e.target.style.boxShadow = 'none';
                    }}
                  >
                    {assigning ? 'Đang giao...' : 'Giao việc'}
                  </button>
                </div>
              ))
            ) : (
              <p style={{ textAlign: 'center', color: '#6b7280', padding: '20px' }}>Không có xe nào phù hợp.</p>
            )}
          </div>
        </div>
      </div>
      <style>{`
        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: scale(0.95) translateY(-10px);
          }
          to {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
        }
      `}</style>
    </div>
  );
}

}

