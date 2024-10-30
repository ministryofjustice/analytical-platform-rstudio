#!/usr/bin/env bash

bash /opt/analytical-platform/init/10-restore-bash.sh
bash /opt/analytical-platform/init/20-create-workspace.sh
bash /opt/analytical-platform/init/30-configure-aws-sso.sh

rstudio-server start
