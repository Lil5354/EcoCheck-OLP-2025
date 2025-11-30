/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Personnel Management Page
 */

import React, { useState, useEffect } from "react";
import SidebarPro from "../../navigation/SidebarPro.jsx";
import Table from "../../components/common/Table.jsx";
import FormModal from "../../components/common/FormModal.jsx";
import Toast from "../../components/common/Toast.jsx";
import api from "../../lib/api.js";

export default function Personnel() {
  const [activeTab, setActiveTab] = useState("personnel"); // "personnel" or "groups"
  const [personnel, setPersonnel] = useState([]);
  const [groups, setGroups] = useState([]);
  const [depots, setDepots] = useState([]);
  const [vehicles, setVehicles] = useState([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [editItem, setEditItem] = useState(null);
  const [toast, setToast] = useState(null);
  const [autoAssignEnabled, setAutoAssignEnabled] = useState(true);

  useEffect(() => {
    loadDepots(); // Always load depots
    if (activeTab === "personnel") {
      loadPersonnel();
    } else {
      loadGroups();
      loadVehicles();
      loadPersonnel(); // Also load personnel for member selection
    }
  }, [activeTab]);

  async function loadPersonnel() {
    const res = await api.getPersonnel();
    if (res.ok && Array.isArray(res.data)) setPersonnel(res.data);
  }

  async function loadDepots() {
    const res = await api.getDepots();
    if (res.ok && Array.isArray(res.data)) setDepots(res.data);
  }

  async function loadVehicles() {
    const res = await api.getFleet();
    if (res.ok && Array.isArray(res.data)) setVehicles(res.data);
  }

  async function loadGroups() {
    const res = await api.getGroups();
    if (res.ok && Array.isArray(res.data)) setGroups(res.data);
  }

  // Helper function to extract district from address
  function extractDistrictFromAddress(address) {
    if (!address) return null;
    const match = address.match(/Quận\s*(\d+)|Q\.?\s*(\d+)/i);
    if (match) return `Quận ${match[1] || match[2]}`;
    const districts = [
      'Quận 1', 'Quận 2', 'Quận 3', 'Quận 4', 'Quận 5',
      'Quận 6', 'Quận 7', 'Quận 8', 'Quận 9', 'Quận 10',
      'Quận 11', 'Quận 12', 'Bình Thạnh', 'Tân Bình', 'Tân Phú',
      'Phú Nhuận', 'Gò Vấp', 'Bình Tân', 'Thủ Đức'
    ];
    for (const dist of districts) {
      if (address.includes(dist)) return dist;
    }
    return null;
  }

  // Helper function để generate group name prefix từ operating area
  function getGroupPrefix(operatingArea) {
    if (!operatingArea) return "GRP";
    
    const prefixMap = {
      "Bình Thạnh": "A",
      "Bình Tân": "B",
      "Tân Bình": "T",
      "Tân Phú": "TP",
      "Phú Nhuận": "PN",
      "Gò Vấp": "GV",
      "Thủ Đức": "TD",
    };
    
    // Xử lý Quận 1-12
    const quanMatch = operatingArea.match(/Quận\s*(\d+)/);
    if (quanMatch) {
      return `Q${quanMatch[1]}`;
    }
    
    return prefixMap[operatingArea] || operatingArea.substring(0, 2).toUpperCase();
  }

  // Helper function để get next group number cho khu vực
  async function getNextGroupNumber(operatingArea, depotId = null) {
    try {
      const prefix = getGroupPrefix(operatingArea);
      const res = await api.getGroups({ operating_area: operatingArea, status: "active" });
      
      if (res.ok && Array.isArray(res.data)) {
        // Lọc groups theo prefix
        const existingGroups = res.data
          .filter(g => {
            const namePrefix = getGroupPrefix(g.operating_area);
            return namePrefix === prefix;
          })
          .map(g => {
            // Extract number from name (A01, B02, Q1-01, etc.)
            const match = g.name?.match(/(\d+)$/);
            return match ? parseInt(match[1]) : 0;
          })
          .filter(n => !isNaN(n) && n > 0)
          .sort((a, b) => b - a);
        
        const nextNum = existingGroups.length > 0 ? existingGroups[0] + 1 : 1;
        return nextNum.toString().padStart(2, "0");
      }
      return "01";
    } catch (error) {
      console.error("Error getting next group number:", error);
      return "01";
    }
  }

  function handleAdd() {
    setEditItem({
      id: "",
      name: "",
      role: "collector", // ✅ Luôn là nhân viên thu gom (không thay đổi)
      phone: "",
      email: "",
      address: "",
      password: "123456", // Default password
      status: "active",
      depot_id: "",
      operating_area: "",
    });
    setModalOpen(true);
  }

  function handleEdit(item) {
    setEditItem({
      ...item,
      role: "collector", // ✅ Luôn là nhân viên thu gom (không thay đổi)
      depot_id: item.depot_id || "",
      operating_area: item.meta?.operating_area || (item.depot_address ? extractDistrictFromAddress(item.depot_address) : ""),
    });
    setModalOpen(true);
  }

  async function handleAddGroup() {
    setEditItem({
      id: "",
      name: "",
      code: "",
      description: "",
      vehicle_id: "",
      depot_id: "",
      operating_area: "",
      member_ids: [],
      leader_id: "",
    });
    setModalOpen(true);
  }

  // Auto-update group name khi chọn operating area
  useEffect(() => {
    if (activeTab === "groups" && editItem?.operating_area && !editItem?.id) {
      const updateGroupName = async () => {
        const prefix = getGroupPrefix(editItem.operating_area);
        const nextNum = await getNextGroupNumber(editItem.operating_area, editItem.depot_id);
        const newName = `${prefix}${nextNum}`;
        
        if (editItem.name !== newName) {
          setEditItem({ ...editItem, name: newName });
        }
      };
      
      updateGroupName();
    }
  }, [editItem?.operating_area, editItem?.depot_id, activeTab]);

  // Auto-assign personnel khi chọn operating area và depot
  useEffect(() => {
    if (
      activeTab === "groups" &&
      autoAssignEnabled &&
      editItem?.operating_area &&
      editItem?.depot_id &&
      personnel.length > 0 &&
      (!editItem.member_ids || editItem.member_ids.length === 0)
    ) {
      // Tìm nhân viên cùng khu vực và trạm
      const matchingPersonnel = personnel.filter(p => {
        const pArea = p.meta?.operating_area || 
                      (p.depot_address ? extractDistrictFromAddress(p.depot_address) : null);
        return (
          p.status === "active" &&
          pArea === editItem.operating_area &&
          p.depot_id === editItem.depot_id
        );
      });
      
      if (matchingPersonnel.length > 0) {
        const memberIds = matchingPersonnel.map(p => p.id);
        const firstMember = matchingPersonnel[0];
        
        setEditItem({
          ...editItem,
          member_ids: memberIds,
          leader_id: firstMember.id, // Auto-select first member as leader
        });
      }
    }
  }, [editItem?.operating_area, editItem?.depot_id, personnel, autoAssignEnabled, activeTab]);

  // Function để auto-create groups
  async function handleAutoCreateGroups() {
    try {
      const confirmed = window.confirm(
        "Bạn có chắc muốn tự động tạo nhóm từ nhân viên hiện có?\n\n" +
        "Hệ thống sẽ:\n" +
        "- Nhóm nhân viên theo khu vực hoạt động và trạm\n" +
        "- Tạo nhóm tự động với tên theo quy tắc (VD: A01, B01, Q1-01...)\n" +
        "- Tự động chọn trưởng nhóm (nhân viên đầu tiên)\n\n" +
        "Lưu ý: Chỉ tạo nhóm cho nhân viên có khu vực hoạt động rõ ràng."
      );
      
      if (!confirmed) return;
      
      const res = await api.autoCreateGroups();
      if (res.ok) {
        setToast({
          message: `✅ Đã tạo ${res.data?.created || 0} nhóm từ nhân viên`,
          type: "success",
        });
        loadGroups();
        loadPersonnel(); // Reload để refresh data
      } else {
        setToast({ message: res.error || "Tạo nhóm tự động thất bại", type: "error" });
      }
    } catch (error) {
      setToast({ message: "Lỗi: " + error.message, type: "error" });
    }
  }

  function handleEditGroup(group) {
    // Load group details with members
    api.getGroup(group.id).then((res) => {
      if (res.ok) {
        const groupData = res.data;
        setEditItem({
          ...groupData,
          member_ids: groupData.members?.map((m) => m.personnel_id) || [],
          leader_id: groupData.members?.find((m) => m.role_in_group === "leader")?.personnel_id || "",
        });
        setModalOpen(true);
      }
    });
  }

  async function handleSave() {
    try {
      // Prepare meta object
      const meta = {
        operating_area: editItem.operating_area || "",
      };

      if (editItem.id) {
        // Update existing
        const res = await api.updatePersonnel(editItem.id, {
          name: editItem.name,
          role: "collector", // ✅ Luôn là nhân viên thu gom
          phone: editItem.phone,
          email: editItem.email,
          status: editItem.status,
          depot_id: editItem.depot_id || null,
          meta: meta,
        });
        if (res.ok) {
          setModalOpen(false);
          setToast({ message: "Đã cập nhật nhân sự", type: "success" });
          loadPersonnel();
        } else {
          setToast({
            message: res.error || "Cập nhật thất bại",
            type: "error",
          });
        }
      } else {
        // Create new - include all fields
        const res = await api.createPersonnel({
          name: editItem.name,
          role: "collector", // ✅ Luôn là nhân viên thu gom
          phone: editItem.phone,
          email: editItem.email,
          address: editItem.address || "",
          password: editItem.password || "123456",
          status: editItem.status,
          depot_id: editItem.depot_id || null,
          meta: meta,
        });
        if (res.ok) {
          setModalOpen(false);
          setToast({
            message:
              res.message ||
              `Đã tạo tài khoản. Email: ${editItem.email}, Password: ${
                editItem.password || "123456"
              }`,
            type: "success",
          });
          loadPersonnel();
        } else {
          setToast({ message: res.error || "Tạo thất bại", type: "error" });
        }
      }
    } catch (error) {
      setToast({ message: "Lỗi: " + error.message, type: "error" });
    }
  }

  async function handleSaveGroup() {
    try {
      const { member_ids, leader_id, ...groupData } = editItem;

      if (editItem.id) {
        // Update existing
        const res = await api.updateGroup(editItem.id, groupData);
        if (res.ok) {
          setModalOpen(false);
          setToast({ message: "Đã cập nhật nhóm", type: "success" });
          loadGroups();
        } else {
          setToast({ message: res.error || "Cập nhật thất bại", type: "error" });
        }
      } else {
        // Create new
        const res = await api.createGroup({
          ...groupData,
          member_ids: member_ids || [],
          leader_id: leader_id || null,
        });
        if (res.ok) {
          setModalOpen(false);
          setToast({ message: "Đã tạo nhóm", type: "success" });
          loadGroups();
        } else {
          setToast({ message: res.error || "Tạo thất bại", type: "error" });
        }
      }
    } catch (error) {
      setToast({ message: "Lỗi: " + error.message, type: "error" });
    }
  }

  const columns = [
    { key: "name", label: "Họ tên" },
    {
      key: "email",
      label: "Email",
      render: (r) => r.email || "-",
    },
    {
      key: "phone",
      label: "SĐT",
      render: (r) => r.phone || "-",
    },
    {
      key: "role",
      label: "Vai trò",
      render: (r) => "Nhân viên thu gom", // ✅ Luôn hiển thị "Nhân viên thu gom"
    },
    {
      key: "depot_name",
      label: "Trạm",
      render: (r) => r.depot_name || "-",
    },
    {
      key: "operating_area",
      label: "Khu vực hoạt động",
      render: (r) => {
        const area = r.meta?.operating_area || 
                     (r.depot_address ? extractDistrictFromAddress(r.depot_address) : null);
        return area || "-";
      },
    },
    {
      key: "status",
      label: "Trạng thái",
      render: (r) => {
        const statusMap = {
          active: "Hoạt động",
          inactive: "Không hoạt động",
          on_leave: "Nghỉ phép",
        };
        return statusMap[r.status] || r.status;
      },
    },
    {
      key: "action",
      label: "Hành động",
      render: (r) => (
        <div style={{ display: "flex", gap: 8 }}>
          <button
            className="btn btn-sm"
            onClick={() => handleEdit(r)}
            style={{ backgroundColor: "#2196f3", color: "white" }}
          >
            Sửa
          </button>
          {r.status === "active" && (
            <button
              className="btn btn-sm"
              onClick={async () => {
                const res = await api.deletePersonnel(r.id);
                if (res.ok) {
                  setToast({
                    message: "Đã vô hiệu hóa nhân sự",
                    type: "success",
                  });
                  loadPersonnel();
                } else {
                  setToast({
                    message: res.error || "Vô hiệu hóa thất bại",
                    type: "error",
                  });
                }
              }}
              style={{ backgroundColor: "#f44336", color: "white" }}
            >
              Vô hiệu hóa
            </button>
          )}
        </div>
      ),
    },
  ];

  const groupColumns = [
    { key: "name", label: "Tên nhóm" },
    {
      key: "code",
      label: "Mã nhóm",
      render: (r) => r.code || "-",
    },
    {
      key: "vehicle_plate",
      label: "Xe",
      render: (r) => r.vehicle_plate || "-",
    },
    {
      key: "depot_name",
      label: "Trạm",
      render: (r) => r.depot_name || "-",
    },
    {
      key: "operating_area",
      label: "Khu vực",
      render: (r) => r.operating_area || "-",
    },
    {
      key: "member_count",
      label: "Số thành viên",
      render: (r) => r.member_count || 0,
    },
    {
      key: "status",
      label: "Trạng thái",
      render: (r) => {
        const statusMap = {
          active: "Hoạt động",
          inactive: "Không hoạt động",
          archived: "Lưu trữ",
        };
        return statusMap[r.status] || r.status;
      },
    },
    {
      key: "action",
      label: "Hành động",
      render: (r) => (
        <div style={{ display: "flex", gap: 8 }}>
          <button
            className="btn btn-sm"
            onClick={() => handleEditGroup(r)}
            style={{ backgroundColor: "#2196f3", color: "white" }}
          >
            Sửa
          </button>
          {r.status === "active" && (
            <button
              className="btn btn-sm"
              onClick={async () => {
                const res = await api.deleteGroup(r.id);
                if (res.ok) {
                  setToast({ message: "Đã vô hiệu hóa nhóm", type: "success" });
                  loadGroups();
                } else {
                  setToast({ message: res.error || "Vô hiệu hóa thất bại", type: "error" });
                }
              }}
              style={{ backgroundColor: "#f44336", color: "white" }}
            >
              Vô hiệu hóa
            </button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <div style={{ marginBottom: 16 }}>
              <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>Quản lý nhân sự</h1>
              
              {/* Tabs */}
              <div style={{ display: "flex", gap: 8, borderBottom: "2px solid #e0e0e0", marginBottom: 16 }}>
                <button
                  onClick={() => setActiveTab("personnel")}
                  style={{
                    padding: "10px 20px",
                    border: "none",
                    background: "none",
                    cursor: "pointer",
                    fontSize: 14,
                    fontWeight: activeTab === "personnel" ? 600 : 400,
                    color: activeTab === "personnel" ? "#2196f3" : "#666",
                    borderBottom: activeTab === "personnel" ? "2px solid #2196f3" : "2px solid transparent",
                    marginBottom: -2,
                  }}
                >
                  Nhân sự
                </button>
                <button
                  onClick={() => setActiveTab("groups")}
                  style={{
                    padding: "10px 20px",
                    border: "none",
                    background: "none",
                    cursor: "pointer",
                    fontSize: 14,
                    fontWeight: activeTab === "groups" ? 600 : 400,
                    color: activeTab === "groups" ? "#2196f3" : "#666",
                    borderBottom: activeTab === "groups" ? "2px solid #2196f3" : "2px solid transparent",
                    marginBottom: -2,
                  }}
                >
                  Nhóm
                </button>
              </div>

              {/* Action Button */}
              <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, marginBottom: 16 }}>
                {activeTab === "personnel" ? (
                  <button className="btn btn-primary" onClick={handleAdd}>
                    + Tạo tài khoản nhân viên
                  </button>
                ) : (
                  <>
                    <button 
                      className="btn btn-secondary" 
                      onClick={handleAutoCreateGroups}
                      style={{ backgroundColor: "#4CAF50", color: "white" }}
                    >
                      🔄 Tự động tạo nhóm từ nhân viên
                    </button>
                    <button className="btn btn-primary" onClick={handleAddGroup}>
                      + Tạo nhóm mới
                    </button>
                  </>
                )}
              </div>
            </div>
            <div className="card">
              {activeTab === "personnel" ? (
                <Table
                  columns={columns}
                  data={personnel}
                  emptyText="Không có nhân sự"
                />
              ) : (
                <Table
                  columns={groupColumns}
                  data={groups}
                  emptyText="Không có nhóm"
                />
              )}
            </div>
          </div>
        </main>
      </div>
      <FormModal
        open={modalOpen}
        title={activeTab === "personnel" ? "Nhân sự" : "Nhóm"}
        onClose={() => setModalOpen(false)}
        onSubmit={activeTab === "personnel" ? handleSave : handleSaveGroup}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {activeTab === "groups" ? (
            // Group Form
            <>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Tên nhóm *
                </label>
                <input
                  type="text"
                  value={editItem?.name || ""}
                  onChange={(e) => setEditItem({ ...editItem, name: e.target.value })}
                  placeholder={editItem?.operating_area ? "Tự động tạo theo khu vực" : "Chọn khu vực trước"}
                  style={{ 
                    width: "100%", 
                    padding: "8px 12px", 
                    border: "1px solid #ccc", 
                    borderRadius: 6,
                    backgroundColor: editItem?.operating_area && !editItem?.id ? "#f5f5f5" : "white",
                    color: editItem?.operating_area && !editItem?.id ? "#666" : "#000"
                  }}
                  readOnly={!!(editItem?.operating_area && !editItem?.id)}
                  required
                />
                {editItem?.operating_area && !editItem?.id && (
                  <div style={{ fontSize: 12, color: "#666", marginTop: 4 }}>
                    Tên nhóm tự động: {getGroupPrefix(editItem.operating_area)}XX (XX = số thứ tự)
                  </div>
                )}
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Mã nhóm
                </label>
                <input
                  type="text"
                  value={editItem?.code || ""}
                  onChange={(e) => setEditItem({ ...editItem, code: e.target.value })}
                  placeholder="Tự động tạo nếu để trống"
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6, backgroundColor: "#f5f5f5" }}
                  readOnly
                />
                <div style={{ fontSize: 12, color: "#666", marginTop: 4 }}>
                  Mã nhóm sẽ tự động được tạo (VD: GRP-001-2025-01-28)
                </div>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Xe
                </label>
                <select
                  value={editItem?.vehicle_id || ""}
                  onChange={(e) => setEditItem({ ...editItem, vehicle_id: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                >
                  <option value="">-- Chọn xe (tùy chọn) --</option>
                  {vehicles.map((v) => (
                    <option key={v.id} value={v.id}>
                      {v.plate} - {v.type}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Trạm
                </label>
                <select
                  value={editItem?.depot_id || ""}
                  onChange={(e) => setEditItem({ ...editItem, depot_id: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                >
                  <option value="">-- Chọn trạm (tùy chọn) --</option>
                  {depots.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Khu vực hoạt động
                </label>
                <select
                  value={editItem?.operating_area || ""}
                  onChange={(e) => setEditItem({ ...editItem, operating_area: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                >
                  <option value="">-- Chọn khu vực --</option>
                  <option value="Quận 1">Quận 1</option>
                  <option value="Quận 2">Quận 2</option>
                  <option value="Quận 3">Quận 3</option>
                  <option value="Quận 4">Quận 4</option>
                  <option value="Quận 5">Quận 5</option>
                  <option value="Quận 6">Quận 6</option>
                  <option value="Quận 7">Quận 7</option>
                  <option value="Quận 8">Quận 8</option>
                  <option value="Quận 9">Quận 9</option>
                  <option value="Quận 10">Quận 10</option>
                  <option value="Quận 11">Quận 11</option>
                  <option value="Quận 12">Quận 12</option>
                  <option value="Bình Thạnh">Bình Thạnh</option>
                  <option value="Tân Bình">Tân Bình</option>
                  <option value="Tân Phú">Tân Phú</option>
                  <option value="Phú Nhuận">Phú Nhuận</option>
                  <option value="Gò Vấp">Gò Vấp</option>
                  <option value="Bình Tân">Bình Tân</option>
                  <option value="Thủ Đức">Thủ Đức</option>
                </select>
              </div>
              <div>
                <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={autoAssignEnabled}
                    onChange={(e) => setAutoAssignEnabled(e.target.checked)}
                    style={{ width: 16, height: 16 }}
                  />
                  <span style={{ fontSize: 14 }}>Tự động thêm nhân viên cùng khu vực và trạm</span>
                </label>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Mô tả
                </label>
                <textarea
                  value={editItem?.description || ""}
                  onChange={(e) => setEditItem({ ...editItem, description: e.target.value })}
                  placeholder="Mô tả về nhóm..."
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6, minHeight: 60 }}
                />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Thành viên
                </label>
                <select
                  multiple
                  value={editItem?.member_ids || []}
                  onChange={(e) => {
                    const selected = Array.from(e.target.selectedOptions, (option) => option.value);
                    setEditItem({ ...editItem, member_ids: selected });
                  }}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6, minHeight: 120 }}
                >
                  {personnel
                    .filter((p) => p.status === "active")
                    .map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.name} {p.email ? `(${p.email})` : ""}
                      </option>
                    ))}
                </select>
                <div style={{ fontSize: 12, color: "#666", marginTop: 4 }}>
                  Chọn nhiều thành viên (Ctrl+Click hoặc Cmd+Click). Chọn trưởng nhóm bên dưới.
                </div>
              </div>
              {editItem?.member_ids && editItem.member_ids.length > 0 && (
                <div>
                  <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                    Trưởng nhóm
                  </label>
                  <select
                    value={editItem?.leader_id || ""}
                    onChange={(e) => setEditItem({ ...editItem, leader_id: e.target.value })}
                    style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                  >
                    <option value="">-- Chọn trưởng nhóm --</option>
                    {editItem.member_ids.map((memberId) => {
                      const member = personnel.find((p) => p.id === memberId);
                      return member ? (
                        <option key={memberId} value={memberId}>
                          {member.name}
                        </option>
                      ) : null;
                    })}
                  </select>
                </div>
              )}
            </>
          ) : (
            // Personnel Form
            <>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Họ tên
                </label>
                <input
                  type="text"
                  value={editItem?.name || ""}
                  onChange={(e) => setEditItem({ ...editItem, name: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Vai trò
                </label>
                <input
                  type="text"
                  value="Nhân viên thu gom"
                  readOnly
                  disabled
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6, backgroundColor: "#f5f5f5", color: "#666", cursor: "not-allowed" }}
                />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Trạm
                </label>
                <select
                  value={editItem?.depot_id || ""}
                  onChange={(e) => {
                    const selectedDepot = depots.find(d => d.id === e.target.value);
                    setEditItem({ 
                      ...editItem, 
                      depot_id: e.target.value,
                      operating_area: selectedDepot ? extractDistrictFromAddress(selectedDepot.address) : editItem?.operating_area || ""
                    });
                  }}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                >
                  <option value="">-- Chọn trạm (tùy chọn) --</option>
                  {depots.map(d => (
                    <option key={d.id} value={d.id}>{d.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Khu vực hoạt động
                </label>
                <select
                  value={editItem?.operating_area || ""}
                  onChange={(e) => setEditItem({ ...editItem, operating_area: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                >
                  <option value="">-- Chọn khu vực --</option>
                  <option value="Quận 1">Quận 1</option>
                  <option value="Quận 2">Quận 2</option>
                  <option value="Quận 3">Quận 3</option>
                  <option value="Quận 4">Quận 4</option>
                  <option value="Quận 5">Quận 5</option>
                  <option value="Quận 6">Quận 6</option>
                  <option value="Quận 7">Quận 7</option>
                  <option value="Quận 8">Quận 8</option>
                  <option value="Quận 9">Quận 9</option>
                  <option value="Quận 10">Quận 10</option>
                  <option value="Quận 11">Quận 11</option>
                  <option value="Quận 12">Quận 12</option>
                  <option value="Bình Thạnh">Bình Thạnh</option>
                  <option value="Tân Bình">Tân Bình</option>
                  <option value="Tân Phú">Tân Phú</option>
                  <option value="Phú Nhuận">Phú Nhuận</option>
                  <option value="Gò Vấp">Gò Vấp</option>
                  <option value="Bình Tân">Bình Tân</option>
                  <option value="Thủ Đức">Thủ Đức</option>
                </select>
                <div style={{ fontSize: 12, color: "#666", marginTop: 4 }}>
                  Khu vực hoạt động của nhân viên (có thể khác với trạm)
                </div>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Số điện thoại
                </label>
                <input
                  type="text"
                  value={editItem?.phone || ""}
                  onChange={(e) => setEditItem({ ...editItem, phone: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Email
                </label>
                <input
                  type="email"
                  value={editItem?.email || ""}
                  onChange={(e) => setEditItem({ ...editItem, email: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                  required
                />
              </div>
              {!editItem?.id && (
                <>
                  <div>
                    <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                      Mật khẩu đăng nhập
                      <span style={{ fontSize: 12, color: "#666", fontWeight: 400, marginLeft: 8 }}>
                        (Mặc định: 123456)
                      </span>
                    </label>
                    <input
                      type="text"
                      value={editItem?.password || ""}
                      onChange={(e) => setEditItem({ ...editItem, password: e.target.value })}
                      placeholder="123456"
                      style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                    />
                  </div>
                  <div>
                    <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                      Địa chỉ
                    </label>
                    <textarea
                      value={editItem?.address || ""}
                      onChange={(e) => setEditItem({ ...editItem, address: e.target.value })}
                      placeholder="Nhập địa chỉ nhân viên..."
                      style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6, minHeight: 60 }}
                    />
                  </div>
                </>
              )}
              <div>
                <label style={{ display: "block", marginBottom: 4, fontSize: 14, fontWeight: 500 }}>
                  Trạng thái
                </label>
                <select
                  value={editItem?.status || "active"}
                  onChange={(e) => setEditItem({ ...editItem, status: e.target.value })}
                  style={{ width: "100%", padding: "8px 12px", border: "1px solid #ccc", borderRadius: 6 }}
                >
                  <option value="active">Hoạt động</option>
                  <option value="inactive">Không hoạt động</option>
                  <option value="on_leave">Nghỉ phép</option>
                </select>
              </div>
              {!editItem?.id && (
                <div style={{ padding: "12px", backgroundColor: "#e3f2fd", borderRadius: 6, border: "1px solid #2196f3", fontSize: 13 }}>
                  <strong style={{ color: "#1976d2" }}>📝 Lưu ý:</strong>
                  <ul style={{ margin: "8px 0 0 20px", color: "#1565c0" }}>
                    <li>Hệ thống sẽ tạo tài khoản đăng nhập cho nhân viên</li>
                    <li>Email và số điện thoại sẽ dùng để đăng nhập</li>
                    <li>
                      Mật khẩu mặc định: <strong>123456</strong> (có thể thay đổi)
                    </li>
                    <li>Nhân viên có thể đăng nhập app mobile sau khi tạo</li>
                  </ul>
                </div>
              )}
            </>
          )}
        </div>
      </FormModal>
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}
