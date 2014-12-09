include:
  - java.java_home

{% if grains['os_family'] == 'Debian' %}

# add the oracle apt repository
java_repo:
  pkgrepo:
    - managed
    - ppa: webupd8team/java

# accept the license agreement for a headless install
java_installer_selections:
  cmd:
    - run
    - name: 'echo oracle-java6-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections'
    - require:
      - pkgrepo: java_repo

# ie, apt-get update
java_refresh_db:
  module:
    - run
    - name: pkg.refresh_db
    - require:
      - pkgrepo: java_repo

# install java
oracle-java8-installer:
  pkg:
    - installed
    - name: oracle-java8-installer
    - require:
      - cmd: java_installer_selections
      - module: java_refresh_db

# Create symlink so java can be found in a normal location
/usr/java/jdk1.8.0:
  file:
    - symlink
    - target: /usr/lib/jvm/java-8-oracle
    - makedirs: true
    - require:
      - pkg: oracle-java7-installer

# make the latest link
/usr/java/latest:
  file:
    - symlink
    - target: jdk1.8.0
    - require:
      - file: /usr/java/jdk1.8.0


{% elif grains['os_family'] == 'RedHat' %}

# Staging directory
{% set staging  = pillar.java.oracle.staging %}
{% set cookies  = pillar.java.oracle.cookies %}
{% set java_uri = pillar.java.oracle.jdk8.uri %}
{% set java_rpm = pillar.java.oracle.jdk8.rpm %}

init_staging:
  file:
    - directory
    - name: {{ staging }}
    - makedirs: true
    - clean: true

wget:
  pkg:
    - installed

download_java:
  cmd:
    - run
    - cwd: {{ staging }}
    - name: 'wget --no-check-certificate --header="Cookie: {{ cookies }}" -c "{{ java_uri }}" -O "{{ java_rpm }}.rpm"'
    - unless: 'rpm -qa | grep {{ java_rpm }}'
    - require:
      - pkg: wget
      - file: init_staging

install_java:
  cmd:
    - run
    - cwd: {{ staging }}
    - name: 'rpm -Uvh {{ java_rpm }}.rpm'
    - unless: 'rpm -qa | grep {{ java_rpm }}'
    - require:
      - cmd: download_java

set_alternatives:
  cmd:
    - run
    - cwd: {{ staging }}
    - name: 'alternatives --install /usr/bin/java java /usr/java/latest/bin/java 1000000'
    - onlyif: 'rpm -qa | grep {{ java_rpm }}'
    - require:
      - cmd: install_java

{% if pillar.java.enable_jce %}
{% set jce_uri = pillar.java.oracle.jce8.uri %}

download_jce:
  cmd:
    - run
    - cwd: {{ staging }}
    - name: 'wget --no-check-certificate --header="Cookie: {{ cookies }}" -c "{{ jce_uri }}" -O jce.zip'
    - require:
      - pkg: wget
      - file: init_staging

unzip_jce:
  cmd:
    - run
    - cwd: {{ staging }}
    - name: 'unzip -d jce jce.zip'
    - require:
      - cmd: download_jce

install_jce:
  cmd:
    - run
    - cwd: {{ staging }}
    - name: 'mv jce/*/*.jar /usr/java/latest/jre/lib/security'
    - require:
      - cmd: unzip_jce
{% endif %}

clear_staging:
  file:
    - absent
    - name: {{ staging }}
    - require:
      - cmd: install_java
{% if pillar.java.enable_jce %}
      - cmd: install_jce
{% endif %}

{% endif %}
