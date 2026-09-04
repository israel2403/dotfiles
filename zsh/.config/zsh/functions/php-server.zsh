# Run a PHP application with PHP's built-in development server.
#
# Usage:
#   php_serve [project-directory] [port]
#
# The project directory defaults to the current directory and the port to 8000.
# Stop the server with Ctrl-C.
php_serve() {
  if (( $# > 2 )); then
    print -u2 'usage: php_serve [project-directory] [port]'
    return 2
  fi

  local project_dir=${1:-$PWD}
  local port=${2:-8000}

  if [[ ! -d $project_dir ]]; then
    print -u2 -- "php_serve: directory does not exist: $project_dir"
    return 1
  fi

  project_dir=${project_dir:A}

  if [[ $port != <1-65535> ]]; then
    print -u2 -- "php_serve: invalid port: $port"
    return 2
  fi

  if [[ ! -f $project_dir/index.php ]]; then
    print -u2 -- "php_serve: index.php not found in: $project_dir"
    return 1
  fi

  print -r -- "Serving: $project_dir"
  print -r -- "Open:    http://127.0.0.1:$port"
  print -r -- 'Stop:    Ctrl-C'

  command php -S "127.0.0.1:$port" -t "$project_dir"
}

_php_serve() {
  _arguments \
    '1:project directory:_directories' \
    '2:port number:'
}

compdef _php_serve php_serve
