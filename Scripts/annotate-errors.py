#!/usr/bin/env python3
"""Expose compiler diagnostics as Actions annotations when full logs need login."""
from pathlib import Path
import re
for path in [Path('release-build.log'),Path('native-build.log')]:
    if not path.exists(): continue
    errors=[line.strip() for line in path.read_text(errors='replace').splitlines() if 'error:' in line.lower()]
    for error in errors[:30]:
        error=re.sub(r'\x1b\[[0-9;]*m','',error)
        escaped=error.replace('%','%25').replace('\r','%0D').replace('\n','%0A')
        print('::error title=Native compiler::'+escaped)
