#!/usr/bin/env bash
set -Eeuo pipefail

TOOL_NAME="bt-gdrive-multiserver"
PLUGIN_DIR="${BT_GDRIVE_PLUGIN_DIR:-/www/server/panel/plugin/gdrive}"
GDRIVE_FILE="$PLUGIN_DIR/gdrive_main.py"
CLOUD_FILE="${BT_GDRIVE_CLOUD_FILE:-/www/server/panel/class/CloudStoraUpload.py}"
PYTHON="${BT_GDRIVE_PYTHON:-/www/server/panel/pyenv/bin/python3}"
STATE_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
CONFIG_FILE="${BT_GDRIVE_CONFIG:-$STATE_DIR/config.env}"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$STATE_DIR/backups/$STAMP"
LOG_DIR="$STATE_DIR/logs"
LOG_FILE="$LOG_DIR/repair_$STAMP.log"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"
chmod 700 "$STATE_DIR" "$BACKUP_DIR" "$LOG_DIR" 2>/dev/null || true
exec > >(tee -a "$LOG_FILE") 2>&1

fail(){ echo "[ERROR] $*"; echo "Log: $LOG_FILE"; exit 1; }
rollback(){
  echo "[WARN] Error detected; restoring files from this run..."
  [ -f "$BACKUP_DIR/gdrive_main.py" ] && cp -a "$BACKUP_DIR/gdrive_main.py" "$GDRIVE_FILE" || true
  [ -f "$BACKUP_DIR/CloudStoraUpload.py" ] && cp -a "$BACKUP_DIR/CloudStoraUpload.py" "$CLOUD_FILE" || true
  echo "Rollback finished. Log: $LOG_FILE"
}
trap rollback ERR

[ -f "$CONFIG_FILE" ] || fail "Config not found: $CONFIG_FILE. Run install.sh first."
# shellcheck disable=SC1090
source "$CONFIG_FILE"
BOOTSTRAP="${BOOTSTRAP:-0}"
if [ -z "${ROOT_FOLDER_ID:-}" ] && [ "$BOOTSTRAP" != "1" ]; then fail "ROOT_FOLDER_ID is required (or use bootstrap mode)"; fi
FALLBACK_SERVER_NAME="${FALLBACK_SERVER_NAME:-}"

[ -f "$GDRIVE_FILE" ] || fail "Google Drive plugin file not found: $GDRIVE_FILE"
[ -f "$CLOUD_FILE" ] || fail "Cloud storage core file not found: $CLOUD_FILE"
if [ ! -x "$PYTHON" ]; then PYTHON="$(command -v python3 || true)"; fi
[ -n "$PYTHON" ] || fail "python3 not found"

cp -a "$GDRIVE_FILE" "$BACKUP_DIR/gdrive_main.py"
cp -a "$CLOUD_FILE" "$BACKUP_DIR/CloudStoraUpload.py"
[ -f "$PLUGIN_DIR/root_folder_id.conf" ] && cp -a "$PLUGIN_DIR/root_folder_id.conf" "$BACKUP_DIR/root_folder_id.conf" || true
[ -f "$PLUGIN_DIR/server_name.conf" ] && cp -a "$PLUGIN_DIR/server_name.conf" "$BACKUP_DIR/server_name.conf" || true

echo "[$TOOL_NAME] Repair started"
echo "Backup: $BACKUP_DIR"
echo "Server ID: public IPv4 (fallback: server_name.conf / hostname)"

"$PYTHON" - "$GDRIVE_FILE" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1]); text=p.read_text(encoding='utf-8')
orig=text

pat = r'(    __config_path = os\.path\.join\(__setup_path,\s*[\'\"]config\.conf[\'\"]\)\n)(?:    # BT-GDRIVE-MULTISERVER-BEGIN.*?    # BT-GDRIVE-MULTISERVER-END\n)?(?:    __backup_dir_name = [\'\"](?:bt_backup|BT-Backup)[\'\"]\n)?'
rep = r'''\1    # BT-GDRIVE-MULTISERVER-BEGIN
    __backup_dir_name = "BT-Backup"
    __root_folder_id_path = os.path.join(__setup_path, 'root_folder_id.conf')
    __server_name_path = os.path.join(__setup_path, 'server_name.conf')
    # BT-GDRIVE-MULTISERVER-END
'''
text,n = re.subn(pat,rep,text,count=1,flags=re.S)
if n != 1: raise SystemExit('Unsupported gdrive_main.py: class config anchor not found')

