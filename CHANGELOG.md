# Release Notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

* The `ExternalFallbacks` now has a keyword argument `automatic` (defaults to `false`) that controls whether _any_ unresolvable `@ref` reference should be automatically searched for in external inventories. [[#14], [#17]]

### Changed

* In version `1.0.0`, loading the `DocumenterInterLinks` package would automatically try to resolve all otherwise unresolvable `@ref` references in external inventories, without any possibility to opt out of this behavior [[#14]]. This possibility is now provided by the new `automatic` keyword argument for `ExternalFallbacks`. Because the default is `automatic=false`, the behavior is now opt-in, not opt-out. Since the `ExternalFallbacks` plugin and its associated functionality are "experimental", this is not considered a semver-breaking change. To restore the previous behavior of `v1.0.0`, one must now instantiate `fallbacks = ExternalFallbacks(; automatic=true)` in `docs/make.jl`, and pass the `fallbacks` objects as part of `plugins` to `Documenter.makedocs` (alongside the `InterLinks` object). [[#17]]

### Other

* Bumped minimum compatible version of `Documenter` to `v1.3.0`.


## [Version 1.0.0][1.0.0] - 2024-06-07

* Initial stable release. This is functionally identical to the `v0.3.3` release.

[Unreleased]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/JuliaDocs/DocumenterInterLinks.jl/releases/tag/v1.0.0
[#14]: https://github.com/JuliaDocs/DocumenterInterLinks.jl/issues/14
[#17]: https://github.com/JuliaDocs/DocumenterInterLinks.jl/pull/17
