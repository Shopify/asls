defmodule AssemblyScriptLS.Diagnostic.ParserTest do
  alias AssemblyScriptLS.Diagnostic.Parser

  use ExUnit.Case, async: true

  test "extracts compiler diagnostics per uri" do
    output = ~s"""
      > @ asbuild /Users/foo/Developer/asc-sandbox
      > npm run asbuild:untouched && npm run asbuild:optimized


      > @ asbuild:untouched /Users/foo/Developer/asc-sandbox
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
          at Object.main (/Users/foo/Developer/asc-sandbox/node_modules/assemblyscript/cli/asc.js:634:21)
          at /Users/foo/Developer/asc-sandbox/node_modules/assemblyscript/bin/asc:21:47
      npm ERR! code ELIFECYCLE
      npm ERR! errno 1
      npm ERR! @ asbuild:untouched: `asc --extension asc assembly/index.asc -b build/untouched.wasm -t build/untouched.wat --validate --sourceMap --debug`
      npm ERR! Exit status 1
      npm ERR!
      npm ERR! Failed at the @ asbuild:untouched script.
      npm ERR! This is probably not a problem with npm. There is likely additional logging output above.

      npm ERR! A complete log of this run can be found in:
      npm ERR!     /Users/foo/.npm/_logs/2020-06-11T13_35_22_005Z-debug.log
      npm ERR! code ELIFECYCLE
      npm ERR! errno 1
      npm ERR! @ asbuild: `npm run asbuild:untouched && npm run asbuild:optimized`
      npm ERR! Exit status 1
      npm ERR!
      npm ERR! Failed at the @ asbuild script.
      npm ERR! This is probably not a problem with npm. There is likely additional logging output above.

      npm ERR! A complete log of this run can be found in:
      npm ERR!     /Users/foo/.npm/_logs/2020-06-11T13_35_22_042Z-debug.log
    """

    result = Parser.parse("foo/bar/assembly/index.asc", output)

    {"foo/bar/assembly/index.asc", diagnostics} = result
    assert length(diagnostics) == 2
    assert hd(tl(diagnostics)) == %AssemblyScriptLS.Diagnostic{
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

    assert hd(diagnostics) == %AssemblyScriptLS.Diagnostic{
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

  test "subsequent diagnostics without location are ignored" do
    output = ~s"""
      WARNING Unknown option '--validate'
      ERROR TS6054: File 'assembly/index..ts' not found.


      ERROR TS2355: A function whose declared type is not 'void' must return a value.

           public run(param: i32): i32 {
                                   ~~~
       in assembly/index.asc(8,29)

      FAILURE 1 parse error(s)
      npm ERR! code ELIFECYCLE
      npm ERR! errno 1
      npm ERR! @ asbuild:untouched: `asc assembly/index. -b build/untouched.wasm -t build/untouched.wat --validate --sourceMap --debug`
      npm ERR! Exit status 1
      npm ERR!
      npm ERR! Failed at the @ asbuild:untouched script.
      npm ERR! This is probably not a problem with npm. There is likely additional logging output above.
    """

    result = Parser.parse("foo/bar/assembly/index.asc", output)
    {"foo/bar/assembly/index.asc", diagnostics} = result
    assert length(diagnostics) === 1
    assert hd(diagnostics) == %AssemblyScriptLS.Diagnostic{
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

  test "diagnostics without location are ingnored" do
    output = ~s"""
      WARNING Unknown option '--validate'
      ERROR TS6054: File 'assembly/index..ts' not found.

      FAILURE 1 parse error(s)
      npm ERR! code ELIFECYCLE
      npm ERR! errno 1
      npm ERR! @ asbuild:untouched: `asc assembly/index. -b build/untouched.wasm -t build/untouched.wat --validate --sourceMap --debug`
      npm ERR! Exit status 1
      npm ERR!
      npm ERR! Failed at the @ asbuild:untouched script.
      npm ERR! This is probably not a problem with npm. There is likely additional logging output above.
    """

    assert {"foo/bar", []} == Parser.parse("foo/bar", output)
  end

  test "an assertion is returned when an assertion failure is found" do
    output = """
          Whoops, the AssemblyScript compiler has crashed during compile :-(
      ▌
      ▌ Here is a stack trace that may or may not be useful:
      ▌
      ▌ AssertionError: assertion failed
      ▌     at i.assert (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:737155)
      ▌     at f.ensureRuntimeFunction (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:219974)
      ▌     at f.compileIdentifierExpression (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:302341)
      ▌     at f.compileExpression (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:237695)
      ▌     at f.compileCallDirect (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:285287)
      ▌     at f.compileCallExpression (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:280134)
      ▌     at f.compileExpression (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:237302)
      ▌     at f.compileGlobal (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:206051)
      ▌     at f.compileTopLevelStatement (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:221274)
      ▌     at f.compileFile (/Users/foo/Developer/astest/node_modules/assemblyscript/dist/assemblyscript.js:7:204959)
      ▌
      ▌ If it refers to the dist files, try to 'npm install source-map-support' and
      ▌ run again, which should then show the actual code location in the sources.
      ▌
      ▌ If you see where the error is, feel free to send us a pull request. If not,
      ▌ please let us know: https://github.com/AssemblyScript/assemblyscript/issues
      ▌
      ▌ Thank you!
    """

    {"foo/bar", [assertion]} = Parser.parse("foo/bar", output)
    assert assertion.contents == output
  end
end
