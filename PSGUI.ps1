﻿$TestObject = [pscustomobject]@{
	String = "test"
	multi = "test `n multiline"
	Stringb = "test"
	Stringc = "test"
	multibssssss = "test `n multiline"
	multic = "test `n multiline"
	multid = "test `n multiline"
	Int = 23
	Double = 23.1
	Bool = $true
	Boolongername = $true
	datetimeTYPE = [datetime]
	datetimeEX = [datetime]"Tuesday, January 3, 2017 1:59:11 AM"
	Char = [char]"A"
	longo = [long]123456789012345678
	weird = [System.Windows.Forms.PictureBoxSizeMode]
	GUID = New-Guid
	sid = Get-ADUser -Identity 'zachary.fischer' | Select-Object SID
}

$TestObjectB = [pscustomobject]@{
	String = [string]
	Int = [int]
	Double = [double]
	Bool = [bool]
	datetime = [datetime]
}
#This is a test

#bug with RuntimeTypes
function Get-PSObjectParamTypes () {
	param(
		$Object
	)
	$NoteProperties = $object | Get-Member -MemberType NoteProperty
	foreach ($property in $NoteProperties)
	{
		$Pdefinition = $property.Definition.split(" ")
		$PType = $Pdefinition[0]
		if ($PType -eq "RuntimeType") {
			$PType = $Pdefinition[1].split(".",2)[1]
		}

		Add-Member -InputObject $property -MemberType NoteProperty -Name "Type" -Value $PType
	}

	return $NoteProperties
}

