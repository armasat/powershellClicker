param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-Not (Test-Path $ConfigFile)) {
    Write-Host "Configuration file not found: $ConfigFile"
    exit
}

# Load JSON config
$config = Get-Content $ConfigFile | ConvertFrom-Json
$coords = $config.Coords
$clickCount = $config.ClickCount

# Get primary screen size
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# Main form: fullscreen, transparent
$form = New-Object System.Windows.Forms.Form
$form.Text = "Draggable Red Boxes"
$form.StartPosition = "Manual"
$form.Size = [System.Drawing.Size]::new($screenWidth,$screenHeight)
$form.Location = [System.Drawing.Point]::new(0,0)
$form.TopMost = $true
$form.FormBorderStyle = 'None'
$form.BackColor = [System.Drawing.Color]::White
$form.TransparencyKey = [System.Drawing.Color]::White

$size = 25  # box size
$boxes = @()

function Add-DragEvents {
    param($ctrl)

    $ctrl.Add_MouseDown({
        param($s,$e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $s.Parent.Tag.IsDragging = $true
            $s.Parent.Tag.Offset = $e.Location
        }
    })
    $ctrl.Add_MouseMove({
        param($s,$e)
        if ($s.Parent.Tag.IsDragging) {
            $screenPoint = $s.Parent.PointToScreen($e.Location)
            $parentScreen = $s.Parent.Parent.PointToScreen([System.Drawing.Point]::Empty)
            $s.Parent.Location = [System.Drawing.Point]::new(
                $screenPoint.X - $parentScreen.X - $s.Parent.Tag.Offset.X,
                $screenPoint.Y - $parentScreen.Y - $s.Parent.Tag.Offset.Y
            )
        }
    })
    $ctrl.Add_MouseUp({
        param($s,$e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $s.Parent.Tag.IsDragging = $false
        }
    })
}

for ($i = 0; $i -lt $clickCount; $i++) {
    $xCoord = [int]$coords[$i][0]
    $yCoord = [int]$coords[$i][1]

    $panel = New-Object System.Windows.Forms.Panel
    $panel.BackColor = [System.Drawing.Color]::Red
    $panel.Size = [System.Drawing.Size]::new($size,$size)
    $panel.Location = [System.Drawing.Point]::new($xCoord - [int]($size/2), $yCoord - [int]($size/2))
    $panel.Cursor = [System.Windows.Forms.Cursors]::SizeAll

    # Keep index in Tag
    $panel.Tag = [PSCustomObject]@{ IsDragging=$false; Offset=[System.Drawing.Point]::Empty; Index=$i }

    # Label for click number
    $label = New-Object System.Windows.Forms.Label
    $label.Text = ($i+1).ToString()
    $label.ForeColor = [System.Drawing.Color]::White
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label.TextAlign = "MiddleCenter"
    $label.Dock = "Fill"
    $panel.Controls.Add($label)

    # Add drag events to both panel and label
    Add-DragEvents $panel
    Add-DragEvents $label

    $form.Controls.Add($panel)
    $boxes += $panel
}

# Update & Close button
$btn = New-Object System.Windows.Forms.Button
$btn.Text = "Update & Close"
$btn.Size = [System.Drawing.Size]::new(120,50)
$btn.Location = [System.Drawing.Point]::new(10,10)
$btn.BackColor = [System.Drawing.Color]::Purple
$btn.ForeColor = [System.Drawing.Color]::Yellow
$btn.Font = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Bold)

$btn.Add_Click({
    # Update coordinates from box positions
    $newCoords = @()
    foreach ($b in $boxes | Sort-Object {$_.Tag.Index}) {
        $centerX = $b.Left + [int]($b.Width/2)
        $centerY = $b.Top + [int]($b.Height/2)
        $newCoords += ,@($centerX,$centerY)
    }
    $config.Coords = $newCoords
    $config | ConvertTo-Json -Depth 5 | Set-Content $ConfigFile

    $form.Close()
})

$form.Controls.Add($btn)

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
