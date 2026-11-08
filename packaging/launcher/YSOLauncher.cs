// YSO.exe, the launcher of the Microsoft Store package: starts YSO.ps1 (next to it) with Windows
// PowerShell 5.1 and no console window, and passes its arguments on. Administrator rights are
// asked for by app.manifest, once, like YSO does when it starts from its file.
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string script = Path.Combine(dir, "YSO.ps1");
        string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
        StringBuilder line = new StringBuilder("-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ");
        line.Append(Quote(script));
        foreach (string a in args) { line.Append(' ').Append(Quote(a)); }
        ProcessStartInfo psi = new ProcessStartInfo(ps, line.ToString());
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        psi.WorkingDirectory = dir;
        try
        {
            using (Process p = Process.Start(psi))
            {
                p.WaitForExit();
                return p.ExitCode;
            }
        }
        catch (Exception e)
        {
            MessageBox.Show("YSO could not start Windows PowerShell: " + e.Message, "YSO", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return 1;
        }
    }

    private static string Quote(string s)
    {
        return "\"" + s.Replace("\"", "\\\"") + "\"";
    }
}