function Show-Psgui () {
	param(
		$object,
		[int]$height = 600,
		[int]$width = 600,
		[string]$font = 'Microsoft Sans Serif,10'
	)
	$tmpobj = $object
	$Form = New-Object system.Windows.Forms.Form
	#TODO automate width and height
	$Form.ClientSize = "$width,$height"
	$Form.text = "Form"
	$Form.TopMost = $false

	$NoteProperties = Get-PSObjectParamTypes $object
	$currentX = 15
	$currentY = 15
	$maxFieldWidths = 0
	$fields = @()
	$fieldCount = 0

	#get biggest label
	$labelwidth = 0
	($NoteProperties | Where-Object { $_.type -ne "bool" }) | ForEach-Object { if ((Get-StringSize -Font $font -String "[$($_.Type)] $($_.Name)").width -gt $labelwidth) { $labelwidth = [math]::Ceiling((Get-StringSize -Font $font -String "[$($_.Type)] $($_.Name)").width) } }
	$labelwidth += 5

	foreach ($NP in $NoteProperties)
	{
		switch ($NP.type) {
			bool {
				New-Variable -Name "Checkbox_$($np.Name)" -Value (New-Object system.Windows.Forms.CheckBox)
				(Get-Variable -Name "Checkbox_$($np.Name)").Value.text = "$($np.Name)"
				(Get-Variable -Name "Checkbox_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Checkbox_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Checkbox_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'
				(Get-Variable -Name "Checkbox_$($np.Name)").Value.checked = $object. "$($np.Name)"

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Checkbox_$($np.Name)").Value)
				(Get-Variable -Name "Checkbox_$($np.Name)").Value.width = [math]::Ceiling($FontSize.width) + 25
				(Get-Variable -Name "Checkbox_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 5


				#add field to form
				$fields += $getfixobj = [pscustomobject]@{ type = "CheckBox"; Name = "$($np.Name)"; object = ((Get-Variable -Name "CheckBox_$($np.Name)").Value) }
				$currentY = ((Get-Variable -Name "Checkbox_$($np.Name)").Value.height + (Get-Variable -Name "Checkbox_$($np.Name)").Value.location.y) + 5

				if ($maxFieldWidths -lt ((Get-Variable -Name "Checkbox_$($np.Name)").Value.width + (Get-Variable -Name "Checkbox_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "Checkbox_$($np.Name)").Value.width + (Get-Variable -Name "Checkbox_$($np.Name)").Value.location.x) + 15
				}
			}
			string {
				#Create Label field for the string input
				New-Variable -Name "Label_$($np.Name)" -Value (New-Object system.Windows.Forms.Label)
				(Get-Variable -Name "Label_$($np.Name)").Value.text = "[$($np.Type)] $($np.Name)"
				(Get-Variable -Name "Label_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Label_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Label_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Label_$($np.Name)").Value)
				(Get-Variable -Name "Label_$($np.Name)").Value.width = $labelwidth
				(Get-Variable -Name "Label_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height)
				#add field to form
				$fields += $getfixobj = [pscustomobject]@{ type = "Label"; Name = "$($np.Name)"; object = ((Get-Variable -Name "Label_$($np.Name)").Value) }



				#Get Position of textbox after label
				$tmpX = $currentX + (Get-Variable -Name "Label_$($np.Name)").Value.width + 5

				#create Textbox element
				New-Variable -Name "TextBox_$($np.Name)" -Value (New-Object system.Windows.Forms.TextBox)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.location = New-Object System.Drawing.Point ($tmpX,$currentY)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'


				#check if input should be multiline              
				if ($object. "$($np.Name)".GetType().Name -eq "string") {
					if ($object. "$($np.Name)".Contains("`n")) {
						(Get-Variable -Name "TextBox_$($np.Name)").Value.multiline = $true
						(Get-Variable -Name "TextBox_$($np.Name)").Value.Scrollbars = "Vertical"
						(Get-Variable -Name "TextBox_$($np.Name)").Value.text = $object. "$($np.Name)"
					}
					(Get-Variable -Name "TextBox_$($np.Name)").Value.text = $object. "$($np.Name)"
				}

				#resize textbox
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "TextBox_$($np.Name)").Value)
				if ($FontSize.width -lt 200)
				{
					(Get-Variable -Name "TextBox_$($np.Name)").Value.width = 200
				}
				else {
					(Get-Variable -Name "TextBox_$($np.Name)").Value.width = [math]::Ceiling($FontSize.width) + 10
				}
				if ($FontSize.height -lt 20)
				{
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = 20
				}
				else {
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 3 + ([math]::Ceiling($FontSize.height / 2))
				}

				#add textbox to form
				$fields += $getfixobj = [pscustomobject]@{ type = "TextBox"; Name = "$($np.Name)"; object = ((Get-Variable -Name "TextBox_$($np.Name)").Value) }


				if ($maxFieldWidths -lt ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x) + 15
				}
				$currentY = ((Get-Variable -Name "TextBox_$($np.Name)").Value.height + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.y) + 5


			}
			char {
				#Create Label field for the string input
				New-Variable -Name "Label_$($np.Name)" -Value (New-Object system.Windows.Forms.Label)
				(Get-Variable -Name "Label_$($np.Name)").Value.text = "[$($np.Type)] $($np.Name)"
				(Get-Variable -Name "Label_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Label_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Label_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Label_$($np.Name)").Value)
				(Get-Variable -Name "Label_$($np.Name)").Value.width = $labelwidth
				(Get-Variable -Name "Label_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height)
				#add field to form
				$fields += $getfixobj = [pscustomobject]@{ type = "Label"; Name = "$($np.Name)"; object = ((Get-Variable -Name "Label_$($np.Name)").Value) }



				#Get Position of textbox after label
				$tmpX = $currentX + (Get-Variable -Name "Label_$($np.Name)").Value.width + 5

				#create Textbox element
				New-Variable -Name "TextBox_$($np.Name)" -Value (New-Object system.Windows.Forms.TextBox)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.location = New-Object System.Drawing.Point ($tmpX,$currentY)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'
				(Get-Variable -Name "TextBox_$($np.Name)").Value.text = $object. "$($np.Name)"
				(Get-Variable -Name "TextBox_$($np.Name)").Value.width = 20
				(Get-Variable -Name "TextBox_$($np.Name)").Value.maxlength = 1

				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "TextBox_$($np.Name)").Value)
				if ($FontSize.height -lt 20)
				{
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = 20
				}
				else {
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 3 + ([math]::Ceiling($FontSize.height / 2))
				}

				#add textbox to form
				$fields += $getfixobj = [pscustomobject]@{ type = "TextBox"; Name = "$($np.Name)"; object = ((Get-Variable -Name "TextBox_$($np.Name)").Value) }


				if ($maxFieldWidths -lt ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x) + 15
				}
				$currentY = ((Get-Variable -Name "TextBox_$($np.Name)").Value.height + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.y) + 5

			}
			int {
				#Create Label field for the string input
				New-Variable -Name "Label_$($np.Name)" -Value (New-Object system.Windows.Forms.Label)
				(Get-Variable -Name "Label_$($np.Name)").Value.text = "[$($np.Type)] $($np.Name)"
				(Get-Variable -Name "Label_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Label_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Label_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Label_$($np.Name)").Value)
				(Get-Variable -Name "Label_$($np.Name)").Value.width = $labelwidth
				(Get-Variable -Name "Label_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height)
				#add field to form
				$fields += $getfixobj = [pscustomobject]@{ type = "Label"; Name = "$($np.Name)"; object = ((Get-Variable -Name "Label_$($np.Name)").Value) }



				#Get Position of textbox after label
				$tmpX = $currentX + (Get-Variable -Name "Label_$($np.Name)").Value.width + 5

				#create Textbox element
				New-Variable -Name "TextBox_$($np.Name)" -Value (New-Object system.Windows.Forms.TextBox)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.location = New-Object System.Drawing.Point ($tmpX,$currentY)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'
				(Get-Variable -Name "TextBox_$($np.Name)").Value.text = $object. "$($np.Name)"
				(Get-Variable -Name "TextBox_$($np.Name)").Value.width = 200
				(Get-Variable -Name "TextBox_$($np.Name)").Value.maxlength = 10

				(Get-Variable -Name "TextBox_$($np.Name)").Value.add_TextChanged({
						#Found at https://stackoverflow.com/questions/38404631/limiting-text-box-entry-to-numbers-or-numpad-only-no-special-characters
						# Check if Text contains any non-Digits
						$Global:ta = $this
						if ($this.text -match '\D') {
							# If so, remove them
							$this.text = $this.text -replace '\D'
							# If Text still has a value, move the cursor to the end of the number
							if ($this.text.Length -gt 0) {
								$this.Focus()
								$this.SelectionStart = $this.text.Length
							}
						}

					})

				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "TextBox_$($np.Name)").Value)
				if ($FontSize.height -lt 20)
				{
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = 20
				}
				else {
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 3 + ([math]::Ceiling($FontSize.height / 2))
				}

				#add textbox to form
				$fields += $getfixobj = [pscustomobject]@{ type = "TextBox"; Name = "$($np.Name)"; object = ((Get-Variable -Name "TextBox_$($np.Name)").Value) }


				if ($maxFieldWidths -lt ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x) + 15
				}
				$currentY = ((Get-Variable -Name "TextBox_$($np.Name)").Value.height + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.y) + 5

			}
			long {
				#Create Label field for the string input
				New-Variable -Name "Label_$($np.Name)" -Value (New-Object system.Windows.Forms.Label)
				(Get-Variable -Name "Label_$($np.Name)").Value.text = "[$($np.Type)] $($np.Name)"
				(Get-Variable -Name "Label_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Label_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Label_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Label_$($np.Name)").Value)
				(Get-Variable -Name "Label_$($np.Name)").Value.width = $labelwidth
				(Get-Variable -Name "Label_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height)
				#add field to form
				$fields += $getfixobj = [pscustomobject]@{ type = "Label"; Name = "$($np.Name)"; object = ((Get-Variable -Name "Label_$($np.Name)").Value) }



				#Get Position of textbox after label
				$tmpX = $currentX + (Get-Variable -Name "Label_$($np.Name)").Value.width + 5

				#create Textbox element
				New-Variable -Name "TextBox_$($np.Name)" -Value (New-Object system.Windows.Forms.TextBox)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.location = New-Object System.Drawing.Point ($tmpX,$currentY)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'
				(Get-Variable -Name "TextBox_$($np.Name)").Value.text = $object. "$($np.Name)"
				(Get-Variable -Name "TextBox_$($np.Name)").Value.width = 200
				(Get-Variable -Name "TextBox_$($np.Name)").Value.maxlength = 19

				(Get-Variable -Name "TextBox_$($np.Name)").Value.add_TextChanged({
						#Found at https://stackoverflow.com/questions/38404631/limiting-text-box-entry-to-numbers-or-numpad-only-no-special-characters
						# Check if Text contains any non-Digits
						$Global:ta = $this
						if ($this.text -match '\D') {
							# If so, remove them
							$this.text = $this.text -replace '\D'
							# If Text still has a value, move the cursor to the end of the number
							if ($this.text.Length -gt 0) {
								$this.Focus()
								$this.SelectionStart = $this.text.Length
							}
						}

					})

				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "TextBox_$($np.Name)").Value)
				if ($FontSize.height -lt 20)
				{
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = 20
				}
				else {
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 3 + ([math]::Ceiling($FontSize.height / 2))
				}

				#add textbox to form
				$fields += $getfixobj = [pscustomobject]@{ type = "TextBox"; Name = "$($np.Name)"; object = ((Get-Variable -Name "TextBox_$($np.Name)").Value) }


				if ($maxFieldWidths -lt ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x) + 15
				}
				$currentY = ((Get-Variable -Name "TextBox_$($np.Name)").Value.height + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.y) + 5

			}
			{ ($_ -eq "double") -or ($_ -eq "decimal") -or ($_ -eq "single") } {
				#Create Label field for the string input
				New-Variable -Name "Label_$($np.Name)" -Value (New-Object system.Windows.Forms.Label)
				(Get-Variable -Name "Label_$($np.Name)").Value.text = "[$($np.Type)] $($np.Name)"
				(Get-Variable -Name "Label_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Label_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Label_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Label_$($np.Name)").Value)
				(Get-Variable -Name "Label_$($np.Name)").Value.width = $labelwidth
				(Get-Variable -Name "Label_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height)
				#add field to form
				$fields += $getfixobj = [pscustomobject]@{ type = "Label"; Name = "$($np.Name)"; object = ((Get-Variable -Name "Label_$($np.Name)").Value) }



				#Get Position of textbox after label
				$tmpX = $currentX + (Get-Variable -Name "Label_$($np.Name)").Value.width + 5

				#create Textbox element
				New-Variable -Name "TextBox_$($np.Name)" -Value (New-Object system.Windows.Forms.TextBox)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.location = New-Object System.Drawing.Point ($tmpX,$currentY)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'
				(Get-Variable -Name "TextBox_$($np.Name)").Value.text = $object. "$($np.Name)"
				Add-Member -InputObject (Get-Variable -Name "TextBox_$($np.Name)").Value -MemberType NoteProperty -Name LastValid -Value $object. "$($np.Name)"
				(Get-Variable -Name "TextBox_$($np.Name)").Value.width = 200

				(Get-Variable -Name "TextBox_$($np.Name)").Value.add_TextChanged({
						#check if decimal
						try { [decimal]$this.text }
						catch {
							# If so, remove them
							$this.text = $this.lastvalid
							if ($this.text.Length -gt 0) {
								$this.Focus()
								$this.SelectionStart = $this.text.Length
							}

						}
						$this.lastvalid = $this.text

					})

				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "TextBox_$($np.Name)").Value)
				if ($FontSize.height -lt 20)
				{
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = 20
				}
				else {
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 3 + ([math]::Ceiling($FontSize.height / 2))
				}

				#add textbox to form
				$fields += $getfixobj = [pscustomobject]@{ type = "TextBox"; Name = "$($np.Name)"; object = ((Get-Variable -Name "TextBox_$($np.Name)").Value) }


				if ($maxFieldWidths -lt ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x) + 15
				}
				$currentY = ((Get-Variable -Name "TextBox_$($np.Name)").Value.height + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.y) + 5

			}
			datetime {
				#Create Label field for the string input
				New-Variable -Name "Label_$($np.Name)" -Value (New-Object system.Windows.Forms.Label)
				(Get-Variable -Name "Label_$($np.Name)").Value.text = "[$($np.Type)] $($np.Name)"
				(Get-Variable -Name "Label_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Label_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Label_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Label_$($np.Name)").Value)
				(Get-Variable -Name "Label_$($np.Name)").Value.width = $labelwidth
				(Get-Variable -Name "Label_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height)
				#add field to form

				$fields += $getfixobj = [pscustomobject]@{ type = "Label"; Name = "$($np.Name)"; object = ((Get-Variable -Name "Label_$($np.Name)").Value) }



				#Get Position of textbox after label
				$tmpX = $currentX + (Get-Variable -Name "Label_$($np.Name)").Value.width + 5

				#create Textbox element
				New-Variable -Name "DateTimePicker_$($np.Name)" -Value (New-Object System.Windows.Forms.DateTimePicker)
				(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.location = New-Object System.Drawing.Point ($tmpX,$currentY)
				(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'
				try { $basedatetime = [datetime]"$($object."$($np.Name)")" }
				catch { $basedatetime = Get-Date }
				(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.text = $basedatetime
				(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.width = 200
				(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.Format = "Custom"
				(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.CustomFormat = "MM/dd/yyyy hh:mm:ss";

				if ($FontSize.height -lt 20)
				{
					(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.height = 20
				}
				else {
					(Get-Variable -Name "DateTimePicker_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 3 + ([math]::Ceiling($FontSize.height / 2))
				}

				#add textbox to form
				$fields += $getfixobj = [pscustomobject]@{ type = "DateTimePicker"; Name = "$($np.Name)"; object = ((Get-Variable -Name "DateTimePicker_$($np.Name)").Value) }


				if ($maxFieldWidths -lt ((Get-Variable -Name "DateTimePicker_$($np.Name)").Value.width + (Get-Variable -Name "DateTimePicker_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "DateTimePicker_$($np.Name)").Value.width + (Get-Variable -Name "DateTimePicker_$($np.Name)").Value.location.x) + 15
				}
				$currentY = ((Get-Variable -Name "DateTimePicker_$($np.Name)").Value.height + (Get-Variable -Name "DateTimePicker_$($np.Name)").Value.location.y) + 5


			}
			default {
				#Create Label field for the string input
				New-Variable -Name "Label_$($np.Name)" -Value (New-Object system.Windows.Forms.Label)
				(Get-Variable -Name "Label_$($np.Name)").Value.text = "[$($np.Type)] $($np.Name)"
				(Get-Variable -Name "Label_$($np.Name)").Value.AutoSize = $false
				(Get-Variable -Name "Label_$($np.Name)").Value.location = New-Object System.Drawing.Point ($currentX,$currentY)
				(Get-Variable -Name "Label_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'

				#size field
				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "Label_$($np.Name)").Value)
				(Get-Variable -Name "Label_$($np.Name)").Value.width = $labelwidth
				(Get-Variable -Name "Label_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height)
				#add field to form
				$fields += $getfixobj = [pscustomobject]@{ type = "Label"; Name = "$($np.Name)"; object = ((Get-Variable -Name "Label_$($np.Name)").Value) }



				#Get Position of textbox after label
				$tmpX = $currentX + (Get-Variable -Name "Label_$($np.Name)").Value.width + 5

				#create Textbox element
				New-Variable -Name "TextBox_$($np.Name)" -Value (New-Object system.Windows.Forms.TextBox)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.location = New-Object System.Drawing.Point ($tmpX,$currentY)
				(Get-Variable -Name "TextBox_$($np.Name)").Value.Font = 'Microsoft Sans Serif,10'
				(Get-Variable -Name "TextBox_$($np.Name)").Value.text = "Unhandled Data TYPE"
				(Get-Variable -Name "TextBox_$($np.Name)").Value.enabled = $false
				(Get-Variable -Name "TextBox_$($np.Name)").Value.width = 200

				$FontSize = Get-ObjectSize -control ((Get-Variable -Name "TextBox_$($np.Name)").Value)
				if ($FontSize.height -lt 20)
				{
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = 20
				}
				else {
					(Get-Variable -Name "TextBox_$($np.Name)").Value.height = [math]::Ceiling($FontSize.height) + 3 + ([math]::Ceiling($FontSize.height / 2))
				}

				#add textbox to form
				#$fields += ((Get-Variable -Name "TextBox_$($np.Name)").Value)
				$fields += $getfixobj = [pscustomobject]@{ type = "TextBox"; Name = "$($np.Name)"; object = ((Get-Variable -Name "TextBox_$($np.Name)").Value) }


				if ($maxFieldWidths -lt ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x)) {
					$maxFieldWidths = ((Get-Variable -Name "TextBox_$($np.Name)").Value.width + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.x) + 15
				}
				$currentY = ((Get-Variable -Name "TextBox_$($np.Name)").Value.height + (Get-Variable -Name "TextBox_$($np.Name)").Value.location.y) + 5
			}


		}

	}

	$form.text = "Input"
	$Form.width = $maxFieldWidths + 30
	$Form.height = $currentY + 50
	$form.Controls.AddRange($fields.object)
	$form.Add_FormClosed({
			$Global:ta = $fields
		})
	[void]$Form.ShowDialog()
}

#private
function Get-ObjectSize () {
	param(
		$control
	)
	Add-Type -Assembly System.Drawing
	$BlankImage = New-Object System.Drawing.Bitmap (500,500)
	$gr = [System.Drawing.Graphics]::FromImage($BlankImage)
	return $gr.MeasureString("$($control.text)",$($control.Font))
}

#private
function Get-StringSize () {
	param(
		[Parameter(mandatory = $true)] [string]$String,
		[Parameter(mandatory = $true)] [string]$Font
	)
	Add-Type -Assembly System.Drawing
	$BlankImage = New-Object System.Drawing.Bitmap (500,500)
	$gr = [System.Drawing.Graphics]::FromImage($BlankImage)
	return $gr.MeasureString("$($string)",$($font))
}



