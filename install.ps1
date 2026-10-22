# Instalador interativo (EN/PT-BR) da imagem do Recalbox para a Radxa Dragon Q6A -- Windows.
#
# Baixa (ou usa arquivos ja baixados) as partes da release no GitHub, confere os checksums SHA256,
# reconstroi o .img.xz, descompacta e grava no disco de destino que voce escolher (SD card, pendrive,
# SSD externo ou case SSD NVMe) -- com confirmacao explicita antes de qualquer escrita.
#
# Interactive installer (EN/PT-BR) for the Recalbox image for the Radxa Dragon Q6A -- Windows.
#
# Downloads (or uses already-downloaded files) the release parts from GitHub, verifies SHA256 checksums,
# reassembles the .img.xz, decompresses it and writes it to the target disk you choose (SD card, USB stick,
# external SSD or NVMe SSD enclosure) -- with an explicit confirmation before any write.
#
# Requisitos / Requirements: Windows 10/11, PowerShell 5.1+, Administrator, 7-Zip (7z.exe) to unpack .xz
#   (winget install 7zip.7zip), ~6 GB free in %TEMP%.
# Uso / Usage (PowerShell as Administrator):
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Repositorio do GitHub de onde as releases sao baixadas / GitHub repository the releases are downloaded from.
$RepoSlug  = 'rafaelwms/q6a-recallbox'
$ImageType = 'recalbox'

$script:Lang = 'en'

