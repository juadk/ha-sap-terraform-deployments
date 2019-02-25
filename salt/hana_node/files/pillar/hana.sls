hana:
  nodes:
    - host: 'hana01'
      sid: 'prd'
      instance: '"00"'
      password: 'ENTER_YOUR_PASSWORD'
      install:
        software_path: '/root/sap_inst/'
        root_user: 'root'
        root_password: ''
        system_user_password: 'ENTER_YOUR_PASSWORD'
        extra_parameters:
          hostname: 'hana01'
       sapadm_password: 'ENTER_YOUR_PASSWORD'
      primary:
        name: MASTER
        backup:
          key_name: 'backupkey'
          database: 'SYSTEMDB'
          file: 'backup'
        userkey:
          key_name: 'backupkey'
          environment: 'hana01:30013'
          user_name: 'SYSTEM'
          user_password: 'ENTER_YOUR_PASSWORD'
          database: 'SYSTEMDB'

    - host: 'hana02'
      sid: 'prd'
      instance: '"00"'
      password: 'ENTER_YOUR_PASSWORD'
      install:
        software_path: '/root/sap_inst/51052481'
        root_user: 'root'
        root_password: ''
        system_user_password: 'ENTER_YOUR_PASSWORD'
        sapadm_password: 'ENTER_YOUR_PASSWORD'
        extra_parameters:
          hostname: 'hana02'
      secondary:
        name: SLAVE
        remote_host: 'hana01'
        remote_instance: '00'
        replication_mode: 'sync'
        operation_mode: 'logreplay'

    - host: hana02
      sid: 'qas'
      instance: '"01"'
      password: 'ENTER_YOUR_PASSWORD'
      install:
        software_path: '/root/sap_inst/51052481'
        root_user: 'root'
        root_password: 'linux'
        system_user_password: 'ENTER_YOUR_PASSWORD'
        sapadm_password: 'ENTER_YOUR_PASSWORD'
        extra_parameters:
          hostname: 'hana02'
