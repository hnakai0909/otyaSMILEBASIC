import std.stdio;
import otya.smilebasic.parser;
int main(string[] argv)
{
    version(none)
    {
        auto parser = new Parser("ADD(ADD(1,2,3,4,5,6),2,3,4,5,6)");
        writeln(parser.calc());
    }

    auto parser = new Parser("PRINT 1+1,2+3;10-5,A");
    auto vm = parser.compile();
    vm.run();
    readln();
    return 0;
}