$Msg = @{
  en = @{
    banner        = "==============================================================`n Radxa Dragon Q6A -- Recalbox`n Interactive installer (Windows)`n=============================================================="
    need_admin    = 'ERROR: run this script from a PowerShell opened as Administrator (it writes directly to a disk).'
    need_7z       = 'ERROR: 7-Zip (7z.exe) is needed to unpack the .xz image. Install it with:  winget install 7zip.7zip  -- then run this script again.'
    ask_source    = 'Where are the release files?'
    opt_download  = '1) Download them now from the latest GitHub release'
    opt_local     = '2) I already downloaded them -- point me to the folder'
    ask_local_dir = 'Path to the folder with the .part* and SHA256SUMS* files:'
    dir_not_found = 'ERROR: folder not found.'
    fetching      = '>>> Fetching latest release info from GitHub...'
    release_error = 'ERROR: could not fetch release info. Check your connection or $RepoSlug at the top of this script.'
    no_assets     = 'ERROR: no matching files found for that image.'
    downloading   = '>>> Downloading release files...'
    verifying_p   = '>>> Verifying the parts (SHA256)...'
    parts_ok      = '>>> All parts verified OK.'
    parts_nosums  = 'WARNING: SHA256SUMS-parts.txt not found -- skipping per-part verification.'
    parts_fail    = 'ERROR: checksum mismatch on a part. Re-download and try again:'
    reassembling  = '>>> Reassembling the image from the parts...'
    verifying_f   = '>>> Verifying the reassembled image (SHA256)...'
    full_ok       = '>>> Image verified OK -- matches the published checksum.'
    full_nosums   = 'WARNING: SHA256SUMS-full.txt not found -- skipping full-image verification.'
    full_fail     = 'ERROR: the reassembled image does NOT match the published checksum. Do not write it -- delete and try again.'
    unpacking     = '>>> Unpacking the image (.xz -> .img)...'
    listing       = '>>> Disks currently attached (the ones marked SYSTEM/BOOT are NOT offered):'
    no_disks      = 'ERROR: no removable/external disk found. Plug in the SD card, USB stick or SSD and try again.'
    ask_disk      = 'Type the disk NUMBER to erase and write (the Number column):'
    bad_disk      = 'ERROR: invalid choice -- it must be one of the numbers listed above.'
    confirm_head  = 'About to ERASE EVERYTHING on this disk:'
    confirm_ask   = 'Type FLASH (all caps) to confirm, or anything else to cancel:'
    cancelled     = 'Cancelled. Nothing was written.'
    preparing     = '>>> Preparing the disk (removing its partitions)...'
    flashing      = '>>> Writing... this can take several minutes, do not disconnect the disk.'
    done          = '>>> Done! Wait for this message, then use "Safely remove" before unplugging the disk.'
    next_steps    = "`nNext steps:`n  1. Plug the device into the Radxa Dragon Q6A (USB 3.0 SSD/pendrive, SD card or the internal NVMe) and`n     boot it from the UEFI boot menu (or from rEFInd, if you use it).`n  2. The first boot takes 1-2 minutes: Recalbox creates its SHARE (exFAT) and OVERLAY partitions in the free`n     space of the disk. Do not power off during this step.`n  3. Video: the Dragon Q6A HDMI output is limited to 4K@30Hz. The image already defaults to 1080p60;`n     on a 4K/120Hz TV you can pick 1080p at a higher refresh in Menu > System settings > Video.`n  4. SSH is enabled: user 'root', password 'recalboxroot' -- change it in recalbox.conf."
    confirm_word  = 'FLASH'
  }
  pt = @{
    banner        = "==============================================================`n Radxa Dragon Q6A -- Recalbox`n Instalador interativo (Windows)`n=============================================================="
    need_admin    = 'ERRO: rode este script num PowerShell aberto como Administrador (ele grava direto num disco).'
    need_7z       = 'ERRO: o 7-Zip (7z.exe) e necessario para descompactar a imagem .xz. Instale com:  winget install 7zip.7zip  -- e rode este script de novo.'
    ask_source    = 'Onde estao os arquivos da release?'
    opt_download  = '1) Baixar agora da ultima release do GitHub'
    opt_local     = '2) Ja baixei -- me diga a pasta'
    ask_local_dir = 'Caminho da pasta com os arquivos .part* e SHA256SUMS*:'
    dir_not_found = 'ERRO: pasta nao encontrada.'
    fetching      = '>>> Consultando a ultima release no GitHub...'
    release_error = 'ERRO: nao consegui consultar a release. Confira a conexao ou o $RepoSlug no topo deste script.'
    no_assets     = 'ERRO: nao achei arquivos correspondentes a essa imagem.'
    downloading   = '>>> Baixando os arquivos da release...'
    verifying_p   = '>>> Verificando as partes (SHA256)...'
    parts_ok      = '>>> Todas as partes verificadas com sucesso.'
    parts_nosums  = 'AVISO: SHA256SUMS-parts.txt nao encontrado -- pulando a verificacao das partes.'
    parts_fail    = 'ERRO: checksum nao bate em uma parte. Baixe de novo e tente outra vez:'
    reassembling  = '>>> Reconstruindo a imagem a partir das partes...'
    verifying_f   = '>>> Verificando a imagem reconstruida (SHA256)...'
    full_ok       = '>>> Imagem verificada com sucesso -- bate com o checksum publicado.'
    full_nosums   = 'AVISO: SHA256SUMS-full.txt nao encontrado -- pulando a verificacao da imagem completa.'
    full_fail     = 'ERRO: a imagem reconstruida NAO bate com o checksum publicado. Nao grave -- apague e tente de novo.'
    unpacking     = '>>> Descompactando a imagem (.xz -> .img)...'
    listing       = '>>> Discos conectados agora (os marcados SYSTEM/BOOT NAO sao oferecidos):'
    no_disks      = 'ERRO: nenhum disco removivel/externo encontrado. Conecte o cartao SD, pendrive ou SSD e tente de novo.'
    ask_disk      = 'Digite o NUMERO do disco a apagar e gravar (coluna Number):'
    bad_disk      = 'ERRO: escolha invalida -- precisa ser um dos numeros listados acima.'
    confirm_head  = 'Isso vai APAGAR TUDO neste disco:'
    confirm_ask   = 'Digite GRAVAR (maiusculas) para confirmar, ou qualquer outra coisa para cancelar:'
    cancelled     = 'Cancelado. Nada foi gravado.'
    preparing     = '>>> Preparando o disco (removendo as particoes)...'
    flashing      = '>>> Gravando... pode levar varios minutos, nao desconecte o disco.'
    done          = '>>> Pronto! Espere esta mensagem e use "Remover com seguranca" antes de desconectar o disco.'
    next_steps    = "`nProximos passos:`n  1. Ligue o dispositivo na Radxa Dragon Q6A (SSD/pendrive USB 3.0, cartao SD ou o NVMe interno) e de boot`n     pelo menu de boot do UEFI (ou pelo rEFInd, se voce usa).`n  2. O primeiro boot leva 1-2 minutos: o Recalbox cria as particoes SHARE (exFAT) e OVERLAY no espaco livre`n     do disco. Nao desligue durante essa etapa.`n  3. Video: a saida HDMI da Dragon Q6A e limitada a 4K@30Hz. A imagem ja vem em 1080p60 por padrao;`n     numa TV 4K/120Hz voce pode escolher 1080p numa taxa maior em Menu > Configuracoes do sistema > Video.`n  4. O SSH vem ligado: usuario 'root', senha 'recalboxroot' -- troque no recalbox.conf."
    confirm_word  = 'GRAVAR'
  }
}
function T($key) { $Msg[$script:Lang][$key] }

function Get-Sha256($path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower() }

