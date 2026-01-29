# Example: Windows Group Policy Configuration

This example provides step-by-step instructions for configuring Windows Update to use the cache server via Group Policy.

## For Domain Environments

### Method 1: Configure Proxy Settings via Group Policy

#### Step 1: Open Group Policy Management

1. On your Domain Controller or management workstation, open **Group Policy Management** (gpmc.msc)
2. Create a new GPO or edit an existing one
3. Give it a descriptive name like "Windows Update Cache Proxy"

#### Step 2: Configure Proxy Settings

Navigate to:
```
Computer Configuration
  └─ Preferences
      └─ Windows Settings
          └─ Registry
```

#### Step 3: Add Registry Items

**Item 1: Enable Proxy**

- Click **New** → **Registry Item**
- **Action**: Update
- **Hive**: HKEY_LOCAL_MACHINE
- **Key Path**: `SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings`
- **Value name**: `ProxyEnable`
- **Value type**: REG_DWORD
- **Value data**: `1`

**Item 2: Set Proxy Server**

- Click **New** → **Registry Item**
- **Action**: Update
- **Hive**: HKEY_LOCAL_MACHINE
- **Key Path**: `SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings`
- **Value name**: `ProxyServer`
- **Value type**: REG_SZ
- **Value data**: `http://YOUR_CACHE_SERVER_IP:80`

**Item 3: Set Proxy Bypass List (Optional)**

- Click **New** → **Registry Item**
- **Action**: Update
- **Hive**: HKEY_LOCAL_MACHINE
- **Key Path**: `SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings`
- **Value name**: `ProxyBypass`
- **Value type**: REG_SZ
- **Value data**: `<local>`

#### Step 4: Link the GPO

1. Link the GPO to the appropriate Organizational Unit (OU)
2. Ensure the GPO is enabled and linked correctly

#### Step 5: Apply the Policy

On client machines, force a Group Policy update:
```cmd
gpupdate /force
```

### Method 2: Configure via WinHTTP Proxy Settings

Navigate to:
```
Computer Configuration
  └─ Preferences
      └─ Control Panel Settings
          └─ Scheduled Tasks
```

Create a scheduled task that runs at startup:

**Script to execute**:
```cmd
netsh winhttp set proxy proxy-server="http://YOUR_CACHE_SERVER_IP:80" bypass-list="<local>"
```

## For Workgroup Environments

### Method 1: Local Group Policy

On each Windows machine:

1. Open **Local Group Policy Editor** (gpedit.msc)
2. Follow the same steps as above for registry settings
3. Run `gpupdate /force` to apply changes

### Method 2: PowerShell Script

Create a PowerShell script and run it on each machine:

```powershell
# Set proxy for Windows Update
$proxyServer = "http://YOUR_CACHE_SERVER_IP:80"

# Set WinHTTP proxy
netsh winhttp set proxy proxy-server="$proxyServer" bypass-list="<local>"

# Verify settings
netsh winhttp show proxy
```

Save as `configure-update-proxy.ps1` and run as Administrator:
```powershell
powershell -ExecutionPolicy Bypass -File configure-update-proxy.ps1
```

### Method 3: Registry Script

Create a `.reg` file:

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings]
"ProxyEnable"=dword:00000001
"ProxyServer"="http://YOUR_CACHE_SERVER_IP:80"
"ProxyBypass"="<local>"
```

Save as `update-cache-proxy.reg` and import on each machine:
```cmd
regedit /s update-cache-proxy.reg
```

## Verification

### Verify Proxy Settings

On Windows clients, run:
```cmd
netsh winhttp show proxy
```

Expected output:
```
Current WinHTTP proxy settings:

    Proxy Server(s) :  http://YOUR_CACHE_SERVER_IP:80
    Bypass List     :  <local>
```

### Test Windows Update

1. Open **Windows Update** settings
2. Click **Check for updates**
3. Updates should now be downloaded through the cache server

### Monitor on Cache Server

On the Ubuntu server, watch the logs:
```bash
sudo tail -f /var/log/nginx/access.log
```

You should see Windows Update requests being proxied and cached.

## Troubleshooting

### Proxy not being used

1. Check Group Policy application:
   ```cmd
   gpresult /r
   ```

2. Verify registry values:
   ```cmd
   reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings"
   ```

3. Check Windows Update logs:
   - Location: `C:\Windows\Logs\WindowsUpdate\`

### Updates failing

1. Verify cache server is accessible:
   ```cmd
   ping YOUR_CACHE_SERVER_IP
   curl http://YOUR_CACHE_SERVER_IP/cache-status
   ```

2. Check firewall rules on both Windows client and Ubuntu server

3. Review Nginx error logs:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

## Advanced Configuration

### Exclude specific networks

To exclude certain subnets from using the proxy:

```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings]
"ProxyBypass"="<local>;192.168.1.*;*.contoso.com"
```

### Use PAC file

Instead of direct proxy settings, you can use a Proxy Auto-Configuration (PAC) file:

1. Create a PAC file on a web server:
   ```javascript
   function FindProxyForURL(url, host) {
       // Use cache for Microsoft domains
       if (shExpMatch(host, "*.microsoft.com") || 
           shExpMatch(host, "*.windowsupdate.com") ||
           shExpMatch(host, "*.update.microsoft.com")) {
           return "PROXY YOUR_CACHE_SERVER_IP:80";
       }
       // Direct connection for everything else
       return "DIRECT";
   }
   ```

2. Configure via Group Policy:
   ```
   [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings]
   "AutoConfigURL"="http://your-server/proxy.pac"
   ```
