/**
** \file
** \brief  The examples of what sql2doxygen can cope with.
** \author Chris Oldwood
**
** This file contains various SQL object definitions and comment styles to show
** what sql2doxygen can transform.
**/

// The code below will be stripped by the filter as it's not an object definition.
// However this comment will remain. But it's not a Doxygen format comment so
// won't have any effect on the documentation generated.

/**
** This table definition uses the C-style comment.
**/

struct MyTable
{
	/** This column definition uses the C-style comment. */
	MyType MyColumn; 

	/* Non-Doxygen C-style comment. */
	int CStyleComment; 

	// Non-Doxygen SQL-style comment
	int SqlStyleComment; 

	//! This column uses the SQL-equivalent Doxygen comment
	int SqlStyleDoxComment; 

	/// This column uses the other SQL-equivalent Doxygen comment
	int SqlStyleDoxComment2; 

	smallint CommentOnRight; /*!< This comment is to the right */

	bigint CommentOnRight2; //!< This comment is also to the right

	float CommentOnRight3; ///< Another comment to the right
};

////////////////////////////////////////////////////////////////////////////////
/// This table definition uses the SQL-equivalent block comment style.
////////////////////////////////////////////////////////////////////////////////

struct MyOtherTable
{
	smalldatetime MyColumn; 
};

//!
//! The final table definition uses the other SQL-equivalent block comment style.
//!

struct MyFinalTable
{
	varchar[10] MyFinalColumn; 
};

/**
** A table definition that has a schema and []'s in the names.
**/

struct BracketsTable
{
	BracketsType BracketsColumn; //!< A column with []'s in the name.
};

/*!
 * A function that takes no arguments.
 * NB: The signature is written on a single line.
 */

varchar[10] MyNoArgsFunction();

/*!
 * A user defined type.
 */

typedef varchar[100] BracketType;

/*!
 * A function that has a schema and []'s in the name.
 */

BracketType BracketsFunction();

/*!
 * A function that takes no arguments and spans multiple lines.
 */

varchar[20] MyOtherNoArgsFunction();

/*!
 * A function that takes no arguments where the return is
 * specified on a separate line.
 */

varchar[20] OneMoreNoArgsFunction();

/*!
 * A function that takes one or more arguments.
 */

varchar[10] MyFunction
(
	tinyint @value1 //!< The 1st argument.
	,smalldatetime @value2 /*!< The 2nd argument. */
);

/*!
 * A procedure that takes no arguments.
 */

int MyNoArgProcedure();

/*!
 * A procedure that has a schema and []'s in the name.
 */

int BracketsProcedure
(
	BracketType @aParam //!< Parameter type with []'s
);

/*!
 * A procedure that takes arguments.
 */

int MyMultiArgProcedure
(
	tinyint @value1 //!< The 1st argument.
	,varchar[10] @value2 /*!< The 2nd argument. */
);
