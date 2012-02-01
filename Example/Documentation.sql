/**
** \file
** \brief  Main page documentation.
** \author Chris Oldwood
**/

/**
** \mainpage Example sql2doxygen documentation
**
** \section Introduction
** This output was generated from the example .sql scripts. It also acts as
** my test data and so will give you a definitive answer as to what constructs
** are supported.
**
** \section Limitations
** The sql2doygen script is a very dumb line-based parser and so it expects
** most key definitions to appear on one line, e.g. don't split the keywords
** CREATE & (TABLE|FUNCTION|PROCEDURE) across multiple lines. The name of the
** object must also appear on the same line as the CREATE keyword:-
**
** \code
** CREATE TABLE MyTable
** \endcode
**
** This is probably not overly restrictive for tables, but when it comes to
** functions SQL and C put the return type at opposite ends of the function
** declaration and so parsing them is much harder. Currently the only styles
** supported are:-
**
** \code
** CREATE FUNCTION MyFunction() RETURNS int
** AS
** \endcode
**
** \code
** CREATE FUNCTION MyFunction()
**   RETURNS int
** AS
** \endcode
**
** \code
** CREATE FUNCTION MyFunction
** (
**   @value1	tinyint,		--!< The 1st argument.
**   @value2	smalldatetime	--!< Another argument.
** )
**   RETURNS int
** AS
** \endcode
**
** Hopefully later versions of this script will relax these requirements and
** support more flexible coding styles.
**/
