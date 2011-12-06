################################################################################
# \file		sql2doxygen.ps1
# \brief	Convert the SQL file into something Doxygen can handle.
# \author	Chris Oldwood (gort@cix.co.uk | www.cix.co.uk/~gort)
# \version	0.2
#
# This is a Doxygen filter that takes a .SQL file (T-SQL) and transforms it into
# C-like code so that Doxygen can then parse it.
################################################################################

# Configure error handling
$ErrorActionPreference = 'stop'

trap
{
	write-error $_ -erroraction continue
	exit 1
}

# Write a line of output terminated with a CR/LF
function write-line([string] $line)
{
    write-host -nonewline ("{0}`r`n" -f $line)
}

# Validate command line
if ( ($args.count -ne 1) -or ($args[0] -eq '--help') )
{
	if ($args[0] -eq '--help')
	{
		write-line "sql2doxygen v0.2"
		write-line "(C) Chris Oldwood 2011 (gort@cix.co.uk)"
	}
	else
	{
		write-line "ERROR: Invalid command line"
	}

	write-line ""
	write-line "USAGE: sql2doxygen.ps1 <file.sql>"
	write-line ""
	write-line "Doxygen configuration:-"
	write-line "INPUT_FILTER = `"PowerShell.exe -File \Path\To\sql2doxygen.ps1`""
	exit 1
}

$lines = get-content $args[0]

$inComment = $false
$inCreateTable = $false
$inCreateFunction = $false
$inCreateProcedure = $false

# For all lines...
foreach ($line in $lines)
{
	# Keep empty lines
	if ($line -match '^\s*$')
	{
		write-line $line
	}
	# If currently parsing a comment, continue until end found.
	elseif ($inComment -eq $true)
	{
		write-line $line

		if ($line -match '\*/')
		{
			$inComment = $false
		}
	}
	# Start of c-style comment?
	elseif ($line -match '^/\*[*!]')
	{
		write-line $line

		if ($line -notmatch '\*/')
		{
			$inComment = $true
		}
	}
	# Part of sql-style comment?
	elseif ($line -match '^--')
	{
		if ($line -match '^----+')
		{
			$line = $line -replace '-','/'
		}

		$line = $line -replace '--!','//!'
		$line = $line -replace '---','///'
		$line = $line -replace '--','//'

		write-line $line
	}
	# If currently parsing a table, continue until end found.
	elseif ($inCreateTable -eq $true)
	{
		if ($line -match '^(?<indent>\s+)(?<column>[\w\[\]]+)\s+(?<fulltype>[\w.\[\]]+)')
		{
			$type = $matches.fulltype
            $type = $type -replace '^\w+\.',''
			$type = $type -replace '\[|\]',''

			$indent = $matches.indent

			$column = $matches.column
			$column = $column -replace '\[|\]',''

			$comment = ''

			if ($line -match '(?<comment>(/\*.+\*/|-.+)$)')
			{
				$comment = $matches.comment
			}

			$line = $indent + $type + ' ' + $column + '; ' + $comment
		}

		$line = $line -replace '^\(', '{'
		$line = $line -replace '^\);?', '};'

		$line = $line -replace '--!','//!'
		$line = $line -replace '---','///'
		$line = $line -replace '--','//'

		write-line $line

		if ($line -match '};')
		{
			$inCreateTable = $false
		}
	}
	# Start of table definition?
	elseif ($line -match '^\s*create\s+table\s+(?<fullname>[\w.\[\]]+)')
	{
        $name = $matches.fullname
		$name = $name -replace '\[|\]',''
		$name = $name -replace '\.','::'

		$line = 'struct ' + $name

		write-line $line

		$inCreateTable = $true
	}
	# If currently parsing a function, continue until end found.
	elseif ($inCreateFunction -eq $true)
	{
		$line = $line -replace '^begin', '{'
		$line = $line -replace '^end;?', '}'

		$line = $line -replace '^as$', ''

		if ($line -match '^\($')
		{
			$inArgsList = $true
			$argsList = @()
		}

		if ($line -match '^\)$')
		{
			$inArgsList = $false
		}

		if ($line -match '.*returns\s+(?<type>[\w.\[\]()]+)$')
		{
			$returnType = $matches.type -replace '^\w+\.',''
            $returnType = $returnType -replace '\[|\]',''
			$returnType = $returnType -replace '\(','['
			$returnType = $returnType -replace '\)',']'

			write-line ($returnType + ' ' + $name)
			write-line '('

			$firstArg = $true

			foreach ($arg in $argsList)
			{
				if ($firstArg -ne $true)
				{
					$arg = ', ' + $arg
				}

				write-line $arg

				$firstArg = $false
			}

			write-line ')'
		}
		elseif ( ($inArgsList -eq $true) -and ($line -match '^(?<indent>\s+)(?<param>@\w+)\s+(?<fulltype>[\w.\[\]]+)') )
		{
			$type = $matches.fulltype -replace '^\w+\.',''
			$indent = $matches.indent
			$param = $matches.param

			$comment = ''

			if ($line -match '(?<comment>(/\*.+\*/|--.+)$)')
			{
				$comment = $matches.comment

				$comment = $comment -replace '--!','//!'
				$comment = $comment -replace '---','///'
				$comment = $comment -replace '--','//'
			}

			$argsList += $indent + $type + ' ' + $param + ' ' + $comment
		}
		elseif ($returnType -ne $null)
		{
			write-line $line
		}

		if ($line -match '}')
		{
			$inCreateFunction = $false
		}
	}
	# Start of function definition?
	elseif ($line -match '^\s*create\s+function\s+(?<fullname>[\w.\[\]]+)')
	{
		$name = $matches.fullname
        $name = $name -replace '\[|\]',''
		$name = $name -replace '\.','::'

		$returnType = $null

		if ($line -match '.*returns\s+(?<type>[\w.\[\]()]+)$')
		{
			$returnType = $matches.type -replace '^\w+\.',''
            $returnType = $returnType -replace '\[|\]',''
			$returnType = $returnType -replace '\(','['
			$returnType = $returnType -replace '\)',']'
		}

		$parens = ''

		if ($line -match 'function\s+[\w.\[\]]+\s*(?<parens>[()\s]+)')
		{
			$parens = $matches.parens
		}

		if ($returnType -ne $null)
		{
			write-line ($returnType + ' ' + $name + $parens)
		}

		$inCreateFunction = $true
	}
	# If currently parsing a procedure, continue until end found.
	elseif ($inCreateProcedure -eq $true)
	{
		$line = $line -replace '^as', '{'
		$line = $line -replace '^go', '}'

		if ( ($line -match '^{$') -and ($name -ne $null) )
		{
			write-line ('void' + ' ' + $name + '()')
			write-line '{'
		}
		elseif ($line -match '^\($')
		{
			$inArgsList = $true
			$argsList = @()

			write-line ('void' + ' ' + $name)
			write-line '('

			$name = $null
		}
		elseif ($line -match '^\)$')
		{
			$inArgsList = $false

			$firstArg = $true

			foreach ($arg in $argsList)
			{
				if ($firstArg -ne $true)
				{
					$arg = ', ' + $arg
				}

				write-line $arg

				$firstArg = $false
			}

			write-line ')'
		}
		elseif ( ($inArgsList -eq $true) -and ($line -match '^(?<indent>\s+)(?<param>@\w+)\s+(?<fulltype>[\w.\[\]]+)') )
		{
			$type = $matches.fulltype
            $type = $type -replace '^\w+\.',''
			$type = $type -replace '\[|\]',''

			$indent = $matches.indent
			$param = $matches.param

			$comment = ''

			if ($line -match '(?<comment>(/\*.+\*/|--.+)$)')
			{
				$comment = $matches.comment

				$comment = $comment -replace '--!','//!'
				$comment = $comment -replace '---','///'
				$comment = $comment -replace '--','//'
			}

			$argsList += $indent + $type + ' ' + $param + ' ' + $comment
		}
		else
		{
			write-line $line
		}

		if ($line -match '}')
		{
			$inCreateProcedure = $false
		}
	}
	# Start of procedure definition?
	elseif ($line -match '^\s*create\s+procedure\s+(?<fullname>[\w.\[\]]+)')
	{
        $name = $matches.fullname
		$name = $name -replace '\[|\]',''
		$name = $name -replace '\.','::'

		$inCreateProcedure = $true
	}
}