start=text.find('    def _create_folder_cycle(self,filepath):')
if start < 0:
    start=text.find('    def _read_simple_conf(self, path):')
if start < 0: raise SystemExit('Unsupported gdrive_main.py: folder helper anchor not found')
end=text.find('    def upload_file(', start)
if end < 0: raise SystemExit('Unsupported gdrive_main.py: upload_file anchor not found')
new='''    # BT-GDRIVE-MULTISERVER-BEGIN helpers
    def _read_simple_conf(self, path):
        try:
            if not os.path.isfile(path): return ""
            value = public.readFile(path)
            return "" if value is None else str(value).strip()
        except Exception:
            return ""

    def _get_root_folder_id(self):
        return self._read_simple_conf(self.__root_folder_id_path)

    def _get_server_name(self):
        cached = getattr(self, '_gdrive_server_id_cache', None)
        if cached: return cached
        mode = os.environ.get('BT_GDRIVE_SERVER_ID_MODE', 'public-ip').strip().lower()
        name = ""
        if mode == 'public-ip':
            try:
                import urllib.request
                req=urllib.request.Request('https://api4.ipify.org',headers={'User-Agent':'bt-gdrive-multiserver'})
                name=urllib.request.urlopen(req,timeout=3).read().decode().strip()
                if not re.match(r'^\\d{1,3}(?:\\.\\d{1,3}){3}$', name): name=""
            except Exception:
                name=""
        if not name:
            name=self._read_simple_conf(self.__server_name_path)
        if not name:
            try:
                import socket; name=socket.gethostname()
            except Exception:
                name='server'
        name=re.sub(r'[\\\\/\\r\\n\\t]+','_',str(name).strip()) or 'server'
        self._gdrive_server_id_cache=name
        return name

    def _get_remote_base(self):
        server_name=self._get_server_name()
        return server_name if self._get_root_folder_id() else self.__backup_dir_name + '/' + server_name

    def _remote_path(self,*parts):
        values=[self._get_remote_base()]
        for part in parts:
            if part is None: continue
            part=str(part).strip('/')
            if part: values.append(part)
        return '/'.join(values)

    def _escape_drive_query_value(self,value):
        return str(value).replace('\\\\','\\\\\\\\').replace("'","\\\\'")

    def _create_folder_cycle(self,filepath):
        parent_id=self._get_root_folder_id()
        for folder_name in filepath.split('/'):
            if not folder_name: continue
            fid=self.__get_folder_id(folder_name,parent_id)
            if not fid: fid=self.create_folder(folder_name,parent_id or "")
            parent_id=fid
        return parent_id

    def build_object_name(self,data_type,file_name):
        prefix_dict={'site':'web','database':'db','path':'path'}
        data_prefix=prefix_dict.get(data_type,data_type)
        file_regx=rf'{data_prefix}_(.+)_20\\d+_\\d+(?:\\.|_)'
        sub_search=re.search(file_regx.lower(),file_name)
        sub_path_name=''
        if sub_search: sub_path_name=sub_search.groups()[0]+'/'
        object_name=self._remote_path(data_prefix,sub_path_name)
        return object_name[1:] if object_name[:1]=='/' else object_name
    # BT-GDRIVE-MULTISERVER-END helpers

'''
text=text[:start]+new+text[end:]

pat2=re.compile(r'(?ms)^    # 获取目录id.*?^    def create_folder\(self,folder_name,parents=""\):')
if pat2.search(text):
    repl='''    # 获取目录id（按父目录限定，避免同名目录串线）
    def __get_folder_id(self, folder_name, parent_id=None):
        service = build('drive', 'v3', credentials=self.__creds)
        safe_name = self._escape_drive_query_value(folder_name)
        q = "name='{}' and mimeType='application/vnd.google-apps.folder' and trashed=false".format(safe_name)
        if parent_id:
            q += " and '{}' in parents".format(self._escape_drive_query_value(parent_id))
        else:
            q += " and 'root' in parents"
        results = service.files().list(pageSize=100,q=q,spaces='drive',fields="nextPageToken, files(id, name, parents)").execute()
        items = results.get('files', [])
        return [] if not items else items[0]['id']

    def create_folder(self,folder_name,parents=""):
'''
    text=pat2.sub(repl,text,count=1)
elif 'def __get_folder_id(self, folder_name, parent_id=None):' not in text:
    raise SystemExit('Unsupported gdrive_main.py: folder lookup function not found')

