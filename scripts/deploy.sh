#!/bin/bash

# 1. โหลดค่า Config และตัวแปรจาก .env
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | xargs)
else
  echo ".env not found!" && exit 1
fi

ADMIN_KEY="edd1c9f034335f136f87ad84b625c8f1"
APISIX_URL="http://127.0.0.1:9180"

# 2. Import ฟังก์ชันทั้งหมดเข้ามาใช้
source ./lib/functions.sh

echo "--- Start Deployment ---"

# deploy_frontend "test" "/test/*" "host.docker.internal:3001"
deploy_upstream "front-upstream" "host.docker.internal:3001"
# 3. สร้าง Upstream (เป้าหมายปลายทาง)
deploy_upstream "mock-upstream" "mock-backend:80"

deploy_service "front-p2p" "$SERVICE_P2P_CLIENT_ID" "$SERVICE_P2P_CLIENT_SECRET" "http://localhost:19080/front-p2p/callback" "http://localhost:19080/front-p2p/logout"

# 4. สร้าง Services (ตัวจัดการ Auth)
deploy_service "p2p-service" "$SERVICE_P2P_CLIENT_ID" "$SERVICE_P2P_CLIENT_SECRET" "http://localhost:19080/p2p/v1/callback" "http://localhost:19080/p2p/v1/logout"
deploy_service "kpi-service" "$SERVICE_KPI_CLIENT_ID" "$SERVICE_KPI_CLIENT_SECRET" "http://localhost:19080/kpi/callback" "http://localhost:19080/kpi/hello"
deploy_service "zen-service" "$SERVICE_ZEN_CLIENT_ID" "$SERVICE_ZEN_CLIENT_SECRET" "http://localhost:19080/zen/callback" "http://localhost:19080/zen/hello"

deploy_route "front-p2p-route" "/front-p2p/*" "front-p2p" "front-upstream"
# 5. สร้าง Routes (ตัวเปิดประตูรับ Traffic)
deploy_route "p2p-route" "/p2p/v1/*" "p2p-service" "mock-upstream"
deploy_route "kpi-route" "/kpi/v1/*" "kpi-service" "mock-upstream"
deploy_route "zen-route" "/zen/v1/*" "zen-service" "mock-upstream"

echo "--- Deployment Finished ---"