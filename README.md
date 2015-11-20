Maven Build
=========

Build a maven project and handle the differences between local, [SnapCI](https://snap-ci.com) and the SnapCI builds for pull requests.

Requirements
------------

Expects Apache Maven to be installed and available on the path. 

Role Variables
--------------

`maven_build_cmd` how to run maven, default `mvn -B -U` 
`maven_project_dir` the root dir to execute maven commands from, no default and required
`maven_archive_dir` where to archive files to in relative path to `maven_project_dir`, no default and archive related tasks will be skipped if this is not defined and not running on [SnapCI](https://snap-ci.com).   
`maven_archive_filename` relative path filename to `maven_project_dir` to archive, default `*-webservice/target/*.zip`

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
      
where `base_dir` is the full path to the maven project directory to work in.  

Also added example playbood and dependencies file in `provisioning` dir.

License
-------

MIT

Author Information
------------------
Heath Eldeen
Architect
PeopleKeep.com
