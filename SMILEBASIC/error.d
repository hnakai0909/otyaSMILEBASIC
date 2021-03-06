module otya.smilebasic.error;
import std.exception;
import std.string;
import std.conv;
class SmileBasicError : Exception
{
    int errnum;
    int errline;
    int errprg;
    string message2;
    this(int slot, int line, string message)
    {
        super(format("%s in %d:%d", message, slot, line));
    }
    this(int line, string message)
    {
        super(format("%s in %d", message, line));
    }
    this(string message)
    {
        super(message);
    }
    this(string message, string message2)
    {
        super(message);
        this.message2 = message2;
    }
    string getErrorMessage()
    {
        return this.msg;
    }
    //詳細
    string getErrorMessage2()
    {
        return message2;
    }
}
class SyntaxError : SmileBasicError
{
    this()
    {
        this.errnum = 3;
        super("Syntax error");
    }
    this(wstring func)
    {
        this();
        this.message2 = "Undefined function (" ~ func.to!string ~ ")";
    }
}
class IllegalFunctionCall : SmileBasicError
{
    this(string func)
    {
        this.errnum = 4;
        super("Illegal function call(" ~ func ~ ")");
    }
}
class TypeMismatch : SmileBasicError
{
    this()
    {
        this.errnum = 8;
        super("Type mismatch");
    }
}
class OutOfRange : SmileBasicError
{
    this()
    {
        this.errnum = 10;
        super("Out of range");
    }
}
class OutOfDATA : SmileBasicError
{
    this()
    {
        this.errnum = 13;
        super("Out of DATA");
    }
}
class DuplicateVariable : SmileBasicError
{
    this()
    {
        this.errnum = 18;
        super("Duplicate variable");
    }
}
class ReturnWithoutGosub : SmileBasicError
{
    this()
    {
        this.errnum = 30;
        super("RETURN without GOSUB");
    }
}
class SubscriptOutOfRange : SmileBasicError
{
    this()
    {
        this.errnum = 31;
        super("Subscript out of range");
    }
}

