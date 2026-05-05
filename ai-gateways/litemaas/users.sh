#!/bin/bash

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Function to create group if it doesn't exist
create_group_if_not_exists() {
  local group_name=$1
  if oc get group "$group_name" >/dev/null 2>&1; then
    echo -e "${YELLOW}Group '$group_name' already exists. Skipping creation.${NC}"
  else
    echo -e "${BLUE}Creating group '$group_name'...${NC}"
    oc adm groups new "$group_name"
    echo -e "${GREEN}Group '$group_name' created.${NC}"
  fi
}

# Function to add user to group if not already a member
add_user_to_group_if_not_exists() {
  local group_name=$1
  local username=$2
  
  if oc get group "$group_name" -o jsonpath='{.users[*]}' 2>/dev/null | grep -q "$username"; then
    echo -e "${YELLOW}User '$username' is already in group '$group_name'. Skipping.${NC}"
  else
    echo -e "${BLUE}Adding user '$username' to group '$group_name'...${NC}"
    oc adm groups add-users "$group_name" "$username"
    echo -e "${GREEN}User '$username' added to group '$group_name'.${NC}"
  fi
}

echo "**********************"
echo -e "${BLUE}=== Setting up LiteMaaS user groups ===${NC}"
echo "**********************"

# Create admin group
create_group_if_not_exists "litemaas-admins"
add_user_to_group_if_not_exists "litemaas-admins" "admin"

# Create read-only admin group
create_group_if_not_exists "litemaas-readonly"
add_user_to_group_if_not_exists "litemaas-readonly" "user1"

# Create users group (optional - users get this role by default)
create_group_if_not_exists "litemaas-users"
add_user_to_group_if_not_exists "litemaas-users" "user2"

echo "**********************"
echo -e "${GREEN}=== User group setup complete ===${NC}"
echo "**********************"
