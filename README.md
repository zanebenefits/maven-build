Role Name
=========

Build a maven project and handle the differences between local, snap (CI tool) and builds for branches.

Requirements
------------

Expects maven to be installed and available on the path. 

Role Variables
--------------

`maven_build_cmd` `mvn -B -U` how to run maven
`maven_project_dir` no default
`maven_archive_dir` no default

This also looks for some environment variables on the system that [SnapCI](https://snap-ci.com) will set so we know we're building on snap. 

Dependencies
------------

none

Example Playbook
----------------

An example of how to use the role:

    - hosts: localhost
      sudo: no
      connection: local
      roles:
      - { role: maven-build, maven_project_dir: "{{ base_dir }}" }

License
-------

BSD

Author Information
------------------

eng@peoplekeep.com
