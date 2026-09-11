#!/usr/bin/env python3
"""Installed Myran caller proof on a private tmux server, with a recording Agent fixture."""
import fcntl,json,os,pathlib,pty,select,shutil,struct,subprocess,tempfile,termios,threading,time
source_root=pathlib.Path(__file__).resolve().parents[1]
root=pathlib.Path(tempfile.mkdtemp(prefix='myr21-prompt-',dir='/tmp')).resolve();root.chmod(0o700)
(root/'bin').mkdir();(root/"repo space 'quote").mkdir();(root/'other').mkdir()
myr=os.environ.get('MYRAN_BINARY') or shutil.which('myr');tmux=shutil.which('tmux')
assert myr and tmux, 'Install Myran and tmux before running this lane'
myr=str(pathlib.Path(myr).resolve(strict=True))
(root/'bin'/'myr').write_text('#!'+shutil.which('python3')+'\nimport json,os,pathlib,sys\npathlib.Path('+repr(str(root/'myr-env.json'))+').write_text(json.dumps({k:os.environ.get(k) for k in ["TMUX","TMUX_PANE","PWD"]}))\nos.execv('+repr(myr)+', ['+repr(myr)+', *sys.argv[1:]])\n');(root/'bin'/'myr').chmod(0o700)
record=root/'agent.json';marker=root/'INJECTED'
(root/'bin'/'pi').write_text('#!'+shutil.which('python3')+'\nimport json,pathlib,sys,time\nrecord=pathlib.Path('+repr(str(record))+')\npending=record.with_suffix(".pending")\npending.write_text(json.dumps(sys.argv[1:]))\npending.replace(record)\ntime.sleep(120)\n');(root/'bin'/'pi').chmod(0o700)
env=dict(os.environ,PATH=str(root/'bin')+':'+os.environ['PATH'],MYRAN_STATE_DIR=str(root/'state'),TERM='xterm-256color')
for key in ['TMUX','TMUX_PANE','NVIM','TMUX_EDIT_BYPASS','FZF_DEFAULT_OPTS','FZF_DEFAULT_OPTS_FILE','TMUX_SESSION_SOCKET']:
    env.pop(key,None)
socket=str(root/'socket');child=None;terminal=None;data=bytearray()
def tm(*args):
    return subprocess.check_output([tmux,'-f','/dev/null','-S',socket,*args],env=env,text=True,timeout=15).strip()
def wait(check,label):
    end=time.monotonic()+15
    while time.monotonic()<end:
        value=check()
        if value:return value
        time.sleep(.1)
    raise AssertionError(label)
def drain():
    while True:
        try:
            if select.select([terminal],[],[],.1)[0]:
                block=os.read(terminal,65536)
                if not block:return
                data.extend(block)
        except OSError:return
try:
    pane=tm('new-session','-d','-P','-F','#{pane_id}','-s','origin','-x','150','-y','45','-c',str(root/"repo space 'quote"),'/bin/sleep','120')
    tm('set-option','-t','origin','@workspace_root',str(root/"repo space 'quote"))
    tm('new-session','-d','-s','alternate','-c',str(root/'other'),'/bin/sleep','120')
    tm('set-option','-g','prefix','C-a');tm('set-option','-g','mouse','on');tm('set-option','-g','status-left','workspace ')
    source=(source_root/'tmux/.tmux.conf').read_text()
    status=(source_root/'tmux/.tmux/workspace-status.conf').read_text()
    lines=[line for line in source.splitlines() if line.startswith(('bind-key A ','bind-key w '))]
    lines += [line for line in status.splitlines() if line.startswith('bind-key -n MouseDown1StatusLeft ')]
    (root/'bindings.conf').write_text('\n'.join(lines)+'\n');tm('source-file',str(root/'bindings.conf'))
    child,terminal=pty.fork()
    if child==0:os.execve(tmux,[tmux,'-S',socket,'attach-session','-t','origin'],env)
    fcntl.ioctl(terminal,termios.TIOCSWINSZ,struct.pack('HHHH',45,150,0,0))
    threading.Thread(target=drain,daemon=True).start()
    client=wait(lambda:tm('list-clients','-F','#{client_name}'),'attach')
    label='review $(touch '+str(marker)+'); "literal"'
    tm('send-keys','-K','-c',client,'C-a','A')
    wait(lambda:b'AI task name:' in data,'agent prompt')
    os.write(terminal,label.encode()+b'\r')
    wait(record.exists,'named agent argv')
    assert json.loads(record.read_text())==['--name',label]
    assert not marker.exists()
    # Choose the other Session using the actual prefix-w popup.
    previous=len(data)
    tm('send-keys','-K','-c',client,'C-a','w')
    wait(lambda:b'alternate' in data[previous:],'Workspace picker')
    os.write(terminal,b'alternate');time.sleep(.3);os.write(terminal,b'\r')
    wait(lambda:tm('display-message','-p','-c',client,'#{session_name}')=='alternate','selected Workspace')
    # An actual SGR left click on status-left invokes the same selector from the other Session.
    previous=len(data)
    os.write(terminal,b'\x1b[<0;2;45M\x1b[<0;2;45m')
    wait(lambda:b'origin' in data[previous:],'status-left click picker')
    os.write(terminal,b'origin');time.sleep(.3);os.write(terminal,b'\r')
    wait(lambda:tm('display-message','-p','-c',client,'#{session_name}')=='origin','status-click selection')
    assert tm('show-option','-qv','-t','alternate','@workspace_root')==''
    result={'named_prompt_literal_argv':'PASS','no_shell_injection':'PASS','prefix_w_workspace_switch':'PASS','actual_status_left_mouse_click':'PASS','opaque_session_not_adopted':'PASS'}
    (root/'result.json').write_text(json.dumps(result,indent=2));print(root);print(json.dumps(result,indent=2))
finally:
    (root/'terminal.raw').write_bytes(data)
    subprocess.run([tmux,'-S',socket,'kill-server'],env=env,capture_output=True)
    if child:os.waitpid(child,0)
    if terminal is not None:os.close(terminal)
