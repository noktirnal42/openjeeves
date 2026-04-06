# OpenJeeves Documentation

## Overview

This folder contains the documentation for OpenJeeves. The docs are designed to be served via GitHub Pages.

## Structure

```
docs/
├── index.html          # Main landing page
├── getting-started.md  # Quick start guide
├── configuration.md    # Configuration reference
├── channels.md        # Channel setup guides
├── tools.md           # Tools reference
├── skills.md          # Skills system
├── security.md        # Security guidelines
└── assets/
    ├── openjeeves-logo-text.svg
    └── openjeeves-logo-text-light.svg
```

## GitHub Pages Setup

1. Go to repository settings
2. Navigate to Pages
3. Source: Deploy from a branch
4. Branch: `main`
5. Folder: `/docs`

## Building Locally

To test the documentation locally:

```bash
# Install a static site generator
npm install -g docsify

# Serve the docs
docsify serve docs
```

## Contributing

To contribute to the documentation:

1. Edit the `.md` files in this directory
2. Ensure all links are relative
3. Test locally before submitting PR
