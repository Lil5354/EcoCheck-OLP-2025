/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Badges Management Tab
 */

import React, { useState, useEffect } from "react";
import api from "../../../lib/api.js";
import FormModal from "../../../components/common/FormModal.jsx";
import ConfirmDialog from "../../../components/common/ConfirmDialog.jsx";

// Helper function to check if string is emoji or URL/path
function isEmoji(str) {
  if (!str) return false;
  // Remove spaces and check if it's a single emoji character
  const trimmed = str.trim();
  // Emoji regex pattern
  const emojiRegex = /^[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]$/u;
  return emojiRegex.test(trimmed) || trimmed.length <= 2;
}

// Helper function to check if string is a URL or path
function isImagePath(str) {
  if (!str) return false;
  const trimmed = str.trim();
  
  // Check if it contains spaces or invalid characters (likely corrupted data)
  if (trimmed.includes(" ") || trimmed.length > 200) {
    return false;
  }
  
  return (
    trimmed.startsWith("http://") ||
    trimmed.startsWith("https://") ||
    (trimmed.startsWith("/") && !trimmed.includes(" ")) ||
    trimmed.startsWith("./") ||
    trimmed.endsWith(".png") ||
    trimmed.endsWith(".jpg") ||
    trimmed.endsWith(".jpeg") ||
    trimmed.endsWith(".gif") ||
    trimmed.endsWith(".svg") ||
    trimmed.endsWith(".webp")
  );
}

// Helper component to render badge icon
function BadgeIcon({ icon_url, name, size = "3rem" }) {
  const [imageError, setImageError] = useState(false);
  const [imageLoading, setImageLoading] = useState(true);

  // If no icon_url, show default emoji
  if (!icon_url || icon_url.trim() === "") {
    return <span style={{ fontSize: size }}>🏆</span>;
  }

  const trimmedIcon = icon_url.trim();

  // If it's an image path/URL, try to render as image
  if (isImagePath(trimmedIcon)) {
    return (
      <div style={{ position: "relative", width: size, height: size }}>
        {imageLoading && !imageError && (
          <span style={{ fontSize: size, opacity: 0.3 }}>🏆</span>
        )}
        <img
          src={trimmedIcon}
          alt={name}
          style={{
            width: size,
            height: size,
            objectFit: "contain",
            display: imageError ? "none" : "block",
            position: imageLoading ? "absolute" : "static",
            top: 0,
            left: 0,
          }}
          onLoad={() => {
            setImageLoading(false);
            setImageError(false);
          }}
          onError={() => {
            setImageError(true);
            setImageLoading(false);
          }}
        />
        {imageError && (
          <span style={{ fontSize: size, display: "block" }}>🏆</span>
        )}
      </div>
    );
  }

  // If it's likely an emoji (short string, no path indicators)
  if (trimmedIcon.length <= 5 && !trimmedIcon.includes("/") && !trimmedIcon.includes(".")) {
    return <span style={{ fontSize: size }}>{trimmedIcon}</span>;
  }

  // If it looks like corrupted path/text, show default emoji instead
  return <span style={{ fontSize: size }}>🏆</span>;
}

