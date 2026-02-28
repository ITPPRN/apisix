#!/bin/bash

# ฟังก์ชันสร้าง Service
deploy_service() {
  local id=$1
  local client=$2
  local secret=$3
  local redirect=$4
  local logoutredi=$5

  local prefix=$(echo $id | cut -d'-' -f1)

  echo "Deploying Service: $id..."
  sed "s|{{KEYCLOAK_ISSUER}}|$KEYCLOAK_ISSUER|g; \
       s|{{KEYCLOAK_DISCOVERY}}|$KEYCLOAK_DISCOVERY|g; \
       s|{{CLIENT_ID}}|$client|g; \
       s|{{CLIENT_SECRET}}|$secret|g; \
       s|{{REDIRECT_URI}}|$redirect|g; \
       s|{{SERVICE_PREFIX}}|$prefix|g; \
       s|{{REDIRECT_URI_LOGOUT}}|$logoutredi|g" ./templates/template_base.json | \
  curl -s -X PUT "$APISIX_URL/apisix/admin/services/$id" \
  -H "X-API-KEY: $ADMIN_KEY" -H "Content-Type: application/json" -d @- | jq -r '.key'
}

# ฟังก์ชันสร้าง Upstream
deploy_upstream() {
  local id=$1
  local address=$2

  echo "Deploying Upstream: $id ($address)..."
  sed "s|{{UPSTREAM_ID}}|$id|g; s|{{NODE_ADDRESS}}|$address|g" ./templates/upstream_template.json | \
  curl -s -X PUT "$APISIX_URL/apisix/admin/upstreams/$id" \
  -H "X-API-KEY: $ADMIN_KEY" -H "Content-Type: application/json" -d @- | jq -r '.key'
}

# ฟังก์ชันสร้าง Route
deploy_route() {
  local id=$1
  local uri=$2
  local svc_id=$3
  local ups_id=$4

  echo "Deploying Route: $id ($uri)..."
  sed "s|{{URI}}|$uri|g; s|{{ROUTE_NAME}}|$id|g; s|{{SERVICE_ID}}|$svc_id|g; s|{{UPSTREAM_ID}}|$ups_id|g" ./templates/route_template.json | \
  curl -s -X PUT "$APISIX_URL/apisix/admin/routes/$id" \
  -H "X-API-KEY: $ADMIN_KEY" -H "Content-Type: application/json" -d @- | jq -r '.key'
}


deploy_frontend() {
  local id=$1              # เช่น p2p, kpi
  local uri=$2             # เช่น /p2p/*
  local target_address=$3  # เช่น 192.168.1.50:3001

  echo "Deploying Frontend: $id ($uri) -> $target_address..."
  
  # 1. สร้าง Upstream จาก Template
  sed "s|{{FRONT_ID}}|$id|g; s|{{TARGET_ADDRESS}}|$target_address|g" \
      ./templates/front_upstream_template.json | \
  curl -s -X PUT "$APISIX_URL/apisix/admin/upstreams/front-$id" \
  -H "X-API-KEY: $ADMIN_KEY" -H "Content-Type: application/json" -d @- | jq -r '.key'

  # 2. สร้าง Route จาก Template
  sed "s|{{FRONT_ID}}|$id|g; s|{{URI}}|$uri|g" \
      ./templates/front_route_template.json | \
  curl -s -X PUT "$APISIX_URL/apisix/admin/routes/front-route-$id" \
  -H "X-API-KEY: $ADMIN_KEY" -H "Content-Type: application/json" -d @- | jq -r '.key'
}