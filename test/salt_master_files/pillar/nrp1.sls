proxy:
  proxytype: nornir
  multiprocessing: True

hosts:
  ceos1:
    hostname: 10.0.1.4
    platform: arista_eos
    groups: [lab, eos_params]
    data:
      syslog: ["1.1.1.1", "2.2.2.2"]
      location: "North West Hall DC1"
    connection_options:
      pyats:
        extras:
          devices:
            ceos1:
              os: eos
              credentials:
                default:
                  username: nornir
                  password: nornir
              connections:
                default:
                  protocol: ssh
                  ip: 10.0.1.4
                  port: 22
                vty_1:
                  protocol: ssh
                  ip: 10.0.1.4
                  pool: 3
              
  ceos2:
    hostname: 10.0.1.5
    platform: arista_eos
    groups: [lab, eos_params]
    data:
      syslog: ["1.1.1.2", "2.2.2.1"]
      location: "East City Warehouse"
    connection_options:
      pyats:
        platform: eos
        extras:
          devices:
            ceos2: {}
            
groups: 
  lab:
    username: nornir
    password: nornir
    data:
      ntp_servers: ["3.3.3.3", "3.3.3.4"]
      syslog_servers: ["1.2.3.4", "4.3.2.1"]
  eos_params:
    connection_options:
      scrapli:
        platform: arista_eos
        extras:
          auth_strict_key: False
          ssh_config_file: False
      scrapli_netconf:
        port: 830
        extras:
          ssh_config_file: True
          auth_strict_key: False
          transport: paramiko
          transport_options: 
            # refer to https://github.com/saltstack/salt/issues/59962 for details
            # on why need netconf_force_pty False
            netconf_force_pty: False
      napalm:
        platform: eos
        extras:
          optional_args:
            transport: http
            port: 80  
      ncclient:
        port: 830
        extras:
          allow_agent: False
          hostkey_verify: False
      http:
        port: 6020
        extras:
          transport: https
          verify: False
          base_url: "restconf/data"
          headers:
            Content-Type: "application/yang-data+json"
            Accept: "application/yang-data+json"
      pygnmi:
        port: 6030
        extras:
          insecure: True
      ConnectionsPool:
        extras:
          max: 2
                
nornir:
  actions:
    awr: 
      function: nr.cli
      args: ["wr"]
      kwargs: {"FO": {"platform": "arista_eos"}}
      description: "Save Arista devices configuration"
    configure_ntp:
      - function: nr.cfg
        args: ["ntp server 1.1.1.1"]
        kwargs: {"FB": "*", "plugin": "netmiko"}
      - function: nr.cfg
        args: ["ntp server 1.1.1.2"]
        kwargs: {"FB": "*", "plugin": "netmiko"}
      - function: nr.cli
        args: ["show run | inc ntp"]
        kwargs: {"FB": "*"}
    configure_logging:
      function: nr.cfg
      args: ["logging host 7.7.7.7"]
      kwargs: {"plugin": "netmiko"}
    # nr.learn aliases
    arp:
      function: nr.cli
      args: ["show ip arp"]
      description: "Learn ARP cache"  
    uptime:
      function: nr.cli
      args: ["show uptime"]
      description: "Learn uptime info"      
    facts:
      function: nr.cli
      args: ["show version"]
      kwargs: {"run_ttp": "salt://ttp/ceos_show_version.txt"}
      description: "Learn device facts"  
    interfaces:
      function: nr.cli
      args: ["show run"]
      kwargs: {"run_ttp": "salt://ttp/ceos_interface.txt", "enable": True}
      description: "Learn device interfaces"  