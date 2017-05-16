{% from "jenkins/map.jinja" import jenkins with context %}

#/etc/nginx/sites-available/jenkins.conf:
test:
  file.managed:
    - name: {{ jenkins.nginx_conf }}/jenkins.conf
    - template: jinja
    - source: salt://jenkins/files/nginx.conf
    - user: {{ jenkins.nginx_user }}
    - group: {{ jenkins.nginx_group }}
    - mode: 440
    - require:
      - pkg: jenkins

{% if grains['os_family'] == 'Debian' %}
/etc/nginx/sites-enabled/jenkins.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/jenkins.conf
    - user: {{ jenkins.nginx_user }}
    - group: {{ jenkins.nginx_group }}
#{ % endif %}
extend:
  nginx:
    service:
      - watch:
        - file: /etc/nginx/sites-available/jenkins.conf
      - require:
        - file: /etc/nginx/sites-enabled/jenkins.conf

{% elif grains['os_family'] == 'RedHat' %}

extend:
  nginx:
    service:
      - watch:
        - file: /etc/nginx/conf.d/jenkins.conf

{% endif %}
