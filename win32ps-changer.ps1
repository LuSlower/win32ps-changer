# Check administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Console
{
    param ([Switch]$Show,[Switch]$Hide)
    if (-not ("Console.Window" -as [type])) { 

        Add-Type -Name Window -Namespace Console -MemberDefinition '
        [DllImport("Kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
        '
    }

    if ($Show)
    {
        $consolePtr = [Console.Window]::GetConsoleWindow()

        $null = [Console.Window]::ShowWindow($consolePtr, 5)
    }

    if ($Hide)
    {
        $consolePtr = [Console.Window]::GetConsoleWindow()
        $null = [Console.Window]::ShowWindow($consolePtr, 0)
    }
}

Add-Type -AssemblyName System.Windows.Forms

# calcular Win32PrioritySeparation bitmask
function Calculate-Win32PrioritySeparation {
    param (
        [string]$highBits,
        [string]$middleBits,
        [string]$lowBits
    )

    $bitString = "$highBits$middleBits$lowBits"
    $decimalValue = [Convert]::ToInt32($bitString, 2)

    return $decimalValue
}

# establecer Win32PrioritySeparation
function Set-Win32PrioritySeparation {
    param (
        [int]$newValue
    )
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    $valueName = "Win32PrioritySeparation"
    Set-ItemProperty -Path $key -Name $valueName -Value $newValue
}

# obtener Win32PrioritySeparation
function Get-CurrentWin32PrioritySeparation {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    $valueName = "Win32PrioritySeparation"
    $currentValueDecimal = Get-ItemProperty -Path $key -Name $valueName | Select-Object -ExpandProperty $valueName
    $currentValueHex = "{0:X}" -f $currentValueDecimal
    $currentValueBinary = [Convert]::ToString([Convert]::ToInt32($currentValueDecimal, 10), 2).PadLeft(6, '0')

    $highBits = $currentValueBinary.Substring(0, 2)
    $middleBits = $currentValueBinary.Substring(2, 2)
    $lowBits = $currentValueBinary.Substring(4, 2)

    $highDescription = switch ($highBits) {
        "00" { "Default" }
        "01" { "Long" }
        "10" { "Short" }
        "11" { "Default" }
        default { "Default" }
    }

    $middleDescription = switch ($middleBits) {
        "00" { "Default" }
        "01" { "Variable" }
        "10" { "Fixed" }
        "00" { "Default" }
        default { "Default" }
    }

    $lowDescription = switch ($lowBits) {
        "00" { "1:1" }
        "01" { "2:1" }
        "10" { "3:1" }
        "11" { "3:1" }
        default { "Default" }
    }

    return $currentValueHex, $currentValueDecimal, $currentValueBinary, $highDescription, $middleDescription, $lowDescription
}

function Update-Current {
    $currentValueHex, $currentValueDecimal, $currentValueBinary, $highDescription, $middleDescription, $lowDescription = Get-CurrentWin32PrioritySeparation

    $labelHexValue.Text = "Hexadecimal: " + $currentValueHex
    $labelDecimalValue.Text = "Decimal: " + $currentValueDecimal
    $labelBinaryValue.Text = "Binary Value: " + $currentValueBinary
    $labelHighDescription.Text = "Short or Long: " + $highDescription
    $labelMiddleDescription.Text = "Variable or Fixed: " + $middleDescription
    $labelLowDescription.Text = "PrioritySeparation: " + $lowDescription
    $textBoxBitmask.Text = $currentValueBinary
}

# crear form
Console -Hide
[System.Windows.Forms.Application]::EnableVisualStyles();
$form = New-Object System.Windows.Forms.Form
$form.Text = "win32ps-changer"
$form.ClientSize = New-Object System.Drawing.Size(400, 190)
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.KeyPreview = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)
$form.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F5) {
        Update-Current
    }
})

# mostrar los datos del valor actual
$currentValueHex, $currentValueDecimal, $currentValueBinary, $highDescription, $middleDescription, $lowDescription = Get-CurrentWin32PrioritySeparation
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Text = "Current"
$groupBox.BackColor = [System.Drawing.Color]::Transparent
$groupBox.ForeColor = [System.Drawing.Color]::White
$groupBox.Size = New-Object System.Drawing.Size(200, 165)
$groupBox.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($groupBox)

