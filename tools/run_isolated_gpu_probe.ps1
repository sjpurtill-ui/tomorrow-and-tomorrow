param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [Parameter(Mandatory=$true)][string]$Project,
    [Parameter(Mandatory=$true)][string]$Scene,
    [Parameter(Mandatory=$true)][string]$LogFile,
    [string]$UserArguments = '',
    [int]$TimeoutSeconds = 90,
    [ValidateRange(1,1000000)][int]$QuitAfterFrames = 5000
)
# Hidden startup hints do not hide windows a process subsequently creates.
# GPU probes render on a private, non-input desktop. Never switch desktops.
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class IsolatedGpuDesktop {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct Startup { public int cb; public string reserved; public string desktop; public string title; public int x,y,xsize,ysize,xchars,ychars,fill; public int flags; public short show; public short reserved2; public IntPtr reservedPtr,stdin,stdout,stderr; }
    [StructLayout(LayoutKind.Sequential)]
    public struct ProcessInfo { public IntPtr process,thread; public uint processId,threadId; }
    [DllImport("user32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateDesktop(string name,IntPtr device,IntPtr mode,uint flags,uint access,IntPtr security);
    [DllImport("user32.dll",SetLastError=true)] static extern IntPtr OpenInputDesktop(uint flags,bool inherit,uint access);
    [DllImport("user32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool GetUserObjectInformation(IntPtr obj,int index,StringBuilder value,int length,out int needed);
    [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr desktop);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool CreateProcess(string app,StringBuilder command,IntPtr pa,IntPtr ta,bool inherit,uint flags,IntPtr environment,string cwd,ref Startup startup,out ProcessInfo info);
    [DllImport("kernel32.dll")] static extern uint WaitForSingleObject(IntPtr handle,uint milliseconds);
    [DllImport("kernel32.dll")] static extern bool GetExitCodeProcess(IntPtr process,out uint code);
    [DllImport("kernel32.dll")] static extern bool TerminateProcess(IntPtr process,uint code);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
    delegate bool WindowCallback(IntPtr window,IntPtr parameter);
    [DllImport("user32.dll")] static extern bool EnumDesktopWindows(IntPtr desktop,WindowCallback callback,IntPtr parameter);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window,out uint pid);
    static string InputName() { IntPtr d=OpenInputDesktop(0,false,1); if(d==IntPtr.Zero) throw new Exception("Cannot verify input desktop"); try { int needed; var text=new StringBuilder(256); if(!GetUserObjectInformation(d,2,text,512,out needed)) throw new Exception("Cannot read input desktop"); return text.ToString(); } finally { CloseDesktop(d); } }
    public static string Run(string app,string args,string cwd,int seconds) {
        string input=InputName(), name="CodexGpuProbe_"+Guid.NewGuid().ToString("N");
        IntPtr desktop=CreateDesktop(name,IntPtr.Zero,IntPtr.Zero,0,0x1FF,IntPtr.Zero);
        if(desktop==IntPtr.Zero) throw new Exception("Private desktop creation failed: "+Marshal.GetLastWin32Error());
        ProcessInfo info=new ProcessInfo(); bool started=false; int visible=0; uint exit=0;
        try {
            var startup=new Startup();startup.cb=Marshal.SizeOf(typeof(Startup));startup.desktop="winsta0\\"+name;startup.flags=1;startup.show=0;
            if(!CreateProcess(app,new StringBuilder("\""+app+"\" "+args),IntPtr.Zero,IntPtr.Zero,false,0x08000000,IntPtr.Zero,cwd,ref startup,out info)) throw new Exception("Private process failed: "+Marshal.GetLastWin32Error());
            started=true;DateTime deadline=DateTime.UtcNow.AddSeconds(seconds);
            while(WaitForSingleObject(info.process,100)==258) {
                if(InputName()!=input) throw new Exception("Input desktop changed; stopping only this probe");
                int count=0;EnumDesktopWindows(desktop,delegate(IntPtr w,IntPtr p){uint pid;GetWindowThreadProcessId(w,out pid);if(pid==info.processId && IsWindowVisible(w))count++;return true;},IntPtr.Zero);visible=Math.Max(visible,count);
                if(DateTime.UtcNow>deadline) throw new Exception("Private GPU probe timeout");
            }
            GetExitCodeProcess(info.process,out exit);
            return "PRIVATE_GPU_PROBE pid="+info.processId+" exit="+exit+" input_desktop="+input+" render_desktop="+name+" visible_windows_on_private_desktop="+visible;
        } finally { if(started) { if(WaitForSingleObject(info.process,0)==258)TerminateProcess(info.process,124);CloseHandle(info.thread);CloseHandle(info.process); }CloseDesktop(desktop); }
    }
}
'@
$taskArguments='--path "'+$Project+'" --audio-driver Dummy --resolution 1600x900 --quit-after '+$QuitAfterFrames+' --log-file "'+$LogFile+'" "'+$Scene+'" -- '+$UserArguments
$taskResult=[IsolatedGpuDesktop]::Run($Godot,$taskArguments,$Project,$TimeoutSeconds)
$taskResult | Set-Content -LiteralPath ($LogFile+".runner.txt")
$taskResult
if ($taskResult -notmatch " exit=0 ") { throw "GPU probe exited unsuccessfully" }
if (Select-String -LiteralPath $LogFile -Pattern "SCRIPT ERROR|^ERROR:" -Quiet) { throw "GPU probe logged an engine or script error; inspect $LogFile" }
