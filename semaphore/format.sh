  #!/bin/bash
set -e

mix format --check-formatted
npm --prefix assets run check