# Crear y configurar los labels
$labelHexValue = New-Object System.Windows.Forms.Label
$labelHexValue.Text = "Hexadecimal: " + $currentvalueHex
$labelHexValue.BackColor = [System.Drawing.Color]::Transparent
$labelHexValue.ForeColor = [System.Drawing.Color]::White
$labelHexValue.Size = New-Object System.Drawing.Size(130, 15)
$labelHexValue.Location = New-Object System.Drawing.Point(10, 30)
$groupBox.Controls.Add($labelHexValue)

$labelDecimalValue = New-Object System.Windows.Forms.Label
$labelDecimalValue.Text = "Decimal: " + $currentvalueDecimal
$labelDecimalValue.BackColor = [System.Drawing.Color]::Transparent
$labelDecimalValue.ForeColor = [System.Drawing.Color]::White
$labelDecimalValue.Size = New-Object System.Drawing.Size(130, 15)
$labelDecimalValue.Location = New-Object System.Drawing.Point(10, 50)
$groupBox.Controls.Add($labelDecimalValue)

$labelBinaryValue = New-Object System.Windows.Forms.Label
$labelBinaryValue.Text = "Binary Value: " + $currentvalueBinary
$labelBinaryValue.BackColor = [System.Drawing.Color]::Transparent
$labelBinaryValue.ForeColor = [System.Drawing.Color]::White
$labelBinaryValue.Size = New-Object System.Drawing.Size(130, 15)
$labelBinaryValue.Location = New-Object System.Drawing.Point(10, 70)
$groupBox.Controls.Add($labelBinaryValue)

$labelHighDescription = New-Object System.Windows.Forms.Label
$labelHighDescription.Text = "Short or Long: " + $highDescription
$labelHighDescription.BackColor = [System.Drawing.Color]::Transparent
$labelHighDescription.ForeColor = [System.Drawing.Color]::White
$labelHighDescription.Size = New-Object System.Drawing.Size(140, 15)
$labelHighDescription.Location = New-Object System.Drawing.Point(10, 90)
$groupBox.Controls.Add($labelHighDescription)

$labelMiddleDescription = New-Object System.Windows.Forms.Label
$labelMiddleDescription.Text = "Variable or Fixed: " + $middleDescription
$labelMiddleDescription.BackColor = [System.Drawing.Color]::Transparent
$labelMiddleDescription.ForeColor = [System.Drawing.Color]::White
$labelMiddleDescription.Size = New-Object System.Drawing.Size(140, 15)
$labelMiddleDescription.Location = New-Object System.Drawing.Point(10, 110)
$groupBox.Controls.Add($labelMiddleDescription)

$labelLowDescription = New-Object System.Windows.Forms.Label
$labelLowDescription.Text = "PrioritySeparation: "+ $lowDescription
$labelLowDescription.BackColor = [System.Drawing.Color]::Transparent
$labelLowDescription.ForeColor = [System.Drawing.Color]::White
$labelLowDescription.Size = New-Object System.Drawing.Size(130, 15)
$labelLowDescription.Location = New-Object System.Drawing.Point(10, 130)
$groupBox.Controls.Add($labelLowDescription)

# escribir una máscara de bits
$labelBitmask = New-Object System.Windows.Forms.Label
$labelBitmask.Text = "Bitmask"
$labelBitmask.BackColor = [System.Drawing.Color]::Transparent
$labelBitmask.ForeColor = [System.Drawing.Color]::White
$labelBitmask.Size = New-Object System.Drawing.Size(45, 15)
$labelBitmask.Location = New-Object System.Drawing.Point(260, 13)
$form.Controls.Add($labelBitmask)

$textBoxBitmask = New-Object System.Windows.Forms.TextBox
$textBoxBitmask.Text = $currentvalueBinary
$textBoxBitmask.Size = New-Object System.Drawing.Size(45, 20)
$textBoxBitmask.Location = New-Object System.Drawing.Point(310, 10)
$textBoxBitmask.MaxLength = 6  # Limitar la entrada a 6 dígitos
$textBoxBitmask.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$textBoxBitmask.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)
$textBoxBitmask.ForeColor = [System.Drawing.Color]::White
$textBoxBitmask.Add_KeyDown({
    param($sender, $e)
    if (-not ($e.KeyCode -eq [System.Windows.Forms.Keys]::D0 -or $e.KeyCode -eq [System.Windows.Forms.Keys]::D1 -or $e.KeyCode -eq [System.Windows.Forms.Keys]::NumPad0 -or $e.KeyCode -eq [System.Windows.Forms.Keys]::NumPad1 -or $e.KeyCode -eq [System.Windows.Forms.Keys]::Back)) {
        $e.SuppressKeyPress = $true
    }
})
$form.Controls.Add($textBoxBitmask)

