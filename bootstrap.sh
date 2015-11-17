#!/bin/bash -e

function installAnsible () {
  set +e
  command -v ansible >/dev/null 2>&1
  local ansibleExistsExitCode=$?
  set -e

  if [ ${ansibleExistsExitCode} == 0 ]; then
    return
  fi
  echo ""
  echo "Installing Ansible. This script does not try very"
  echo "hard but will do it's best to get it installed."
  echo "If anything could be determined, it is shown here:"
  echo ""

  case `uname -s` in
    Darwin)
      set +e
      command -v brew >/dev/null 2>&1
      set -e
      if [ $? -ne 0 ]; then
        echo "You do not have brew installed. Install homebrew and try again."
        echo "ruby -e \"$\(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install\)\""
        exit -1
      fi
      echo "installing ansible via brew"
      brew install ansible
      ;;
    Linux)
      if [ -f /etc/redhat-release -o -f /etc/centos-release ]; then
        set +e
        sudo -n yum install ansible python-boto
        local yumInstallExitCode=$?
        set -e
        if [ ${yumInstallExitCode} -ne 0 ]; then
          echo "You are missing the ansible package, try installing it with: $ sudo yum install ansible"
          exit -1
        fi
      elif [ -f /etc/SuSE-release ]; then
        set +e
        sudo -n zypper install ansible python-boto
        local zypperInstallExitCode=$?
        set -e
        if [ ${zypperInstallExitCode} -ne 0 ]; then
          echo "You are missing the ansible package, try installing it with: $ sudo zypper install ansible"
          exit -1
        fi
      elif [ -f /etc/debian_version ]; then
        set +e
        sudo -n apt-get install software-properties-common
        sudo -n apt-add-repository ppa:ansible/ansible
        sudo -n apt-get update
        sudo -n apt-get -y install ansible python-boto
        local aptInstallExitCode=$?
        set -e
        if [ ${aptInstallExitCode} -ne 0 ]; then
          echo "You are missing the ansible package,
                try installing with
                $ sudo apt-get install software-properties-common
                $ sudo apt-add-repository ppa:ansible/ansible
                $ sudo apt-get update
                $ sudo apt-get install ansible"
          exit -1
        fi
      fi
      ;;
  esac
}

# Retries a command a configurable number of times with backoff.
#
# The retry count is given by ATTEMPTS (default 9), the initial backoff
# timeout is given by TIMEOUT in seconds (default 1.)
#
# Successive backoffs double the timeout.
# found at: http://stackoverflow.com/questions/8350942/how-to-re-run-the-curl-command-automatically-when-the-error-occurs/8351489#8351489
function withBackoff {
  local maxAttempts=${ATTEMPTS-9}
  local timeout=${TIMEOUT-1}
  local attempt=0
  local exitCode=0
  local output=""

  while [ $attempt < $maxAttempts ]
  do
    set +e
    output="$($@)"
    exitCode=$?
    set -e

    if [ ${exitCode} == 0 ] && [ -n ${output} ]
    then
      echo "$output"
      break
    fi

    echo "Failure! Retrying in $timeout.." 1>&2
    sleep ${timeout}
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout * 2 ))
  done

  if [ ${exitCode} != 0 ] || [ -z ${output} ]
  then
    echo "You've failed me for the last time! ($@)" 1>&2
  fi

  return ${exitCode}
}

function usage () {
  echo "Usage: $0 [-d dependencies.file] [-e ansible_extra_vars] [-i ansible_inventory] [-v [ansible_vault_password_file]] your_playbook.yml"
  exit -1
}

function runPlaybook () {

  installAnsible

  while getopts "d:i:v:e:" o; do
    case "${o}" in
      d)
        DEPENDENCIES_FILE=${OPTARG}
        ;;
      e)
        ANSIBLE_EXTRA_ARGS=${OPTARG}
        ;;
      i)
        ANSIBLE_INVENTORY=${OPTARG}
        ;;
      v)
        if [ -z "${OPTARG}" ]; then
          ANSIBLE_VAULT_PASSWORD_FILE="--vault-password-file ~/.vaultPass.txt"

          if [ ! -f ~/.vaultPass.txt ]; then
            echo "ansible vault password option was set but default file '~/.vaultPass.txt' does not exist"
            exit -1
          fi
        else
          ANSIBLE_VAULT_PASSWORD_FILE="--vault-password-file $OPTARG"

          if [ ! -f "${OPTARG}" ]; then
            echo "ansible vault password option was set but file '$OPTARG' does not exist"
            exit -1
          fi
        fi

      ;;
      *)
        usage
        ;;
    esac
  done

  shift $((OPTIND-1))

  if [ $# -lt 1 ];
  then
    usage
  fi

  if [ -z ${ANSIBLE_INVENTORY} ]; then
    ANSIBLE_INVENTORY="localhost,"
  fi

  if [ -f ${DEPENDENCIES_FILE} ]; then
    mkdir -p ~/.ansibleRoles
    awk '{ if(NF < 2) $2 = "current" }; { system("aws s3 cp s3://deployartifacts/ansibleRoles/"$1"-"$2".tar.gz - | tar -xz -C ~/.ansibleRoles/") }' "$DEPENDENCIES_FILE"
  fi

  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  ANSIBLE_CONFIG="$(dirname ${DIR}/${1})/ansible.cfg" ansible-playbook -i ${ANSIBLE_INVENTORY} ${DIR}/${1} -e "base_dir=${DIR} ${ANSIBLE_EXTRA_ARGS}"
}