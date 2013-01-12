################################################################################
# \file		sql2doxygen.ps1
# \brief	Convert the SQL file into something Doxygen can handle.
# \author	Chris Oldwood (gort@cix.co.uk | www.cix.co.uk/~gort)
# \version	0.2
#
# This is a Doxygen filter that takes a .SQL file (T-SQL) and transforms it into
# C-like code so that Doxygen can then parse it. The current conversion assumes
# that the Doxygen output will be optimised for C and not Java.
################################################################################

################################################################################
# Configure error handling.

set-strictmode -version Latest

$ErrorActionPreference = 'stop'

trap
{
	write-error $_ -erroraction continue
	exit 1
}

################################################################################
# Write a line of output terminated with a CR/LF. The built-in write-host
# cmdlet does not play nicely with stdout redirection (it only appends a CR).
# The write-output cmdlet also fails with redirection as text is wrapped at the
# width of the parent console window so we have to do it manually.

function write-line([string] $line)
{
    write-host -nonewline ("{0}`r`n" -f $line)
}

################################################################################
# Validate the command line.

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

################################################################################
# Regular expressions used to parse the code.

$namepart_pattern = '[\w\[\]]+'                             # [name]
$name_pattern = '[\w.\[\]]+'                                # [schema].[name]
$fullname_re = "(?<schema>$namepart_pattern).(?<name>$namepart_pattern)"	# name|schema.name
$indent_re = '^(?<indent>\s*)'                              # Leading whitespace
$column_name_re = "(?<column_name>$name_pattern)"           # Identifier
$type_name_re = "(?<type_name>[\w.\[\]()]+)"                # Identifier
$parameter_name_re = "(?<parameter_name>@$name_pattern)"    # @Identifier
$comment_re = '(?<comment>/\*.+\*/\s*$|--.+$|\s*$)'         # /* ... */ or -- ... or none
$create_table_re = 'create\s+table'                         # create table
$table_name_re = "(?<table_name>$name_pattern)"             # Identifier
$create_function_re = 'create\s+function'                   # create function
$function_name_re = "(?<function_name>$name_pattern)"       # Identifier
$create_procedure_re = 'create\s+procedure'                 # create procedure
$procedure_name_re = "(?<procedure_name>$name_pattern)"     # Identifier
$create_type_re = 'create\s+type'                           # create type
$alias_name_re = "(?<alias_name>$name_pattern)"             # Identifier

################################################################################
# Detect a line consisting of nothing but whitespace.

function is-blank-line($line)
{
    if ($line -match '^\s*$')
    {
        return $true
    }

    return $false
}

################################################################################
# Parse the schema name from the SQL style identifier.

function parse-schemaname($identifier)
{
	$schema = 'dbo'

	if ( ($identifier -match '\.') -and ($identifier -match $fullname_re) )
	{
		$schema = $matches.schema
	}

    $schema = transform-identifier $schema
    
    return $schema
}

################################################################################
# Parse the object name from the SQL style identifier.

function parse-objectname($identifier)
{
	$object = $identifier

	if ( ($identifier -match '\.') -and ($identifier -match $fullname_re) )
	{
		$object = $matches.name
	}

    $object = transform-identifier $object
    
    return $object
}

################################################################################
# Convert a single-line SQL-style comment into the C-style equivalent.

function transform-sql-comment($line)
{
	$line = $line -replace '--!','//!'
	$line = $line -replace '---','///'
	$line = $line -replace '--','//'
    
    return $line
}

################################################################################
# Transform the SQL identifier into one compatible with the C++ language.

function transform-identifier($identifier)
{
	$identifier = $identifier -replace '\[|\]',''
	$identifier = $identifier -replace '\.','::'
    
    return $identifier
}

################################################################################
# Transform the SQL type name into one compatible with the C++ language. Types
# are similar to identifiers in format but you have parametersied variants, such
# as varchar(10).

function transform-type($type)
{
	$type = transform-identifier $type
	$type = $type -replace '\(','['
	$type = $type -replace '\)',']'
    
    return $type
}

################################################################################
# Handle C-style comments. These start with /* and end with */. The doxygen
# variants starts with /** or /*!.

function is-c-style-comment($line)
{
    if ($line -match '^/\*[*!]')
    {
        return $true
    }

    return $false
}

function write-c-style-comment($enumerator)
{
    $line = $enumerator.value.current

	write-line $line

    # Single comment?
	if ($line -match '\*/')
    {
        return
    }

    # Multi-line comment.
    while ($enumerator.value.movenext())
    {
        $line = $enumerator.value.current

		write-line $line
        
        if ($line -match '\*/')
        {
            return
        }
    }
}

################################################################################
# Handle SQL-style comments. These start with -- or for the doxygen variants --!
# or ---. These are transformed into the single-line // C-style comment.

function is-sql-style-comment($line)
{
    if ($line -match '^--')
    {
        return $true
    }

    return $false
}

function write-sql-style-comment($line)
{
	if ($line -match '^----+')
	{
		$line = $line -replace '-','/'
	}

	$line = transform-sql-comment $line

	write-line $line
}

################################################################################
# Handle table definitions. This assumes that the "create table" keywords and
# the table name are all on a single line. The column definitions also must
# not span lines.

function is-table-definition($line)
{
    if ($line -match "$indent_re$create_table_re")
    {
        return $true
    }

    return $false
}

