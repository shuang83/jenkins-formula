{% from "jenkins/map.jinja" import jenkins with context %}

jenkins_group:
  group.present:
    - name: {{ jenkins.group }}
    - system: True

jenkins_user:
  file.directory:
    - name: {{ jenkins.home }}
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - mode: 0755
    - require:
      - user: jenkins_user
      - group: jenkins_group
  user.present:
    - name: {{ jenkins.user }}
    - groups:
      - {{ jenkins.group }}
    - system: True
    - home: {{ jenkins.home }}
    - shell: /bin/bash
    - require:
      - group: jenkins_group

jenkins_user_ssh_dir:
  file.directory:
    - name: {{ jenkins.home }}/.ssh
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - mode: 0700
    - require: 
      - user: jenkins_user

jenkins_user_ssh_key:
  cmd.run:
    - name: ssh-keygen -q -N '' -f {{ jenkins.home }}/.ssh/id_rsa
    - runas: {{ jenkins.user }}
    - unless: test -f {{ jenkins.home}}/.ssh/id_rsa
    - require:
      - jenkins_user_ssh_dir

jenkins:
  {% if grains['os_family'] in ['RedHat', 'Debian'] %}
    {% set repo_suffix = '' %}
    {% if jenkins.stable %}
      {% set repo_suffix = '-stable' %}
    {% endif %}
  pkgrepo.managed:
    - humanname: Jenkins upstream package repository
    {% if grains['os_family'] == 'RedHat' %}
    - baseurl: http://pkg.jenkins.io/redhat{{ repo_suffix }}
    - gpgkey: http://pkg.jenkins.io/redhat{{ repo_suffix }}/jenkins.io.key
    {% elif grains['os_family'] == 'Debian' %}
    - file: {{jenkins.deb_apt_source}}
    - name: deb http://pkg.jenkins.io/debian{{ repo_suffix }} binary/
    - key_url: http://pkg.jenkins.io/debian{{ repo_suffix }}/jenkins.io.key
    {% endif %}
    - require_in:
      - pkg: jenkins
  {% endif %}
  pkg.installed:
    - pkgs: {{ jenkins.pkgs|json }}
  service.running:
    - enable: True
    - watch:
      - pkg: jenkins
      {% if grains['os_family'] in ['RedHat', 'Debian'] %}
      - file: jenkins config
      {% endif %}

java:
  pkg.installed:
    - pkgs: {{ jenkins.java_pkg }}
    - require_in:
      - pkg: jenkins

 remove_packages:
  pkg.removed:
    - pkgs: {{ jenkins.remove_packages }}
    - require_in:
      - pkg: java

{% if grains['os_family'] in ['RedHat', 'Debian'] %}
jenkins config:
  file.managed:
    {% if grains['os_family'] == 'RedHat' %}
    - name: /etc/sysconfig/jenkins
    - source: salt://jenkins/files/RedHat/jenkins.conf
    {% elif grains['os_family'] == 'Debian' %}
    - name: /etc/default/jenkins
    - source: salt://jenkins/files/Debian/jenkins.conf
    {% endif %}
    - template: jinja
    - user: root
    - group: root
    - mode: 400
    - require:
      - pkg: jenkins
{% endif %}
