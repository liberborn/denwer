<?php

/**
 * Parses a function call.
 *
 * @package    SqlParser
 * @subpackage Components
 */
namespace SqlParser\Components;

use SqlParser\Component;
use SqlParser\Parser;
use SqlParser\Token;
use SqlParser\TokensList;

/**
 * Parses a function call.
 *
 * @category   Keywords
 * @package    SqlParser
 * @subpackage Components
 * @author     Dan Ungureanu <udan1107@gmail.com>
 * @license    http://opensource.org/licenses/GPL-2.0 GNU Public License
 */
class FunctionCall extends Component
{

    /**
     * The name of this function.
     *
     * @var string
     */
    public $name;

    /**
     * The list of parameters
     *
     * @var ArrayObj
     */
    public $parameters;

    /**
     * Constructor.
     *
     * @param string         $name       The name of the function to be called.
     * @param array|ArrayObj $parameters The parameters of this function.
     */
    public function __construct($name = null, $parameters = null)
    {
        $this->name = $name;
        if (is_array($parameters)) {
            $this->parameters = new ArrayObj($parameters);
        } elseif ($parameters instanceof ArrayObj) {
            $this->parameters = $parameters;
        }
    }

    /**
     * @param Parser     $parser  The parser that serves as context.
     * @param TokensList $list    The list of tokens that are being parsed.
     * @param array      $options Parameters for parsing.
     *
     * @return FunctionCall
     */
    public static function parse(Parser $parser, TokensList $list, array $options = array())
    {
        $ret = new FunctionCall();

        /**
         * The state of the parser.
         *
         * Below are the states of the parser.
         *
         *      0 ----------------------[ name ]-----------------------> 1
         *
         *      1 --------------------[ parameters ]-------------------> (END)
         *
         * @var int $state
         */
        $state = 0;

        for (; $list->idx < $list->count; ++$list->idx) {
            /**
             * Token parsed at this moment.
             *
             * @var Token $token
             */
            $token = $list->tokens[$list->idx];

            // End of statement.
            if ($token->type === Token::TYPE_DELIMITER) {
                break;
            }

            // Skipping whitespaces and comments.
            if (($token->type === Token::TYPE_WHITESPACE) || ($token->type === Token::TYPE_COMMENT)) {
                continue;
            }

            if ($state === 0) {
                $ret->name = $token->value;
                $state = 1;
            } elseif ($state === 1) {
                if (($token->type === Token::TYPE_OPERATOR) && ($token->value === '(')) {
                    $ret->parameters = ArrayObj::parse($parser, $list);
                }
                break;
            }

        }

        return $ret;
    }

    /**
     * @param FunctionCall $component The component to be built.
     * @param array        $options   Parameters for building.
     *
     * @return string
     */
    public static function build($component, array $options = array())
    {
        return $component->name . $component->parameters;
    }
}