text=text.replace("get.filepath = 'bt_backup/sites/' + name", "get.filepath = self._remote_path('web', name)")
text=text.replace("get.filepath = 'bt_backup/database/' + name", "get.filepath = self._remote_path('db', name)")
text=text.replace("get.filepath = 'bt_backup/path/' + name", "get.filepath = self._remote_path('path', name)")

if text == orig: raise SystemExit('No changes made to gdrive_main.py')
p.write_text(text,encoding='utf-8')
print('Patched gdrive_main.py')
PY

if [ -n "${ROOT_FOLDER_ID:-}" ]; then
  printf '%s\n' "$ROOT_FOLDER_ID" > "$PLUGIN_DIR/root_folder_id.conf"
  chmod 600 "$PLUGIN_DIR/root_folder_id.conf"
else
  rm -f "$PLUGIN_DIR/root_folder_id.conf"
fi
if [ -n "$FALLBACK_SERVER_NAME" ]; then
  printf '%s\n' "$FALLBACK_SERVER_NAME" > "$PLUGIN_DIR/server_name.conf"
else
  : > "$PLUGIN_DIR/server_name.conf"
fi
chmod 600 "$PLUGIN_DIR/server_name.conf"

"$PYTHON" - "$CLOUD_FILE" <<'PY'
from pathlib import Path
import re,sys
p=Path(sys.argv[1]); text=p.read_text(encoding='utf-8')
pattern=re.compile(r'(?ms)^    def build_object_name\(self, data_type, file_name\):\n.*?(?=^    def [A-Za-z_][A-Za-z0-9_]*\()')
matches=list(pattern.finditer(text)); chosen=None
for m in matches:
    block=m.group(0)
    if 'data_prefix' in block and ('bt_backup' in block or 'BT-Backup' in block or 'prefix_dict' in block): chosen=m; break
if chosen is None: raise SystemExit('Unsupported CloudStoraUpload.py: target build_object_name() not found')
new='''    def build_object_name(self, data_type, file_name):
        import re
        prefix_dict={"site":"web","database":"db","path":"path"}
        data_prefix=prefix_dict.get(data_type,"other")
        server_name=""
        try:
            import urllib.request
            req=urllib.request.Request('https://api4.ipify.org',headers={'User-Agent':'bt-gdrive-multiserver'})
            server_name=urllib.request.urlopen(req,timeout=3).read().decode().strip()
            if not re.match(r'^\\d{1,3}(?:\\.\\d{1,3}){3}$',server_name): server_name=""
        except Exception: server_name=""
        if not server_name:
            try:
                with open('/www/server/panel/plugin/gdrive/server_name.conf','r') as f: server_name=f.read().strip()
            except Exception: pass
        if not server_name:
            try:
                import socket; server_name=socket.gethostname()
            except Exception: server_name='server'
        server_name=re.sub(r'[\\\\/\\r\\n\\t]+','_',str(server_name).strip()) or 'server'
        has_shared_root=os.path.isfile('/www/server/panel/plugin/gdrive/root_folder_id.conf') and bool(open('/www/server/panel/plugin/gdrive/root_folder_id.conf').read().strip())
        remote_root=server_name if has_shared_root else 'BT-Backup/'+server_name
        if "database" in file_name:
            dir_path='/'.join(file_name.split('/')[:-1]); sub_path_name='/'.join(dir_path.split('/')[-2:])+'/'
        else:
            file_regx=rf'{data_prefix}_(.+)_20\\d+_\\d+(?:\\.|_)'; sub_search=re.search(file_regx.lower(),file_name); sub_path_name=(sub_search.groups()[0]+'/') if sub_search else ''
        object_name=f'{remote_root}/{data_prefix}/{sub_path_name}'
        return object_name[1:] if object_name[:1]=='/' else object_name

'''
p.write_text(text[:chosen.start()]+new+text[chosen.end():],encoding='utf-8')
print('Patched CloudStoraUpload.py')
PY

"$PYTHON" -m py_compile "$GDRIVE_FILE"
"$PYTHON" -m py_compile "$CLOUD_FILE"
trap - ERR

echo "Repair completed successfully."
if [ -n "${ROOT_FOLDER_ID:-}" ]; then echo "Folder ID configured: ${ROOT_FOLDER_ID:0:6}...${ROOT_FOLDER_ID: -4}"; else echo "Bootstrap mode: BT-Backup will be created by the plugin on first backup."; fi
echo "Log: $LOG_FILE"
