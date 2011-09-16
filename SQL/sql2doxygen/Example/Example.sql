/**
** \file   Example.sql
** \brief  The examples of what sql2doxygen can cope with.
** \author Chris Oldwood
**
** This file contains various SQL object definitions and comment styles to show
** what sql2doxygen can transform. Becasue it is a very dumb parser it expects
** most key definitions to appear on one line, e.g. don't split the keywords
** CREATE & TABLE and/or the table name across lines.
**/

-- The code below will be stripped from the output as it's not an object definition.
-- However this comment will remain.
if (object_id('myschema.MyTable') is not null)
	drop table myschema.MyTable;
go

/**
** This table definition uses the C-style comment.
**/

create table myschema.MyTable
(
	/** This column definition uses the C-style comment. */
	MyColumn myschema.MyType not null primary key clustered,

	/* Non-Doxygen C-style comment. */
	CStyleComment int,

	-- Non-Doxygen SQL-style comment
	SqlStyleComment int,

	--! This column uses the SQL-equivalent Doxygen comment
	SqlStyleDoxComment int,

	--- This column uses the other SQL-equivalent Doxygen comment
	SqlStyleDoxComment2 int,

	CommentOnRight smallint, /*!< This comment is to the right */
);
go

--------------------------------------------------------------------------------
--- This table definition uses the SQL-equivalent block comment style.
--------------------------------------------------------------------------------

create table MyOtherTable
(
	MyColumn smalldatetime
)
go

--!
--! The final table definition uses the other SQL-equivalent block comment style.
--!

create table MyFinalTable
(
	MyFinalColumn smalldatetime
)
go

/*!
 * A function that takes no arguments.
 */

create function myschema.MyNoArgsFunction() returns varchar(10)
as
begin
	return '42';
end
go

/*!
 * A function that takes one or more arguments.
 */

create function myschema.MyFunction
(
	@value1	tinyint,		--!< The 1st argument.
	@value2	smalldatetime	/*!< The 2nd argument. */
)
	returns varchar(10)
as
begin
	return
	case @value
		when 4 then	'4'
		when 2 then	'2'
		else		'42'
	end
end
go
