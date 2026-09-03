# Create a PHP file from a small, dependency-free skeleton.
#
# Usage:
#   php_create <file> [page|class|script]
#
# The default is "page". Existing files are never overwritten.
php_create() {
  if (( $# < 1 || $# > 2 )); then
    print -u2 'usage: php_create <file> [page|class|script]'
    return 2
  fi

  local target=$1
  local kind=${2:-page}

  [[ $target == *.php ]] || target="${target}.php"

  if [[ -e $target ]]; then
    print -u2 -- "php_create: file already exists: $target"
    return 1
  fi

  local parent=${target:h}
  [[ $parent == . ]] || mkdir -p -- "$parent" || return

  case $kind in
    page)
      command tee -- "$target" >/dev/null <<'PHP'
<?php
declare(strict_types=1);

$title = 'PHP page';
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?></title>
</head>
<body>
    <main>
        <h1><?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?></h1>
    </main>
</body>
</html>
PHP
      ;;
    class)
      local class_name=${target:t:r}
      class_name=${(C)${class_name//[^[:alnum:]_]/_}}
      [[ $class_name == [[:alpha:]_]* ]] || class_name="Php${class_name}"

      command tee -- "$target" >/dev/null <<PHP
<?php
declare(strict_types=1);

final class ${class_name}
{
}
PHP
      ;;
    script)
      command tee -- "$target" >/dev/null <<'PHP'
<?php
declare(strict_types=1);

function main(): void
{
}

main();
PHP
      ;;
    *)
      print -u2 -- "php_create: unknown skeleton '$kind' (use page, class, or script)"
      rmdir -- "$parent" 2>/dev/null
      return 2
      ;;
  esac

  print -r -- "Created PHP ${kind}: ${target}"
}

_php_create() {
  if (( CURRENT == 2 )); then
    _arguments '1:PHP file:_files -g "*.php"' '2:skeleton:(page class script)'
  else
    _arguments '1:PHP file:_files -g "*.php"' '2:skeleton:(page class script)'
  fi
}

compdef _php_create php_create
