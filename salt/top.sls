base:
  'role:hana_node':
    - match: grain
    - ha_repos
    - default
    - hana_node

  'role:iscsi_srv':
    - match: grain
    - ha_repos
    - iscsi_srv