# Definir los valores de radio buttons
$radioOptions = @(
    "2A (42) 101010, Short, Fixed , 3:1",
    "29 (41) 101001, Short, Fixed , 2:1",
    "28 (40) 101000, Short, Fixed , 1:1",
    "26 (38) 100110, Short, Variable , 3:1",
    "25 (37) 100101, Short, Variable , 2:1",
    "24 (36) 100100, Short, Variable , 1:1",
    "1A (26) 011010, Long, Fixed, 3:1",
    "19 (25) 011001, Long, Fixed, 2:1",
    "18 (24) 011000, Long, Fixed, 1:1",
    "16 (22) 010110, Long, Variable, 3:1",
    "15 (21) 010101, Long, Variable, 2:1",
    "14 (20) 010100, Long, Variable, 1:1"
)

# añadir multiples radios al form
$xPos = 230
$yPos = 40
$counter = 0
foreach ($option in $radioOptions) {
    $radioButton = New-Object System.Windows.Forms.RadioButton
    $textParts = $option.Split(' ')
    $radioButton.Text = $textParts[0,1]  # Mostrar hex (dec)
    $radioButton.Tag = $option  # Guardar la descripción completa en la propiedad Tag
    $radioButton.Location = New-Object System.Drawing.Point($xPos, $yPos)
    $radioButton.AutoSize = $true
    $radioButton.BackColor = [System.Drawing.Color]::Transparent
    $radioButton.ForeColor = [System.Drawing.Color]::White
    
    # ToolTip para mostrar informacion al hacer hover
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.SetToolTip($radioButton, $option.Substring(8))  # Mostrar bitmask y valores
    
    $form.Controls.Add($radioButton)
    
    $counter++
    if ($counter % 2 -eq 0) {
        $xPos = 230
        $yPos += 20
    } else {
        $xPos = 320
    }
}

# aplicar bitmask
$buttonBitmask = New-Object System.Windows.Forms.Button
$buttonBitmask.Text = "SetBitmask"
$buttonBitmask.Size = New-Object System.Drawing.Size(75, 20)
$buttonBitmask.Location = New-Object System.Drawing.Point(220, 165)
$buttonBitmask.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonBitmask.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$buttonBitmask.ForeColor = [System.Drawing.Color]::White
$buttonBitmask.FlatAppearance.BorderSize = 0
$buttonBitmask.Add_Click({
    $newBitmask = $textBoxBitmask.Text
    $highBits = $newBitmask.Substring(0, 2)
    $middleBits = $newBitmask.Substring(2, 2)
    $lowBits = $newBitmask.Substring(4, 2)
    $newValue = Calculate-Win32PrioritySeparation -highBits $highBits -middleBits $middleBits -lowBits $lowBits
    Set-Win32PrioritySeparation -newValue $newValue
    Update-Current
})
$form.Controls.Add($buttonBitmask)

# aplicar valor de radio
$buttonValue = New-Object System.Windows.Forms.Button
$buttonValue.Text = "SetValue"
$buttonValue.Size = New-Object System.Drawing.Size(75, 20)
$buttonValue.Location = New-Object System.Drawing.Point(310, 165)
$buttonValue.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonValue.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$buttonValue.ForeColor = [System.Drawing.Color]::White
$buttonValue.FlatAppearance.BorderSize = 0
$buttonValue.Add_Click({
    foreach ($control in $form.Controls) {
        if ($control -is [System.Windows.Forms.RadioButton] -and $control.Checked) {
            $valueText = $control.Text
            $value = [regex]::Match($valueText, '\((\d+)\)').Groups[1].Value
            Set-Win32PrioritySeparation -newValue $value
            break  # romper bucle
        }
    }
    Update-Current
})
$form.Controls.Add($buttonValue)

$form.ShowDialog()
