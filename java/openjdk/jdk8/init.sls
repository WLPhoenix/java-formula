{% set java = salt['grains.filter_by']({
    'Debian': {
      'package': 'openjdk-8-jdk'
    },
    'RedHat': {
      'package': 'java-1.8.0-openjdk-devel'
    },
}) %}

include:
  - java.java_home

install_java:
  pkg:
    - installed
    - name: {{ java.package }}

/usr/java/latest:
  file:
    - symlink
    - target: /etc/alternatives/java_sdk
    - makedirs: true
