iscsi-formula:
  pkg.installed:
    - fromrepo: saphana
    - require:
      - add-saphana-repo

move-iscsi-folder:
  cmd.run:
    - name: cp -R /srv/salt/iscsi /root/salt/
    - unless: file.path_exists_glob('/root/salt/iscsi')