# Confere um arquivo SHA256SUMS contra os arquivos da pasta atual / Verify a SHA256SUMS file against the files in the folder.
function Test-Sums($sumsFile) {
  $bad = @()
  foreach ($line in Get-Content -LiteralPath $sumsFile) {
    if ($line -notmatch '^([0-9a-fA-F]{64})\s+\*?(.+)$') { continue }
    $want = $Matches[1].ToLower(); $name = $Matches[2].Trim()
    if (-not (Test-Path -LiteralPath $name)) { continue }       # equivalente a --ignore-missing
    if ((Get-Sha256 $name) -ne $want) { $bad += $name }
  }
  return $bad
}

# ---------------- Administrador / Administrator ----------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ---------------- Idioma / Language ----------------
if ((Get-UICulture).Name -like 'pt*') { $script:Lang = 'pt' }
Write-Host 'Choose language / Escolha o idioma:'
Write-Host '  1) English'
Write-Host '  2) Portugues'
$pick = Read-Host '>'
if ($pick -in @('2', 'pt', 'PT')) { $script:Lang = 'pt' } elseif ($pick -in @('1', 'en', 'EN')) { $script:Lang = 'en' }

Write-Host (T 'banner'); Write-Host ''
if (-not $isAdmin) { Write-Host (T 'need_admin') -ForegroundColor Red; exit 1 }

# 7-Zip
$sevenZip = $null
foreach ($c in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) { if (Test-Path $c) { $sevenZip = $c; break } }
if (-not $sevenZip) { $cmd = Get-Command 7z.exe -ErrorAction SilentlyContinue; if ($cmd) { $sevenZip = $cmd.Source } }
if (-not $sevenZip) { Write-Host (T 'need_7z') -ForegroundColor Red; exit 1 }

# ---------------- Origem dos arquivos / Where the files come from ----------------
Write-Host ''; Write-Host (T 'ask_source'); Write-Host (T 'opt_download'); Write-Host (T 'opt_local')
$src = Read-Host '>'

