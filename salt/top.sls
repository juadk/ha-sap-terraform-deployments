base:
{% if grains['provider'] != 'aws' %}
  '*':
    - default

  'role:hana_node':
    - match: grain
    - hana_node

{% else %}
  'role:iscsi_srv':
    - match: grain
    - iscsi_srv
    - iscsi.target

  'role:hana_node':
    - match: grain
    - default
    - hana_node
{% endif %}
