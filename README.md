# PublicSuffix

`PublicSuffix` is an Elixir library to operate on domain names using
the public suffix rules provided by https://publicsuffix.org/:

> A "public suffix" is one under which Internet users can (or
> historically could) directly register names. Some examples of public
> suffixes are `.com`, `.co.uk` and `pvt.k12.ma.us`. The Public Suffix List is
> a list of all known public suffixes.

This Elixir library provides a means to get the registrable domain part
from any domain:

``` iex
iex(1)> PublicSuffix.registrable_domain("mysite.foo.bar.com")
"bar.com"
iex(2)> PublicSuffix.registrable_domain("mysite.foo.bar.co.uk")
"bar.co.uk"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add public_suffix to your list of dependencies in `mix.exs`:

        def deps do
          [{:public_suffix, "~> 0.0.1"}]
        end

  2. Ensure public_suffix is started before your application:

        def application do
          [applications: [:public_suffix]]
        end

## Known Issues

The [Public Suffix specification](https://publicsuffix.org/list/)
specifically allows wildcards to appear multiple times in a rule
and at any position:

> Wildcards are not restricted to appear only in the leftmost position,
> but they must wildcard an entire label. (I.e. `*.*.foo` is a valid rule:
> `*bar.foo` is not.)

However, while supporting a single leading wildcard is easy, supporting
multiple wildcards and wildcards at any position is far more difficult.
Furthermore, all wildcard rules in the publicsuffix.org data file use
a wildcard only at the leftmost position. There is also an open conversation
going about this issue:

https://github.com/publicsuffix/list/issues/145

From the issue, most public suffix implementations, including Mozilla
and Chromium, only support wildcards at the leftmost position. We do
not support them yet, either, but may in the future depending on the
direction of the github issue.
