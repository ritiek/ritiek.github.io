# Blog

A personal blog and website built with [Zola](https://www.getzola.org/), a fast static site generator.

## Features

- Static site generation with Zola
- Responsive design using the Adidoks theme
- Blog posts and pages in Markdown
- Syntax highlighting for code
- Deployed to GitHub Pages

## Development

### Prerequisites

- [Zola](https://www.getzola.org/) installed, or use [Nix](https://nixos.org/) for a reproducible environment

### Building

Using Nix (recommended for development):

```bash
nix develop --command zola serve
```

This starts a local server at `http://127.0.0.1:1111` with all dependencies managed by Nix.

To build for production:

```bash
nix develop --command zola build
```

The generated site will be in the `public/` directory.

Alternatively, using nix run with the local flake:

```bash
nix run .  # serves the site
```

For building:

```bash
nix run .#build
```

If Zola is installed directly:

```bash
zola serve
zola build
```

### Deployment

The site is automatically deployed to GitHub Pages via GitHub Actions on pushes to the `master` branch.

## Structure

- `content/`: Markdown files for pages and blog posts
- `templates/`: Zola templates
- `static/`: Static assets (CSS, images, etc.)
- `sass/`: SCSS files for styling
- `config.toml`: Zola configuration

### Alternate Themes I Liked

- Terminus
- Anemone
- Adidoks
- Shadharon
- Zola-folio
- PaperMod

## License

Content is licensed under [MIT](LICENSE.md).
