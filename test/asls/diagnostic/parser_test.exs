defmodule AssemblyScriptLS.Diagnostic.ParserTest do
  alias AssemblyScriptLS.Diagnostics.Parser

  use ExUnit.Case, async: true

  test "extracts compiler diagnostics per uri" do
    output = ~s"""
      > @ asbuild /Users/saulecabrera/Developer/asc-sandbox
      > npm run asbuild:untouched && npm run asbuild:optimized


      > @ asbuild:untouched /Users/saulecabrera/Developer/asc-sandbox
      > asc --extension asc assembly/index.asc -b build/untouched.wasm -t build/untouched.wat --validate --sourceMap --debug

      WARN: Unknown option '--validate'
      ERROR TS2304: Cannot find name 'return5'.

               return5 6;
               ~~~~~~~
       in assembly/index.asc(12,9)

      ERROR TS2355: A function whose declared type is not 'void' must return a value.

           public run(param: i32): i32 {
                                   ~~~
       in assembly/index.asc(8,29)

      ERROR: 2 compile error(s)
          at Object.main (/Users/saulecabrera/Developer/asc-sandbox/node_modules/assemblyscript/cli/asc.js:634:21)
          at /Users/saulecabrera/Developer/asc-sandbox/node_modules/assemblyscript/bin/asc:21:47
      npm ERR! code ELIFECYCLE
      npm ERR! errno 1
      npm ERR! @ asbuild:untouched: `asc --extension asc assembly/index.asc -b build/untouched.wasm -t build/untouched.wat --validate --sourceMap --debug`
      npm ERR! Exit status 1
      npm ERR!
      npm ERR! Failed at the @ asbuild:untouched script.
      npm ERR! This is probably not a problem with npm. There is likely additional logging output above.

      npm ERR! A complete log of this run can be found in:
      npm ERR!     /Users/saulecabrera/.npm/_logs/2020-06-11T13_35_22_005Z-debug.log
      npm ERR! code ELIFECYCLE
      npm ERR! errno 1
      npm ERR! @ asbuild: `npm run asbuild:untouched && npm run asbuild:optimized`
      npm ERR! Exit status 1
      npm ERR!
      npm ERR! Failed at the @ asbuild script.
      npm ERR! This is probably not a problem with npm. There is likely additional logging output above.

      npm ERR! A complete log of this run can be found in:
      npm ERR!     /Users/saulecabrera/.npm/_logs/2020-06-11T13_35_22_042Z-debug.log
    """

    result = AssemblyScriptLS.Diagnostic.Parser.parse("foo/bar", output)

    diagnostics = result["foo/bar/assembly/index.asc"]
    assert length(diagnostics) == 2
    assert hd(diagnostics) == %AssemblyScriptLS.Diagnostic{
      code: "TS2304",
      message: "Cannot find name 'return5'.",
      range: %AssemblyScriptLS.Diagnostic.Range{
        start: %AssemblyScriptLS.Diagnostic.Position{
          character: 8, line: 11
        },
        end: %AssemblyScriptLS.Diagnostic.Position{
          character: 8, line: 11
        },
      },
      severity: 1,
      source: "AssemblyScript Language Server",
    }
    
    assert hd(tl(diagnostics)) == %AssemblyScriptLS.Diagnostic{
      code: "TS2355",
      message: "A function whose declared type is not 'void' must return a value.",
      range: %AssemblyScriptLS.Diagnostic.Range{
        start: %AssemblyScriptLS.Diagnostic.Position{
          character: 28, line: 7
        },
        end: %AssemblyScriptLS.Diagnostic.Position{
          character: 28, line: 7
        },
      },
      severity: 1,
      source: "AssemblyScript Language Server",
    }
  end
end