$work = Join-Path $env:TEMP ("q6a-recalbox-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
try {
  if ($src -eq '2') {
    $dir = Read-Host (T 'ask_local_dir')
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { Write-Host (T 'dir_not_found') -ForegroundColor Red; exit 1 }
    Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Name -like "*$ImageType*" -or $_.Name -like 'SHA256SUMS-*.txt' } | Copy-Item -Destination $work
  } else {
    Write-Host (T 'fetching')
    # /releases/latest ignores pre-releases, so take the newest entry of the list instead
    try { $rel = @(Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoSlug/releases?per_page=1" -Headers @{ 'User-Agent' = 'q6a-recalbox-installer' })[0] }
    catch { Write-Host (T 'release_error') -ForegroundColor Red; exit 1 }
    $assets = @($rel.assets | Where-Object { $_.name -like "*$ImageType*" -or $_.name -like 'SHA256SUMS*' })
    if ($assets.Count -eq 0) { Write-Host (T 'no_assets') -ForegroundColor Red; exit 1 }
    Write-Host (T 'downloading')
    foreach ($a in $assets) {
      Write-Host "  -> $($a.name)"
      & curl.exe -L --fail -sS -o (Join-Path $work $a.name) $a.browser_download_url
      if ($LASTEXITCODE -ne 0) { Write-Host (T 'release_error') -ForegroundColor Red; exit 1 }
    }
  }

  Push-Location $work
  # ---------------- Partes / Parts ----------------
  Write-Host (T 'verifying_p')
  if (Test-Path SHA256SUMS-parts.txt) {
    $bad = Test-Sums 'SHA256SUMS-parts.txt'
    if ($bad.Count -gt 0) { Write-Host (T 'parts_fail') -ForegroundColor Red; $bad | ForEach-Object { Write-Host "  $_" }; exit 1 }
    Write-Host (T 'parts_ok')
  } else { Write-Host (T 'parts_nosums') -ForegroundColor Yellow }

  # ---------------- Reconstroi / Reassemble ----------------
  Write-Host (T 'reassembling')
  $whole = Get-ChildItem -File -Filter "*$ImageType*.img.xz" | Select-Object -First 1
  if ($whole) { $imgXz = $whole.FullName } else {
    $parts = @(Get-ChildItem -File -Filter "*$ImageType*.img.xz.part*" | Sort-Object Name)
    if ($parts.Count -eq 0) { Write-Host (T 'no_assets') -ForegroundColor Red; exit 1 }
    $imgXz = Join-Path $work ($parts[0].Name -replace '\.part\d+$', '')
    $out = [IO.File]::Create($imgXz)
    try { foreach ($p in $parts) { $in = [IO.File]::OpenRead($p.FullName); try { $in.CopyTo($out, 4MB) } finally { $in.Dispose() } } } finally { $out.Dispose() }
  }
  Write-Host (T 'verifying_f')
  if (Test-Path SHA256SUMS-full.txt) {
    $bad = Test-Sums 'SHA256SUMS-full.txt'
    if ($bad.Count -gt 0) { Write-Host (T 'full_fail') -ForegroundColor Red; exit 1 }
    Write-Host (T 'full_ok')
  } else { Write-Host (T 'full_nosums') -ForegroundColor Yellow }

  Write-Host (T 'unpacking')
  & $sevenZip x -y "-o$work" $imgXz | Out-Null
  if ($LASTEXITCODE -ne 0) { Write-Host 'ERROR: 7-Zip failed to unpack the image.' -ForegroundColor Red; exit 1 }
  $img = Get-ChildItem -File -Filter '*.img' | Select-Object -First 1
  if (-not $img) { Write-Host 'ERROR: unpacked image not found.' -ForegroundColor Red; exit 1 }
  Pop-Location

  # ---------------- Escolha do disco / Disk choice ----------------
  Write-Host ''; Write-Host (T 'listing')
  $all = @(Get-Disk)
  $all | Select-Object Number, FriendlyName, @{n = 'SizeGB'; e = { [math]::Round($_.Size / 1GB, 1) } }, BusType, PartitionStyle,
    @{n = 'Note'; e = { if ($_.IsSystem -or $_.IsBoot) { 'SYSTEM/BOOT -- not offered' } else { '' } } } | Format-Table -AutoSize | Out-Host
  $allowed = @($all | Where-Object { -not $_.IsSystem -and -not $_.IsBoot -and $_.Size -gt 0 })
  if ($allowed.Count -eq 0) { Write-Host (T 'no_disks') -ForegroundColor Red; exit 1 }
  $num = Read-Host (T 'ask_disk')
  $disk = $allowed | Where-Object { "$($_.Number)" -eq $num.Trim() }
  if (-not $disk) { Write-Host (T 'bad_disk') -ForegroundColor Red; exit 1 }
  if ($disk.Size -lt $img.Length) { Write-Host "ERROR: disk too small / disco pequeno demais ($([math]::Round($disk.Size/1GB,1)) GB < $([math]::Round($img.Length/1GB,1)) GB)." -ForegroundColor Red; exit 1 }

  Write-Host ''; Write-Host (T 'confirm_head')
  $disk | Select-Object Number, FriendlyName, @{n = 'SizeGB'; e = { [math]::Round($_.Size / 1GB, 1) } }, BusType | Format-List | Out-Host
  $ans = Read-Host (T 'confirm_ask')
  if ($ans -ne (T 'confirm_word')) { Write-Host (T 'cancelled'); exit 0 }

  # ---------------- Grava / Flash ----------------
  Write-Host (T 'preparing')
  Set-Disk -Number $disk.Number -IsOffline $false -ErrorAction SilentlyContinue
  Set-Disk -Number $disk.Number -IsReadOnly $false -ErrorAction SilentlyContinue
  Clear-Disk -Number $disk.Number -RemoveData -RemoveOEM -Confirm:$false

  Write-Host (T 'flashing')
  $bufSize = 4MB
  $buf = New-Object byte[] $bufSize
  $in = [IO.File]::OpenRead($img.FullName)
  $dst = New-Object IO.FileStream("\\.\PhysicalDrive$($disk.Number)", [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite, 8, [IO.FileOptions]::WriteThrough)
  try {
    $total = $in.Length; $done = 0L; $sw = [Diagnostics.Stopwatch]::StartNew()
    while (($n = $in.Read($buf, 0, $bufSize)) -gt 0) {
      $w = [int]([math]::Ceiling($n / 512.0) * 512)                  # a escrita crua precisa ser multipla do setor / raw writes must be sector-aligned
      if ($w -gt $n) { [Array]::Clear($buf, $n, $w - $n) }
      $dst.Write($buf, 0, $w); $done += $n
      if ($sw.ElapsedMilliseconds -gt 1000) { $sw.Restart(); Write-Host ("`r  {0:N0} / {1:N0} MB ({2:P0})" -f ($done / 1MB), ($total / 1MB), ($done / $total)) -NoNewline }
    }
    $dst.Flush()
    Write-Host ''
  } finally { $dst.Dispose(); $in.Dispose() }
  Update-HostStorageCache -ErrorAction SilentlyContinue
  Write-Host (T 'done') -ForegroundColor Green
  Write-Host (T 'next_steps')
}
finally {
  Pop-Location -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