export default function BadgesTab({ showToast }) {
  const [loading, setLoading] = useState(true);
  const [badges, setBadges] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedBadge, setSelectedBadge] = useState(null);
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    icon_url: "🏆",
    points_reward: 0,
    rarity: "common",
    active: true,
  });

  useEffect(() => {
    loadBadges();
    loadAnalytics();
  }, []);

  async function loadBadges() {
    setLoading(true);
    try {
      const res = await api.getBadges();
      if (res.ok) {
        setBadges(res.data || []);
      } else {
        showToast(res.error || "Lỗi tải danh sách huy hiệu", "error");
      }
    } catch (error) {
      showToast("Lỗi: " + error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  async function loadAnalytics() {
    try {
      const res = await api.getBadgeAnalytics();
      console.log("📊 Badge Analytics API response:", res);
      if (res.ok) {
        console.log("📊 Badge Analytics data:", res.data);
        console.log("📊 Statistics:", res.data?.statistics);
        setAnalytics(res.data);
      } else {
        console.error("📊 Badge Analytics API error:", res);
      }
    } catch (error) {
      console.error("Error loading analytics:", error);
    }
  }

  function handleEditBadge(badge) {
    setSelectedBadge(badge);
    setFormData({
      name: badge.name || "",
      description: badge.description || "",
      icon_url: badge.icon_url || "🏆",
      points_reward: badge.points_reward || 0,
      rarity: badge.rarity || "common",
      active: badge.active !== undefined ? badge.active : true,
    });
    setModalOpen(true);
  }

  function handleCreateBadge() {
    setSelectedBadge(null);
    setFormData({
      name: "",
      description: "",
      icon_url: "🏆",
      points_reward: 0,
      rarity: "common",
      active: true,
    });
    setModalOpen(true);
  }

  async function handleSaveBadge() {
    if (!formData.name || !formData.description) {
      showToast("Vui lòng điền đầy đủ thông tin", "error");
      return;
    }

    try {
      let res;
      if (selectedBadge) {
        res = await api.updateBadge(selectedBadge.id, formData);
      } else {
        res = await api.createBadge(formData);
      }

      if (res.ok) {
        showToast(
          selectedBadge ? "Cập nhật huy hiệu thành công" : "Tạo huy hiệu thành công",
          "success"
        );
        setModalOpen(false);
        loadBadges();
        loadAnalytics();
      } else {
        showToast(res.error || "Thất bại", "error");
      }
    } catch (error) {
      showToast("Lỗi: " + error.message, "error");
    }
  }

  async function handleDeleteBadge() {
    if (!selectedBadge) return;

    try {
      const res = await api.deleteBadge(selectedBadge.id);
      if (res.ok) {
        showToast("Xóa huy hiệu thành công", "success");
        setDeleteDialogOpen(false);
        setSelectedBadge(null);
        loadBadges();
        loadAnalytics();
      } else {
        showToast(res.error || "Xóa huy hiệu thất bại", "error");
      }
    } catch (error) {
      showToast("Lỗi: " + error.message, "error");
    }
  }

  const getRarityColor = (rarity) => {
    const colors = {
      common: "#94a3b8",
      rare: "#06b6d4",
      epic: "#8b5cf6",
      legendary: "#fbbf24",
    };
    return colors[rarity] || "#94a3b8";
  };

  if (loading) {
    return (
      <div style={{ textAlign: "center", padding: "4rem 0" }}>
        <div>Đang tải dữ liệu...</div>
      </div>
    );
  }

  const activeBadges = badges.filter((b) => b.active !== false);
  const inactiveBadges = badges.filter((b) => b.active === false);

  return (
    <div>
      {/* Header Actions */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "1.5rem",
        }}
      >
        <h2 style={{ margin: 0, fontSize: "1.25rem", fontWeight: "600" }}>
          Quản lý huy hiệu
        </h2>
        <button
          onClick={handleCreateBadge}
          style={{
            padding: "0.75rem 1.5rem",
            background: "#22c55e",
            color: "white",
            border: "none",
            borderRadius: "4px",
            cursor: "pointer",
            fontSize: "0.875rem",
            fontWeight: "500",
          }}
        >
          + Tạo huy hiệu mới
        </button>
      </div>

      {/* Analytics */}
      {analytics && (
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
            gap: "1rem",
            marginBottom: "1.5rem",
          }}
        >
          <div
            style={{
              padding: "1rem",
              background: "white",
              borderRadius: "8px",
              boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            }}
          >
            <div style={{ color: "#666", fontSize: "0.875rem" }}>Tổng số huy hiệu</div>
            <div style={{ fontSize: "1.5rem", fontWeight: "bold", color: "#1976d2" }}>
              {analytics.statistics?.totalBadges || 0}
            </div>
          </div>
          <div
            style={{
              padding: "1rem",
              background: "white",
              borderRadius: "8px",
              boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            }}
          >
            <div style={{ color: "#666", fontSize: "0.875rem" }}>Users có huy hiệu</div>
            <div style={{ fontSize: "1.5rem", fontWeight: "bold", color: "#22c55e" }}>
              {analytics.statistics?.usersWithBadges || 0}
            </div>
          </div>
          <div
            style={{
              padding: "1rem",
              background: "white",
              borderRadius: "8px",
              boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            }}
          >
            <div style={{ color: "#666", fontSize: "0.875rem" }}>Tổng số unlock</div>
            <div style={{ fontSize: "1.5rem", fontWeight: "bold", color: "#f59e0b" }}>
              {analytics.statistics?.totalUnlocks || 0}
            </div>
          </div>
        </div>
      )}

      {/* Most Unlocked Badges */}
      {analytics?.mostUnlocked && analytics.mostUnlocked.length > 0 && (
        <div
          style={{
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            padding: "1.5rem",
            marginBottom: "1.5rem",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", fontSize: "1.125rem", fontWeight: "600" }}>
            Huy hiệu được unlock nhiều nhất
          </h3>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
              gap: "1rem",
            }}
          >
            {analytics.mostUnlocked.slice(0, 5).map((badge) => (
              <div
                key={badge.id}
                style={{
                  padding: "1rem",
                  background: "#f9fafb",
                  borderRadius: "8px",
                  border: "1px solid #e5e7eb",
                }}
              >
                <div
                  style={{
                    marginBottom: "0.5rem",
                    width: "64px",
                    height: "64px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  <BadgeIcon icon_url={badge.icon_url || badge.icon} name={badge.name} size="3rem" />
                </div>
                <div style={{ fontWeight: "600", marginBottom: "0.25rem" }}>{badge.name}</div>
                <div style={{ color: "#666", fontSize: "0.875rem" }}>
                  {badge.unlockCount} unlocks
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Active Badges */}
      <div
        style={{
          background: "white",
          borderRadius: "8px",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          padding: "1.5rem",
          marginBottom: "1.5rem",
        }}
      >
        <h3 style={{ margin: "0 0 1rem 0", fontSize: "1.125rem", fontWeight: "600" }}>
          Huy hiệu đang hoạt động ({activeBadges.length})
        </h3>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(250px, 1fr))",
            gap: "1rem",
          }}
        >
          {activeBadges.map((badge) => (
            <div
              key={badge.id}
              style={{
                padding: "1.5rem",
                background: "#f9fafb",
                borderRadius: "8px",
                border: "1px solid #e5e7eb",
                position: "relative",
              }}
            >
              <div style={{ display: "flex", alignItems: "start", gap: "1rem" }}>
                <div
                  style={{
                    width: "64px",
                    height: "64px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flexShrink: 0,
                  }}
                >
                  <BadgeIcon icon_url={badge.icon_url} name={badge.name} size="64px" />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: "600", marginBottom: "0.25rem", fontSize: "1rem" }}>
                    {badge.name}
                  </div>
                  <div style={{ color: "#666", fontSize: "0.875rem", marginBottom: "0.5rem" }}>
                    {badge.description}
                  </div>
                  <div
                    style={{
                      display: "flex",
                      gap: "0.5rem",
                      alignItems: "center",
                      marginBottom: "0.5rem",
                    }}
                  >
                    <span
                      style={{
                        padding: "0.25rem 0.75rem",
                        borderRadius: "12px",
                        fontSize: "0.75rem",
                        fontWeight: "500",
                        background: `${getRarityColor(badge.rarity)}20`,
                        color: getRarityColor(badge.rarity),
                      }}
                    >
                      {badge.rarity}
                    </span>
                    <span style={{ fontSize: "0.875rem", color: "#666" }}>
                      {badge.points_reward} điểm
                    </span>
                  </div>
                  <div style={{ display: "flex", gap: "0.5rem", marginTop: "0.75rem" }}>
                    <button
                      onClick={() => handleEditBadge(badge)}
                      style={{
                        padding: "0.5rem 1rem",
                        background: "#1976d2",
                        color: "white",
                        border: "none",
                        borderRadius: "4px",
                        cursor: "pointer",
                        fontSize: "0.875rem",
                      }}
                    >
                      Sửa
                    </button>
                    <button
                      onClick={() => {
                        setSelectedBadge(badge);
                        setDeleteDialogOpen(true);
                      }}
                      style={{
                        padding: "0.5rem 1rem",
                        background: "#ef4444",
                        color: "white",
                        border: "none",
                        borderRadius: "4px",
                        cursor: "pointer",
                        fontSize: "0.875rem",
                      }}
                    >
                      Xóa
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Inactive Badges */}
      {inactiveBadges.length > 0 && (
        <div
          style={{
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            padding: "1.5rem",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", fontSize: "1.125rem", fontWeight: "600" }}>
            Huy hiệu đã vô hiệu hóa ({inactiveBadges.length})
          </h3>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(250px, 1fr))",
              gap: "1rem",
            }}
          >
            {inactiveBadges.map((badge) => (
              <div
                key={badge.id}
                style={{
                  padding: "1.5rem",
                  background: "#f9fafb",
                  borderRadius: "8px",
                  border: "1px solid #e5e7eb",
                  opacity: 0.6,
                }}
              >
                <div style={{ display: "flex", alignItems: "start", gap: "1rem" }}>
                  <BadgeIcon icon_url={badge.icon_url} name={badge.name} size="3rem" />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: "600", marginBottom: "0.25rem", fontSize: "1rem" }}>
                      {badge.name}
                    </div>
                    <div style={{ color: "#666", fontSize: "0.875rem" }}>
                      {badge.description}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Badge Form Modal */}
      <FormModal
        open={modalOpen}
        title={selectedBadge ? "Sửa huy hiệu" : "Tạo huy hiệu mới"}
        onClose={() => {
          setModalOpen(false);
          setSelectedBadge(null);
        }}
        onSubmit={handleSaveBadge}
        submitLabel={selectedBadge ? "Cập nhật" : "Tạo mới"}
      >
          <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                Tên huy hiệu *
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="Nhập tên huy hiệu"
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                }}
              />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                Mô tả *
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Nhập mô tả"
                rows={3}
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                  resize: "vertical",
                }}
              />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                Icon (Emoji hoặc URL)
              </label>
              <input
                type="text"
                value={formData.icon_url}
                onChange={(e) => setFormData({ ...formData, icon_url: e.target.value })}
                placeholder="🏆 hoặc URL hình ảnh"
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                }}
              />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                Điểm yêu cầu
              </label>
              <input
                type="number"
                value={formData.points_reward}
                onChange={(e) =>
                  setFormData({ ...formData, points_reward: parseInt(e.target.value) || 0 })
                }
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                }}
              />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                Độ hiếm
              </label>
              <select
                value={formData.rarity}
                onChange={(e) => setFormData({ ...formData, rarity: e.target.value })}
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                }}
              >
                <option value="common">Common</option>
                <option value="rare">Rare</option>
                <option value="epic">Epic</option>
                <option value="legendary">Legendary</option>
              </select>
            </div>
            <div>
              <label style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                <input
                  type="checkbox"
                  checked={formData.active}
                  onChange={(e) => setFormData({ ...formData, active: e.target.checked })}
                />
                <span>Đang hoạt động</span>
              </label>
            </div>
          </div>
        </FormModal>

      {/* Delete Confirmation Dialog */}
      {deleteDialogOpen && (
        <ConfirmDialog
          title="Xác nhận xóa huy hiệu"
          message={`Bạn có chắc muốn xóa huy hiệu "${selectedBadge?.name}"?`}
          onConfirm={handleDeleteBadge}
          onCancel={() => {
            setDeleteDialogOpen(false);
            setSelectedBadge(null);
          }}
        />
      )}
    </div>
  );
}

