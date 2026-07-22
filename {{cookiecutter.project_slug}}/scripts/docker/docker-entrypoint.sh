#!/usr/bin/env bash
set -euo pipefail


echo "[INFO]: Running '${PROJECT_SLUG}' docker-entrypoint.sh..."

_SUDO="sudo"
_GOSU=""
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
	_GOSU="gosu ${USER}:${GROUP}"
elif ! command -v sudo >/dev/null 2>&1; then
	echo "[ERROR]: 'sudo' is required when not running as root!" >&2
	exit 1
fi

_run()
{
	if [ -n "${JUPYTERLAB_TOKEN:-}" ]; then
		echo -e "c.IdentityProvider.token = '${JUPYTERLAB_TOKEN}'" >> "/home/${USER}/.jupyter/jupyter_server_config.py" || exit 2
	fi

	echo "[INFO]: Starting Jupyter Lab..."
	exec ${_GOSU} jupyter lab --port="${JUPYTERLAB_PORT:-8888}" || exit 2
	exit 0
}


main()
{
	umask 0002 || exit 2

	find "${WORKSPACES_DIR}" \
		\( \
			-type d -name ".git" -o \
			-type d -name ".venv" -o \
			-type d -name "venv" -o \
			-type d -name "env" -o \
			-type d -name "modules" -o \
			-type d -name "volumes" -o \
			-type l -name ".env" \
		\) -prune -o -print0 | \
			xargs -0 ${_SUDO} chown -c "${USER}:${GROUP}" || exit 2

	# find "${PROJECT_DIR}" \
	# 	\( \
	# 		-type d -name ".git" -o \
	# 		-type d -name ".venv" -o \
	# 		-type d -name "venv" -o \
	# 		-type d -name "env" -o \
	# 		-type d -name "scripts" -o \
	# 		-type d -name "modules" -o \
	# 		-type d -name "volumes" \
	# 	\) -prune -o -type d -exec \
	# 		${_SUDO} chmod 775 {} + || exit 2

	# find "${PROJECT_DIR}" \
	# 	\( \
	# 		-type d -name ".git" -o \
	# 		-type d -name ".venv" -o \
	# 		-type d -name "venv" -o \
	# 		-type d -name "env" -o \
	# 		-type d -name "scripts" -o \
	# 		-type d -name "modules" -o \
	# 		-type d -name "volumes" -o \
	# 		-type d -name "examples" -o \
	# 		-type l -name ".env" \
	# 	\) -prune -o -type f -exec \
	# 		${_SUDO} chmod 664 {} + || exit 2

	# find "${PROJECT_DIR}" \
	# 	\( \
	# 		-type d -name ".git" -o \
	# 		-type d -name ".venv" -o \
	# 		-type d -name "venv" -o \
	# 		-type d -name "env" -o \
	# 		-type d -name "scripts" -o \
	# 		-type d -name "modules" -o \
	# 		-type d -name "volumes" \
	# 	\) -prune -o -type d -exec \
	# 		${_SUDO} chmod ug+s {} + || exit 2

	${_GOSU} jupyter labextension disable "@jupyterlab/apputils-extension:announcements" || exit 2
	/usr/sbin/sshd -p "${SSH_PORT:-22}" || exit 2
	# echo "${USER} ALL=(ALL) ALL" | tee -a "/etc/sudoers.d/${USER}" > /dev/null || exit 2
	echo ""

	## Parsing input:
	case ${1:-} in
		"" | -s | --start | start | --run | run)
			_run;;
			# shift;;
		-b | --bash | bash | /bin/bash)
			shift
			if [ -z "${*:-}" ]; then
				echo "[INFO]: Starting bash..."
				exec ${_GOSU} /bin/bash
			else
				echo "[INFO]: Executing command -> ${*}"
				exec ${_GOSU} /bin/bash -c "$@" || exit 2
			fi
			exit 0;;
		*)
			echo "[ERROR]: Failed to parsing input -> ${*}" >&2
			echo "[INFO]: USAGE: ${0}  -s, --start, start | -b, --bash, bash, /bin/bash"
			exit 1;;
	esac
}

main "$@"
