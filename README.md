# PublicSuffix

`PublicSuffix` is an Elixir library to operate on domain names using
the public suffix rules provided by https://publicsuffix.org/:

> A "public suffix" is one under which Internet users can (or
> historically could) directly register names. Some examples of public
> suffixes are `.com`, `.co.uk` and `pvt.k12.ma.us`. The Public Suffix List is
> a list of all known public suffixes.

This Elixir library provides a means to get the public suffix and the
registrable domain from any domain:

``` iex
iex(1)> PublicSuffix.registrable_domain("mysite.foo.bar.com")
"bar.com"
iex(2)> PublicSuffix.registrable_domain("mysite.foo.bar.co.uk")
"bar.co.uk"
iex(3)> PublicSuffix.public_suffix("mysite.foo.bar.com")
"com"
iex(4)> PublicSuffix.public_suffix("mysite.foo.bar.co.uk")
"co.uk"
```

The publicsuffix.org data file contains both official ICANN records
and private records:

> ICANN domains are those delegated by ICANN or part of the IANA root zone database. The authorized registry may express further policies on how they operate the TLD, such as subdivisions within it. Updates to this section can be submitted by anyone, but if they are not an authorized representative of the registry then they will need to back up their claims of error with documentation from the registry's website.
>
> PRIVATE domains are amendments submitted by the domain holder, as an expression of how they operate their domain security policy. Updates to this section are only accepted from authorized representatives of the domain registrant. This is so we can be certain they know what they are getting into.

By default, `PublicSuffix` considers private domain records, but you can
tell it to ignore them:

``` iex
iex(1)> PublicSuffix.registrable_domain("foo.github.io")
"foo.github.io"
iex(2)> PublicSuffix.public_suffix("foo.github.io")
"github.io"
iex(3)> PublicSuffix.registrable_domain("foo.github.io", ignore_private: true)
"github.io"
iex(4)> PublicSuffix.public_suffix("foo.github.io", ignore_private: true)
"io"
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
