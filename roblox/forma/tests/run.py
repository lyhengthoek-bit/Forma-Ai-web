"""Run with Python 3 and the official Luau CLI on PATH (or LUAU_BIN)."""
from pathlib import Path
import os, subprocess, tempfile
root=Path(__file__).resolve().parents[1]
luau=os.environ.get('LUAU_BIN','luau')
for name,source,marker in [('client','Client.luau','-- CLIENT_SOURCE'),('server','Server.server.luau','-- SERVER_SOURCE')]:
    text=(root/'tests'/f'mock_{name}.luau').read_text().replace(marker,(root/source).read_text())
    with tempfile.TemporaryDirectory(prefix='forma-test-') as folder:
        path=Path(folder)/f'{name}.luau'
        path.write_text(text)
        subprocess.run([luau,str(path)],check=True)
