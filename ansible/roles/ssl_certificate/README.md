Role Name
=========

Reusable role that creates files needed for SSL Certificate (.crt + .csr + .key)

Requirements
------------

This role only creates files needed for SSL Certificates (.crt + .csr + .key). It does not reload or restart services. Adjust the order in which it runs, depending on your aplication.
 
Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

When using containers it is necessary to create a docker volume and map the respective paths so that the files are accessible to your aplication inside the container. 

Example Playbook
----------------

To use this Reusable Role - add the following code to your playbook and change the variables.

roles:
    - role: ssl_certificate
      vars:
        # Path to save SSL certificates and Keys on host
        # (Create a volume if using containers and map this 
        # path with the one used by your container)
        ssl_cert_path: /opt/webserver/nginx/ssl

        # Name of the files to create 
        # (ex: ssl_cert_name.crt + ssl_cert_name.csr + ssl_cert_name.key)
        ssl_cert_name: nginx_ssl_cert

        ssl_common_name: "{{ inventory_hostname }}"
        ssl_country: "PT"
        ssl_state: "Porto"
        ssl_locality: "Maia"
        ssl_org: "technova.pt"
        ssl_org_unit: "SysAdmin"

        ssl_valid_days: 365

        ssl_key_size: 2048
        ssl_force_regenerate: false

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
