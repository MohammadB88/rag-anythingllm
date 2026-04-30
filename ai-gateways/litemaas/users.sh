#!/bin/bash


# Create admin group
oc adm groups new litemaas-admins
oc adm groups add-users litemaas-admins admin

# Create read-only admin group
oc adm groups new litemaas-readonly
oc adm groups add-users litemaas-readonly user1

# Create users group (optional - users get this role by default)
oc adm groups new litemaas-users
oc adm groups add-users litemaas-users user2
