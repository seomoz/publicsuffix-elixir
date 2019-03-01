### Unreleased

* Update IDNA to support version 6.0.0
  * Also bump dev dependecies for earmark and ex_doc

Breaking:
* Raise minimum Elixir version to 1.4

### 0.6.0 / 2018-02-28
[Full Changelog](https://github.com/seomoz/publicsuffix-elixir/compare/v0.5.0...v0.4.0)

* Update data file to latest published public suffix list (Jason Axelson, [#28][r28]).
* Update IDNA dependency range (Jason Axelson, [#26][r26]).
* Fix Elixir 1.4 warnings (Rich Cavanaugh, [#24][r24]).

[r28]: https://github.com/seomoz/publicsuffix-elixir/pull/28
[r26]: https://github.com/seomoz/publicsuffix-elixir/pull/26
[r24]: https://github.com/seomoz/publicsuffix-elixir/pull/24


### 0.5.0 / 2016-10-13
[Full Changelog](https://github.com/seomoz/publicsuffix-elixir/compare/v0.4.0...v0.5.0)

* Update data file to latest published public suffix list (Dejan Štrbac, #23).
* Use `:unicode.characters_to_list/1` instead of `:xmerl_ucs.from_utf8/1`
  to for unicode conversion to avoid need to install extra xmerl package
  on some linux distros. (Dejan Štrbac, #23).

### 0.4.0 / 2016-06-21
[Full Changelog](https://github.com/seomoz/publicsuffix-elixir/compare/v0.3.0...v0.4.0)

* Fix Elixir 1.3 warnings.

### 0.3.0 / 2016-06-03
[Full Changelog](https://github.com/seomoz/publicsuffix-elixir/compare/v0.2.1...v0.3.0)

Enhancements:

* Add `prevailing_rule/2` and `matches_explicit_rule?/1` for working
  with rules. (Anders Jensen-Urstad, #17)

### 0.2.1 / 2016-05-20
[Full Changelog](https://github.com/seomoz/publicsuffix-elixir/compare/v0.2.0...v0.2.1)

Bug Fixes:

* Ensure bundled public suffix rules file is actually included in
  published package. (Myron Marston, #16)

### 0.2.0 / 2016-05-19
[Full Changelog](https://github.com/seomoz/publicsuffix-elixir/compare/v0.1.0...v0.2.0)

Enhancements:

* Relax `idna` dependency from `~> 2.0` to `>= 1.2.0 and < 3.0.0` for
  compatibility with applications that cannot yet upgrade to idna 2.0.
  (Myron Marston, #13)

### 0.1.0 / 2016-05-18

Initial release.
