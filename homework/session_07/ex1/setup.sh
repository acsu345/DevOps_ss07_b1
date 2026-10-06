#!/usr/bin/env bash
# ==============================================================================
# Script: setup.sh
# Môt tả: Tạo người dùng sftp-user giới hạn và cấp quyền đọc file log tại /var/log/app-backup/
# Bài tập: Bài 1 - Quản lý người dùng giới hạn và Truyền tải dữ liệu qua SFTP trên Windows
# Session: DevOps Session 07
# ==============================================================================

set -euo pipefail

# Màu sắc hiển thị terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}   Bắt đầu thiết lập SFTP User & Thư mục Log Backup   ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. Kiểm tra quyền root / sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[LỖI] Script cần được chạy với quyền root hoặc sudo!${NC}"
  echo -e "Ví dụ: sudo bash setup.sh"
  exit 1
fi

USERNAME="sftp-user"
LOG_DIR="/var/log/app-backup"
LOG_FILE="${LOG_DIR}/backup-check.log"

# 2. Tạo tài khoản người dùng sftp-user nếu chưa tồn tại
if id "$USERNAME" &>/dev/null; then
    echo -e "${YELLOW}[THÔNG BÁO] Người dùng '$USERNAME' đã tồn tại.${NC}"
else
    echo -e "${GREEN}[1/5] Đang tạo người dùng giới hạn '$USERNAME'...${NC}"
    # Tạo user không cấp quyền root/sudo
    useradd -m -s /bin/bash "$USERNAME"
    
    # Đặt mật khẩu mặc định an toàn cho sftp-user (có thể thay đổi sau)
    DEFAULT_PASS="SftpUser@Secure2026!"
    echo "$USERNAME:$DEFAULT_PASS" | chpasswd
    echo -e "${GREEN} -> Đã tạo tài khoản '$USERNAME' thành công.${NC}"
    echo -e "${YELLOW} -> Mật khẩu mặc định: ${DEFAULT_PASS}${NC}"
fi

# Đảm bảo sftp-user KHÔNG nằm trong nhóm sudo / wheel
echo -e "${GREEN}[2/5] Kiểm tra nhóm và quyền của '$USERNAME'...${NC}"
gpasswd -d "$USERNAME" sudo &>/dev/null || true
gpasswd -d "$USERNAME" wheel &>/dev/null || true

# 3. Tạo thư mục log giả lập
echo -e "${GREEN}[3/5] Khởi tạo thư mục và tệp tin log giả lập...${NC}"
mkdir -p "$LOG_DIR"

# Tạo file log với nội dung kiểm tra
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
echo "Backup status: SUCCESS at ${TIMESTAMP}" > "$LOG_FILE"
echo "System log check completed successfully." >> "$LOG_FILE"
echo "Log ID: LOG-SFTP-$(date +%s)" >> "$LOG_FILE"

# 4. Phân quyền truy cập
echo -e "${GREEN}[4/5] Phân quyền sở hữu và truy cập tệp tin...${NC}"
# Quyền sở hữu: root:sftp-user
chown -R root:"$USERNAME" "$LOG_DIR"

# Phân quyền thư mục: 750 (root full, sftp-user read+exec, other none)
chmod 750 "$LOG_DIR"

# Phân quyền tệp log: 640 (root read+write, sftp-user read, other none)
chmod 640 "$LOG_FILE"

# 5. Kiểm tra và xác nhận
echo -e "${GREEN}[5/5] Kiểm tra lại kết quả cài đặt...${NC}"
echo -e "${BLUE}-----------------------------------------------------${NC}"
echo -e "Thông tin User ID & Groups:"
id "$USERNAME"
echo -e "${BLUE}-----------------------------------------------------${NC}"
echo -e "Thông tin quyền truy cập tệp log:"
ls -ld "$LOG_DIR"
ls -l "$LOG_FILE"
echo -e "${BLUE}-----------------------------------------------------${NC}"
echo -e "Nội dung tệp log ($LOG_FILE):"
cat "$LOG_FILE"
echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN} Hoàn thành thiết lập! Bạn đã sẵn sàng kết nối SFTP trên Windows.${NC}"
echo -e "${BLUE}=====================================================${NC}"