function write-table-definition($enumerator)
{
	if ($line -notmatch "$indent_re$create_table_re\s+$table_name_re")
    {
        return
    }
    
	$schema = parse-schemaname $matches.table_name
	$name = parse-objectname $matches.table_name

	$line = "struct $name"

	write-line $line

    while ($enumerator.value.movenext())
    {
        $line = $enumerator.value.current

        # Handle column definitions
		if ($line -match "$indent_re$column_name_re\s+$type_name_re[\s,\w]*$comment_re")
		{
			$indent  = $matches.indent
			$column  = transform-identifier $matches.column_name
			$type_schema = parse-schemaname $matches.type_name
			$type_name   = transform-type (parse-objectname $matches.type_name)
			$comment = $matches.comment

			$line = $indent + $type_name + ' ' + $column + '; ' + $comment
		}

        # Transform table body delimiters
		$line = $line -replace '^\(', '{'
		$line = $line -replace '^\);?', '};'

        $line = transform-sql-comment $line

		write-line $line

        # End of definition?
		if ($line -match '};')
		{
			return
		}
    }
}

################################################################################
# Handle the set of function/procedure parameters.

function write-parameters($enumerator)
{
    $separator = '';

    while ($enumerator.value.movenext())
    {
        $line = $enumerator.value.current

		if ($line -match "$indent_re$parameter_name_re\s+$type_name_re[\s,]*$comment_re")
		{
			$indent  = $matches.indent
			$param   = transform-identifier $matches.parameter_name
			$type_schema = parse-schemaname $matches.type_name
			$type_name   = transform-type (parse-objectname $matches.type_name)
			$comment = transform-sql-comment $matches.comment

			$line = $indent + $separator + $type_name + ' ' + $param + ' ' + $comment
            
            if ($separator -eq '')
            {
                $separator = ','
            }
		}

		if ($line -match '^\)$')
		{
            return
		}

		write-output $line
    }
}

################################################################################
# Handle user-defined function and stored procedure definitions.

function is-function-definition($line)
{
    if ($line -match "$indent_re$create_function_re")
    {
        return $true
    }

    return $false
}

function is-procedure-definition($line)
{
    if ($line -match "$indent_re$create_procedure_re")
    {
        return $true
    }

    return $false
}

$function = 'function'
$procedure = 'procedure'

function write-fn_or_proc-definition($enumerator, $fn_or_proc)
{
    if ($fn_or_proc -eq $function)
	{
        if ($line -notmatch "$indent_re$create_function_re\s+$function_name_re")
        {
            return
        }

		$schema = parse-schemaname $matches.function_name
		$name = parse-objectname $matches.function_name

        $returnType = ''

        # Return type specified with function name?
	    if ($line -match ".*returns\s+$type_name_re$")
        {
            $returnType = transform-type $matches.type_name
        }
    }
    elseif ($fn_or_proc -eq $procedure)
    {
	    if ($line -notmatch "$indent_re$create_procedure_re\s+$procedure_name_re")
	    {
            return
        }

		$schema = parse-schemaname $matches.procedure_name
		$name = parse-objectname $matches.procedure_name

        $returnType = 'int'
    }

    $argsList = $null

    while ($enumerator.value.movenext())
    {
        $line = $enumerator.value.current

        # transform body delimiters
        if ($fn_or_proc -eq $function)
	    {
            $line = $line -replace '^begin', '{'
		    $line = $line -replace '^end;?', '}'
        }
        elseif ($fn_or_proc -eq $procedure)
        {
            $line = $line -replace '^as', '{'
            $line = $line -replace '^go', '}'
        }

        # Write signature if start of body
		if ($line -match '^{$')
		{
            if ($argsList -eq $null)
            {
                write-line ($returnType + ' ' + "$name" + '();')
            }
            else
            {
                write-line ($returnType + ' ' + "$name")
                write-line '('
                $argsList | foreach { write-line $_ }
                write-line ');'
            }
        }
        # Handle argument list
		elseif ($line -match '^\($')
		{
            $argsList = write-parameters $enumerator
		}
        elseif ($line -match '^as$')
        {
            # Discard
        }
        # Return type specified after function name/arguments?
        elseif ($line -match ".*returns\s+$type_name_re$")
		{
			$returnType = transform-type $matches.type_name
		}

        # End of definition?
		if ($line -match '}')
		{
			return
		}
	}
}

################################################################################
# Handle user-defined type definitions.

function is-type-definition($line)
{
    if ($line -match "$indent_re$create_type_re")
    {
		return $true
    }

    return $false
}

function write-type-definition($enumerator)
{
	if ($line -notmatch "$indent_re$create_type_re\s+$alias_name_re\s+from\s+$type_name_re")
    {
        return
    }

	$alias_schema = parse-schemaname $matches.alias_name
	$alias_name   = transform-type (parse-objectname $matches.alias_name)
	$type_schema = parse-schemaname $matches.type_name
	$type_name   = transform-type (parse-objectname $matches.type_name)

	write-line "typedef $type_name $alias_name;"
}

################################################################################
# Main parsing loop.

$lines = get-content $args[0]
$enumerator = $lines.getenumerator()

while ($enumerator.movenext())
{
    $line = $enumerator.current

	if (is-blank-line $line -eq $true)
    {
        write-line $line
    }
    elseif (is-c-style-comment $line -eq $true)
	{
        write-c-style-comment $(get-variable -name enumerator)
	}
	elseif (is-sql-style-comment $line -eq $true)
	{
        write-sql-style-comment $line
	}
    elseif (is-table-definition $line -eq $true)
    {
        write-table-definition $(get-variable -name enumerator)
    }
    elseif (is-function-definition $line -eq $true)
    {
        write-fn_or_proc-definition $(get-variable -name enumerator) $function
    }
    elseif (is-procedure-definition $line -eq $true)
    {
        write-fn_or_proc-definition $(get-variable -name enumerator) $procedure
    }
    elseif (is-type-definition $line -eq $true)
    {
        write-type-definition $(get-variable -name enumerator)
    }
}
