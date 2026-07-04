/*
 * Singletons of NTCode language node parsers
 */

// NTCode statement node parser
GLOBAL_DATUM_INIT(ntcode_statement_node, /datum/ntcode/node/statement, new)

// NTCode expression node parser
GLOBAL_DATUM_INIT(ntcode_expression_node, /datum/ntcode/node/expression, new)

// NTCode block node parser
GLOBAL_DATUM_INIT(ntcode_block_node, /datum/ntcode/node/block, new)

// NTCode root node parser
GLOBAL_DATUM_INIT(ntcode_root_node, /datum/ntcode/node/root, new)
